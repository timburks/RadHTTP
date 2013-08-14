//
//  RadHTTPServer.h
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

@class RadHTTPService;

//
// RadHTTPServer
// A common interface for Objective-C web servers
//
@interface RadHTTPServer : NSObject 
@property (nonatomic, assign) unsigned port;
@property (nonatomic, assign) BOOL localOnly;
@property (nonatomic, assign) BOOL verbose;
@property (nonatomic, strong) RadHTTPService *service;

- (id)initWithService:(RadHTTPService *) service;
- (void) start;
- (void) run;
- (void) addEventWithOperation:(NSOperation *) operation;

@end

