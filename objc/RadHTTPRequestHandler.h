#import <Foundation/Foundation.h>

@class RadHTTPRequest;
@class RadHTTPResponse;

@interface RadHTTPRequestHandler : NSObject 
+ (RadHTTPRequestHandler *) handlerWithHTTPMethod:(id)httpMethod path:(id)path block:(id)block;
+ (RadHTTPRequestHandler *) handlerWithPath:(NSString *) path directory:(NSString *) directory;
- (RadHTTPResponse *) responseForHTTPRequest:(RadHTTPRequest *) request;
@end