//
//  RadHTTPResponse.m
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import "RadHTTPResponse.h"

@implementation RadHTTPResponse

- (id) init 
{
    if ((self = [super init])) {
        self.headers = [[NSMutableDictionary alloc] init];
        // default to likely values which can be overridden if necessary
        self.status = 200;
        [self.headers setObject:@"text/html" forKey:@"Content-Type"];
    }
    return self;    
}

- (void) setValue:(NSString *) value forHTTPHeader:(NSString *) header
{
    if (value && header) {
        if (![value isKindOfClass:[NSString class]]) {
            value = [value description];
        }
        [self.headers setObject:value forKey:header];
    }
}

- (NSString *) redirectResponseToLocation:(NSString *) location 
{
    [self setStatus:303];
    [self setValue:location forHTTPHeader:@"Location"];
    return @"redirecting";
}

- (void) setBody:(NSData *)body {
    if ([body isKindOfClass:[NSString class]]) {
        _body = [(NSString *) body dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        _body = body;
    }
}

@end
