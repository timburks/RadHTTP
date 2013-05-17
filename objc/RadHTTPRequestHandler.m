#import "RadHTTPRequestHandler.h"
#import "RadHTTPRequest.h"
#import "RadHTTPResponse.h"

@interface RadHTTPRequestHandler ()
@property (nonatomic, strong) NSString *httpMethod;    
@property (nonatomic, strong) NSString *path;			
@property (nonatomic, strong) id block;	
@property (nonatomic, strong) NSArray *parts; // used to expand pattern for request routing
@end

static NSString *mimetype(NSString *filename) {
    static NSDictionary *mimetypes = nil;
    if (!mimetypes) {
        mimetypes = [NSDictionary dictionaryWithObjectsAndKeys:
                     @"text/css", @"css",
                     @"text/html", @"html",
                     @"text/javascript", @"js",                     
                     @"image/jpeg", @"jpeg",
                     @"image/jpeg", @"jpg",
                     @"image/png", @"png",
                     @"image/gif", @"gif",
                     @"image/bmp", @"bmp",
                     @"image/x-icon", @"ico",
                     @"application/vnd.apple.mpegURL", @"m3u8",
                     @"video/MP2T", @"ts",
                     @"video/mp4", @"mp4",
                     @"application/pdf", @"pdf",
                     @"application/xml", @"xml",
                     @"text/xml", @"plist",
                     @"application/octet-stream", @"ipa",
                     @"application/octet-stream", @"mobileprovision",
                     @"application/x-apple-aspen-config", @"mobileconfig",
                     nil];
    }
    NSString *mimetype = [mimetypes objectForKey:[filename pathExtension]];
    if (mimetype) {
        return mimetype;
    } else {
        return @"text/html";
    }
}

@implementation RadHTTPRequestHandler

+ (RadHTTPRequestHandler *) handlerWithHTTPMethod:(id)httpMethod path:(id)path block:(id)block
{
    RadHTTPRequestHandler *handler = [[RadHTTPRequestHandler alloc] init];
    handler.httpMethod = httpMethod;
    handler.path = path;
    handler.parts = [[NSString stringWithFormat:@"%@%@", httpMethod, path]
                     componentsSeparatedByString:@"/"];
    handler.block = block;
    return handler;
}

+ (RadHTTPRequestHandler *) handlerWithPath:(NSString *) path directory:(NSString *) directory
{
    RadHTTPRequestHandler *handler = [[RadHTTPRequestHandler alloc] init];
    handler.httpMethod = @"GET";
    handler.path = path;
    handler.parts = [[NSString stringWithFormat:@"%@%@", @"GET", path]                      
                     componentsSeparatedByString:@"/"];
    handler.block = ^(RadHTTPRequest *REQUEST) {
        NSString *path = [REQUEST.bindings objectForKey:@"*path"];
        NSData *data = [NSData dataWithContentsOfFile:
                        [directory stringByAppendingPathComponent:path]];
        if (data) {
            RadHTTPResponse *response = [[RadHTTPResponse alloc] init];
            response.body = data;
            [response setValue:mimetype(path) forHTTPHeader:@"Content-Type"];
            [response setValue:@"max-age=3600" forHTTPHeader:@"Cache-Control"];
            return response;             
        } else {
            return (RadHTTPResponse *) nil;
        }  
    };
    return handler;
}

static Class NuBlock;
static Class NuCell;

+ (void) initialize {
    NuBlock = NSClassFromString(@"NuBlock");
    NuCell = NSClassFromString(@"NuCell");
}

// Handle a request. Used internally.
- (RadHTTPResponse *) responseForHTTPRequest:(RadHTTPRequest *) request;
{
    // NSLog(@"handling request %@", [[request URL] description]);
    if (NuBlock && NuCell && [self.block isKindOfClass:NuBlock]) {
        id args = [[NuCell alloc] init];
        [args performSelector:@selector(setCar:) withObject:request];
        return [self.block performSelector:@selector(evalWithArguments:context:) 
                                withObject:args 
                                withObject:[NSMutableDictionary dictionary]];
	} else {
        return ((id(^)(id)) self.block)(request);
    }
}

@end
