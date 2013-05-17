#import <Foundation/Foundation.h>

@class RadHTTPRequest;
@class RadHTTPResponse;
@class RadHTTPRequestHandler;

@interface RadHTTPRequestRouter : NSObject

- (RadHTTPResponse *) responseForHTTPRequest:(RadHTTPRequest *) request;

- (void) insertHandler:(RadHTTPRequestHandler *) handler level:(NSUInteger) level;

@end
