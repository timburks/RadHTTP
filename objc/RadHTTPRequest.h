//
//  RadHTTPRequest.h
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol RadHTTPResponder <NSObject>
- (void) respondWithMessageData:(NSData *) data;
@end

@interface RadHTTPRequest : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSData *body;
@property (nonatomic, strong) NSMutableDictionary *bindings;

- (NSDictionary *) cookies;
- (NSDictionary *) post;

@property (nonatomic, weak) id<RadHTTPResponder> connection;
@property (nonatomic, assign) void *context;

@end
