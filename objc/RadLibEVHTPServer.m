//
//  RadLibEVHTPServer.m
//  RadHTTP
//
//  Created by Tim Burks on 3/16/14.
//  Copyright (c) 2014 Radtastical Inc. All rights reserved.
//

#import "RadLibEVHTPServer.h"
#import "RadHTTPRequest.h"
#import "RadHTTPResponse.h"
#import "RadHTTPService.h"

#import <evhtp.h>

@interface RadLibEVHTPServer () {
    evbase_t *evbase;
    evhtp_t  *htp;
}
@property (nonatomic, strong) NSMutableArray *operationQueue;

- (void)processRequest:(RadHTTPRequest *)request;

@end

static NSString *method_for_request(evhtp_request_t *req)
{
    switch (req->method) {
        case htp_method_GET:
            return @"GET";
        case htp_method_POST:
            return @"POST";
        case htp_method_HEAD:
            return @"HEAD";
        case htp_method_PUT:
            return @"PUT";
        case htp_method_DELETE:
            return @"DELETE";
        case htp_method_MKCOL:
            return @"MKCOL";
        case htp_method_COPY:
            return @"COPY";
        case htp_method_MOVE:
            return @"MOVE";
        case htp_method_OPTIONS:
            return @"OPTIONS";
        case htp_method_PROPFIND:
            return @"PROPFIND";
        case htp_method_PROPPATCH:
            return @"PROPPATCH";
        case htp_method_LOCK:
            return @"LOCK";
        case htp_method_UNLOCK:
            return @"UNLOCK";
        case htp_method_TRACE:
            return @"TRACE";
        case htp_method_CONNECT: /* RFC 2616 */
            return @"CONNECT";
        case htp_method_PATCH:   /* RFC 5789 */
            return @"PATCH";
        case htp_method_UNKNOWN:
        default:
            return @"UNKNOWN";

    }
}

static NSString *scheme_for_uri(const evhtp_uri_t *uri)
{
    switch (uri->scheme) {
        case htp_scheme_ftp:
            return @"ftp";
        case htp_scheme_http:
            return @"http";
        case htp_scheme_https:
            return @"https:";
        case htp_scheme_nfs:
            return @"nfs";
        case htp_scheme_unknown:
        default:
            return @"http";
    }
}

static NSDictionary *rad_request_headers_helper(evhtp_request_t *req)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    evhtp_kv_t *header;
    TAILQ_FOREACH(header, req->headers_in, next) {
        [dict setObject:[NSString stringWithCString:header->val encoding:NSUTF8StringEncoding]
                 forKey:[NSString stringWithCString:header->key encoding:NSUTF8StringEncoding]];
    }
    return dict;
}

static NSData *rad_request_body_helper(evhtp_request_t *req)
{
	unsigned long length = evbuffer_get_length(req->buffer_in);
    if (!length)
        return nil;
    else {
		unsigned char *bytes = evbuffer_pullup(req->buffer_in, -1);
        return [NSData dataWithBytes:bytes length:length];
    }
}

