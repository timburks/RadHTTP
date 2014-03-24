//
//  RadHTTPRequest.m
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import "RadHTTPRequest.h"
#import "RadHTTPHelpers.h"
#import <Nu/Nu.h>

@implementation RadHTTPRequest
@synthesize URL, headers, body, context, method, connection, bindings, server;

- (id) init {
    if ((self = [super init])) {
        self.scheme = @"http"; // default
        self.bindings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *) path
{
    return [self.URL relativePath];
}

- (NSString *) query
{
    return [self.URL query];
}

- (NSString *) fragment
{
    return [self.URL fragment];
}

- (NSString *) hostWithPort
{
    NSString *host = [self.URL host];
    int port = [[self.URL port] intValue];
    if (port == 80) {
        return host;
    } else {
        return [NSString stringWithFormat:@"%@:%d", host, port];
    }
}

- (NSDictionary *) cookies
{
    NSRegularExpression *cookie_pattern = [NSRegularExpression regularExpressionWithPattern:@"[ ]*([^=]*)=(.*)"
                                                                                    options:0
                                                                                      error:NULL];
    NSMutableDictionary *cookies = [[NSMutableDictionary alloc] init];
    NSString *cookieText = [self.headers objectForKey:@"Cookie"];
    NSArray *parts = [cookieText componentsSeparatedByString:@";"];
    for (int i = 0; i < [parts count]; i++) {
        NSString *cookieDescription = [parts objectAtIndex:i];
        NSTextCheckingResult *result = [cookie_pattern firstMatchInString:cookieDescription
                                                                  options:0
                                                                    range:NSMakeRange(0,[cookieDescription length])];
        if (result) {
            NSString *cookieName = [cookieDescription substringWithRange:[result rangeAtIndex:1]];
            NSString *cookieValue = [cookieDescription substringWithRange:[result rangeAtIndex:2]];
            [cookies setObject:cookieValue forKey:cookieName];
        }
    }
    return cookies;
}

- (NSDictionary *) post
{
    return [[self body] urlQueryDictionary];
}

@end
