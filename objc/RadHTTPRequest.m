//
//  RadHTTPRequest.m
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import "RadHTTPRequest.h"
#import "RadHTTPHelpers.h"

@implementation RadHTTPRequest

- (id) init {
    if ((self = [super init])) {
        self.bindings = [NSMutableDictionary dictionary];
    }
    return self;
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