static void rad_request_handler(evhtp_request_t *req, void *server_context)
{
    RadLibEVHTPServer *server = (__bridge RadLibEVHTPServer *) server_context;
    RadHTTPRequest *request = [[RadHTTPRequest alloc] init];
    
    const evhtp_uri_t *uri = req->uri;
    
    NSString *scheme = scheme_for_uri(uri);
    
    NSString *host = @"";
    const char *hostHeader = evhtp_header_find(req->headers_in, "Host");
    if (hostHeader) {
        host = [NSString stringWithCString:hostHeader encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *fullpath = [NSMutableString stringWithCString:uri->path->full
                                                          encoding:NSUTF8StringEncoding];
    const unsigned char *queryString = uri->query_raw;
    if (queryString) {
        [fullpath appendFormat:@"?%s", queryString];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", scheme, host, fullpath];
    request.URL = [[NSURL alloc] initWithString:urlString];
    request.method = method_for_request(req);
    request.headers = rad_request_headers_helper(req);
    request.body = rad_request_body_helper(req);
    request.context = req;
    request.server = server;
    request.scheme = scheme;
    return [server processRequest:request];
}


@implementation RadLibEVHTPServer
@synthesize operationQueue;

- (id)initWithService:(RadHTTPService *) service
{
    if (self = [super initWithService:service]) {
        self->evbase = event_base_new();
        self->htp    = evhtp_new(evbase, NULL);
        
        evhtp_set_gencb(self->htp, rad_request_handler, (__bridge void *)(self));
        operationQueue = [NSMutableArray array];
    }
    return self;
}

- (int) bindToAddress:(NSString *) address port:(int) port
{
    return evhtp_bind_socket(htp, [address cStringUsingEncoding:NSUTF8StringEncoding], port, 1024);
}

static void sig_pipe(int signo)
{
    NSLog(@"SIGPIPE: lost connection during write. (signal %d)", signo);
}

struct event_base *gevent_base;

static void sig_int(int sig)
{
    signal(sig, SIG_IGN);
    event_base_loopexit(gevent_base, NULL); // exits libevent loop
}

- (void) start
{
    int status;
    if (self.localOnly) {
        status = [self bindToAddress:@"127.0.0.1" port:self.port];
    }
    else {
        status = [self bindToAddress:@"0.0.0.0" port:self.port];
    }
    if (status != 0) {
        NSLog(@"Unable to start service on port %d. Is another server running?", self.port);
    }
    else {
        gevent_base = self->evbase;
        signal(SIGINT, sig_int);
        
        if (signal(SIGPIPE, sig_pipe) == SIG_ERR) {
            NSLog(@"failed to setup SIGPIPE handler.");
        }
        
        event_base_loop(self->evbase, 0);
    }
}

- (void) run
{
    [self start];
}

- (void) dealloc
{
    evhtp_unbind_socket(self->htp);
    evhtp_free(self->htp);
    event_base_free(self->evbase);
}

static NSDictionary *rad_response_headers_helper(evhtp_request_t *req)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    evhtp_kv_t *header;
    TAILQ_FOREACH(header, req->headers_out, next) {
        [dict setObject:[NSString stringWithCString:header->val encoding:NSUTF8StringEncoding]
                 forKey:[NSString stringWithCString:header->key encoding:NSUTF8StringEncoding]];
    }
    return dict;
}

static void rad_response_helper(evhtp_request_t *req, RadHTTPResponse *response)
{    
    
    for (id key in [response.headers allKeys]) {
        id value = [response.headers objectForKey:key];
        evhtp_headers_add_header(req->headers_out,
                                 evhtp_header_new([key cStringUsingEncoding:NSUTF8StringEncoding],
                                                  [value cStringUsingEncoding:NSUTF8StringEncoding],
                                                  1, 1));
    }
    
    struct evbuffer *buf = req->buffer_out;
    if (buf == NULL) {
        NSLog(@"FATAL: failed to create response buffer");
        assert(0);
    }
    if (req->method != htp_method_HEAD) {
        int result = evbuffer_add(buf, [response.body bytes], [response.body length]);
        if (result == -1) {
            NSLog(@"WARNING: failed to write %ld bytes to response buffer", (unsigned long) [response.body length]);
        }
    }
    else {
        char buffer[100];
        sprintf(buffer, "%d", (int) [response.body length]);
        evhtp_headers_add_header(req->headers_out,
                                 evhtp_header_new("Content-Length", buffer, 1, 1));
    }
    evhtp_send_reply(req, response.status);
}

- (void) processRequest:(RadHTTPRequest *)request
{
    if (self.verbose) {
        NSLog(@"REQUEST %@ %@ %@\n%@",
              [request URL],
              [request method],
              [request path],
              [[request headers] description]
              );
    }
    @try {
        RadHTTPResponse *response = [self.service responseForHTTPRequest:request];
        if (!response) {
            response = [[RadHTTPResponse alloc] init];
            response.status = 404;
            response.body = [@"Resource not found" dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        evhtp_request_t *req = (evhtp_request_t *) request.context;
        if (self.verbose) {
            NSLog(@"RESPONSE %d %@", response.status, [response.headers description]);
        }
        rad_response_helper(req, response);
        if (response.exit) {
            event_base_loopexit(self->evbase, NULL);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error while responding to request (%@): %@", request.path, [exception reason]);
    }
}

@end
