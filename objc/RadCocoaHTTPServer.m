//
//  RadCocoaHTTPServer.m
//  RadHTTP
//
//  Created by Tim Burks on 5/16/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//
#ifndef LINUX

#import "RadCocoaHTTPServer.h"
#import "RadHTTPRequest.h"
#import "RadHTTPResponse.h"
#import "RadHTTPService.h"

#import <sys/socket.h>  // for AF_INET, PF_INET, SOCK_STREAM, SOL_SOCKET, SO_REUSEADDR
#import <netinet/in.h>  // for IPPROTO_TCP, sockaddr_in
#include <signal.h>     // SIGPIPE
#include <arpa/inet.h>  // inet_ntoa

//
// RadCocoaHTTPConnection
// A model for a web server's connection to a client.
// A RadHTTPConnection manages the connection between the RadHTTP server and a client.
// It is created by RadHTTPServer instances in response to a new connection.
// The RadHTTPConnection then receives data and constructs request objects to
// represent each complete request that it receives.
//
@interface RadCocoaHTTPConnection : NSObject <RadHTTPResponder>

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, weak) RadHTTPServer *server;
@property (nonatomic, assign) CFHTTPMessageRef message;
@property (nonatomic, assign) BOOL isMessageComplete;
@property (nonatomic, assign) BOOL isMessageHeaderComplete;
@property (nonatomic, strong) NSMutableData *content;
@property (nonatomic, assign) int contentLength;
@property (nonatomic, strong) NSString *clientAddress;

- (id) initWithFileHandle:(NSFileHandle *) fileHandle server:(RadHTTPServer *) server;
- (void) respondWithMessageData:(NSData *) messageData;

@end

@implementation NSFileHandle (RadHTTP)

- (NSString *) remoteAddress
{
    CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault,
                                                  self.fileDescriptor,
                                                  kCFSocketNoCallBack,
                                                  NULL,
                                                  NULL);
    CFDataRef addrData = CFSocketCopyPeerAddress(socket);
    CFRelease(socket);
    NSString *result;
    if (addrData) {
        struct sockaddr_in *sock = (struct sockaddr_in *) CFDataGetBytePtr(addrData);
        result = [NSString stringWithCString:(const char *) inet_ntoa(sock->sin_addr) encoding:NSUTF8StringEncoding];
        CFRelease(addrData);
    }
    else {
        result = @"NULL";
    }
    return result;
}

@end

@interface RadHTTPServer ()
- (void) closeConnectionAndContinue:(RadCocoaHTTPConnection *) connection;
- (void) addRequest:(id) request;
@end

@implementation RadCocoaHTTPConnection
@synthesize fileHandle = _fileHandle;
@synthesize server = _server;
@synthesize message = _message;
@synthesize isMessageComplete = _isMessageComplete;
@synthesize isMessageHeaderComplete = _isMessageHeaderComplete;
@synthesize content = _content;
@synthesize contentLength = _contentLength;
@synthesize clientAddress = _clientAddress;

- (id) initWithFileHandle:(NSFileHandle *) fileHandle server:(RadHTTPServer *) server
{
    if ((self = [super init])) {
        self.fileHandle = fileHandle;
        self.clientAddress = [self.fileHandle remoteAddress];
        self.server = server;
        self.message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
        self.isMessageComplete = false;
        self.isMessageHeaderComplete = false;
        self.content = [[NSMutableData alloc] init];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(processIncomingData:)
         name:NSFileHandleReadCompletionNotification
         object:self.fileHandle];
        [self.fileHandle readInBackgroundAndNotify];
    }
    return self;
}

- (void) dealloc
{
    CFRelease(self.message);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) requestForIncomingMessage
{
    RadHTTPRequest *request = [[RadHTTPRequest alloc] init];
    CFURLRef URL = CFHTTPMessageCopyRequestURL(self.message);
    request.URL = (__bridge NSURL *) URL;
    CFStringRef method = CFHTTPMessageCopyRequestMethod(self.message);
    request.method = (__bridge NSString *) method;
    CFDictionaryRef headers = CFHTTPMessageCopyAllHeaderFields(self.message);
    request.headers = (__bridge NSDictionary *) headers;
    request.body = self.content;
    request.connection = self;
    if (URL) CFRelease(URL);
    if (method) CFRelease(method);
    if (headers) CFRelease(headers);
    return request;
}

