//
//  RadCocoaHTTPServer.h
//  RadHTTP
//
//  Created by Tim Burks on 5/16/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//
#import "RadHTTPServer.h"

@interface RadCocoaHTTPServer : RadHTTPServer

+ (RadCocoaHTTPServer *) sharedServer;

@end