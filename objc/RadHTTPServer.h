//
//  RadHTTPServer.h
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

@class RadHTTPRequest;
@class RadHTTPResponse;
@class RadHTTPRequestRouter;

//
// RadHTTPServer
// A common interface for Objective-C web servers
//
@interface RadHTTPServer : NSObject 
@property (nonatomic, assign) unsigned port;
@property (nonatomic, strong) RadHTTPRequestRouter *router;
@property (nonatomic, assign) BOOL localOnly;
@property (nonatomic, assign) BOOL verbose;

+ (RadHTTPServer *) sharedServer;

+ (void) setMimeType:(NSString *) mimeType forExtension:(NSString *) extension;
+ (NSString *) mimeTypeForFilename:(NSString *) filename;

- (id)initWithRequestRouter:(RadHTTPRequestRouter *) router;
- (void) start;
- (void) run;
@end