- (void)processIncomingData:(NSNotification *)notification
{
    // get the incoming data
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if ([data length] == 0) {
        // the client closed the connection
        [self.server closeConnectionAndContinue:self];
        return;
    }
    
    if (!self.isMessageHeaderComplete) {
        // append incoming data to the message
        if (!CFHTTPMessageAppendBytes(self.message, [data bytes], [data length])) {
            // invalid incoming message
            [self.server closeConnectionAndContinue:self];
            return;
        }
        if (CFHTTPMessageIsHeaderComplete(self.message)) {
            self.isMessageHeaderComplete = YES;
            
            CFStringRef contentLengthString =
            CFHTTPMessageCopyHeaderFieldValue(self.message, CFSTR("Content-Length"));
            if (contentLengthString) {
                self.contentLength = CFStringGetIntValue(contentLengthString);
                CFRelease(contentLengthString);
            } else {
                self.contentLength = 0;
            }
            
            if (self.contentLength == 0) {
                self.isMessageComplete = true;
            } else {
                NSData *messageData = (__bridge NSData *) CFHTTPMessageCopyBody(self.message);
                if (messageData)
                    [self.content appendData:messageData];
                if (self.contentLength == [self.content length])
                    self.isMessageComplete = true;
            }
            
        }
    }
    
    else {
        // the header is complete, but the message isn't
        [self.content appendData:data];
        if (self.contentLength <= [self.content length]) {
            self.isMessageComplete = true;
        }
    }
    
    if (self.isMessageComplete) {
        [self.server addRequest:[self requestForIncomingMessage]];
    } else {
        [self.fileHandle readInBackgroundAndNotify];
    }
}

- (void) respondWithMessageData:(NSData *) messageData {
    [self.fileHandle writeData:messageData];
}

@end


NSData *messageDataForResponse(RadHTTPResponse *response)
{
    // Create the response message.
    CFHTTPMessageRef message = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
                                                           response.status,
                                                           NULL,
                                                           kCFHTTPVersion1_1);
    // Set the response headers.
    for (NSString *key in [response.headers allKeys]) {
        id value = [response.headers objectForKey:key];
        CFHTTPMessageSetHeaderFieldValue (message, (__bridge CFStringRef)key, (__bridge CFStringRef)value);
    }
    // Set the response body and add the Content-Length header.
    if (response.body) {
        if ([response.body isKindOfClass:[NSString class]]) {
            response.body = [((NSString *) response.body) dataUsingEncoding:NSUTF8StringEncoding];
        }
        CFStringRef length = CFStringCreateWithFormat(NULL, NULL, CFSTR("%ld"), (unsigned long)[response.body length]);
        CFHTTPMessageSetHeaderFieldValue (message, CFSTR("Content-Length"), length);
        CFHTTPMessageSetBody(message, (__bridge CFDataRef) response.body);
    }
    // Serialize the message and return the result.
    CFDataRef messageData = CFHTTPMessageCopySerializedMessage(message);
    CFRelease(message);
    return (__bridge_transfer NSData *) messageData;
}

@interface RadCocoaHTTPServer ()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSMutableArray *connections;
@property (nonatomic, strong) NSMutableArray *requests;
@property (nonatomic, assign) BOOL asynchronous;

- (void)closeConnectionAndContinue:(RadCocoaHTTPConnection *)connection;
@end

@implementation RadCocoaHTTPServer

#if !TARGET_OS_IPHONE
+ (void) load {
    //[RadHTTPServer macros];
}
#endif

