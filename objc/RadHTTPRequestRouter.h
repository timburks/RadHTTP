#import <Foundation/Foundation.h>

@class RadHTTPRequest;
@class RadHTTPResponse;

@interface RadHTTPRequestRouter : NSObject

+ (RadHTTPRequestRouter *) sharedRouter;

- (RadHTTPResponse *) responseForHTTPRequest:(RadHTTPRequest *) request;
- (void) addHandlerWithHTTPMethod:(NSString *) httpMethod path:(NSString *) path block:(id) block;
- (void) addHandlerWithPath:(NSString *) path directory:(NSString *) directory;

@end
