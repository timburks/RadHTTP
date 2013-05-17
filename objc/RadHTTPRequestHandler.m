#import "RadHTTPRequestHandler.h"
#import "RadHTTPRequest.h"
#import "RadHTTPResponse.h"
#import "RadHTTPService.h"

@interface RadHTTPRequestHandler ()
@property (nonatomic, strong) NSString *httpMethod;    
@property (nonatomic, strong) NSString *path;			
@property (nonatomic, strong) id block;	
@property (nonatomic, strong) NSArray *parts; // used to expand pattern for request routing
@end

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
            [response setValue:[[RadHTTPService sharedService] mimeTypeForFilename:path]
                 forHTTPHeader:@"Content-Type"];
            [response setValue:@"max-age=3600"
                 forHTTPHeader:@"Cache-Control"];
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