- (id)initWithService:(RadHTTPService *) service
{
    if (self = [super initWithService:service]) {
#if !TARGET_OS_IPHONE
        [self attachHandlers];
#endif
        self.connections = [[NSMutableArray alloc] init];
        self.requests = [[NSMutableArray alloc] init];
        self.asynchronous = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

static void sig_pipe(int signo)
{
    NSLog(@"SIGPIPE: lost connection during write. (signal %d)", signo);
}

static void sig_int(int sig)
{
    signal(sig, SIG_IGN);
    NSLog(@"SIGINT: interrupt");
}

- (void) attachHandlers
{
    // if (signal(SIGINT, sig_int) == SIG_ERR) {
    //     NSLog(@"failed to setup SIGINT handler.");
    // }
    if (signal(SIGPIPE, sig_pipe) == SIG_ERR) {
        NSLog(@"failed to setup SIGPIPE handler.");
    }
}

- (void) start {
    CFSocketRef socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
    if (socket) {
        int fileDescriptor = CFSocketGetNative(socket);
        int yes = 1;
        setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, (void *) &yes, sizeof(yes));
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(self.port);
        if (self.localOnly) {
            addr4.sin_addr.s_addr = htonl(0x7f000001); // 127.0.0.1
        } else {
            addr4.sin_addr.s_addr = htonl(INADDR_ANY);
        }
        CFDataRef address4 = CFDataCreate(kCFAllocatorDefault, (const UInt8 *) &addr4, sizeof(addr4));
        if (kCFSocketSuccess != CFSocketSetAddress(socket, address4)) {
            NSLog(@"Could not bind to address");
        } else {
            self.fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(processNewConnection:)
             name:NSFileHandleConnectionAcceptedNotification
             object:nil];
            [self.fileHandle acceptConnectionInBackgroundAndNotify];
        }
        CFRelease(address4);
    } else {
        NSLog(@"No server socket");
    }
}

- (void) run {
    [self start];
    [[NSRunLoop mainRunLoop] run];
}

- (void)processNextRequestOnMainEventLoop
{
    [self performSelectorOnMainThread:@selector(processNextRequest:) withObject:self waitUntilDone:NO];
}

- (void)processNextRequest:(id)sender
{
    if ([self.requests count] > 0) {
		RadHTTPRequest *request = [self.requests objectAtIndex:0];
        if (self.verbose) {
            NSLog(@"%@ %@\n%@",
                  request.method,
                  request.path,
                  [request.headers description]
                  );
        }
        [self.requests removeObjectAtIndex:0];
        if (self.asynchronous) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            dispatch_async(queue, ^{
                @try {
                    RadHTTPResponse *response = [self.service responseForHTTPRequest:request];
                    if (!response) {
                        response = [[RadHTTPResponse alloc] init];
                        response.status = 404;
                        response.body = [@"Resource not found" dataUsingEncoding:NSUTF8StringEncoding];
                    }
                    [request.connection respondWithMessageData:messageDataForResponse(response)];
                }
                @catch (NSException *exception) {
                    NSLog(@"Error while responding to request (%@): %@", request.path, [exception reason]);
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self closeConnectionAndContinue:request.connection];
                });
            });
        } else {
            @try {
                RadHTTPResponse *response = [self.service responseForHTTPRequest:request];
                if (!response) {
                    response = [[RadHTTPResponse alloc] init];
                    response.status = 404;
                    response.body = [@"Resource not found" dataUsingEncoding:NSUTF8StringEncoding];
                }
                [request.connection respondWithMessageData:messageDataForResponse(response)];
            }
            @catch (NSException *exception) {
                NSLog(@"Error while responding to request (%@): %@", request.path, [exception reason]);
            }
            [self closeConnectionAndContinue:request.connection];            
        }
    }
}

- (void)addRequest:(id) request
{
    [self.requests addObject:request];
    [self processNextRequestOnMainEventLoop];
}

- (void)processNewConnection:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if (errorNo) {
        NSLog(@"NSFileHandle Error: %@", errorNo);
    } else {
        NSFileHandle *remoteFileHandle = [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
        if (remoteFileHandle) {
            RadCocoaHTTPConnection *connection =
            [[RadCocoaHTTPConnection alloc]
             initWithFileHandle:remoteFileHandle server:self];
            if (connection) {
                [self.connections addObject:connection];
            }
        }
    }
    [self.fileHandle acceptConnectionInBackgroundAndNotify];
}

- (void)closeConnectionAndContinue:(RadCocoaHTTPConnection *)connection;
{
    [self.connections removeObjectIdenticalTo:connection];
    [self processNextRequestOnMainEventLoop];
}

@end
#endif
