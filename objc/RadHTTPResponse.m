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

- (NSData *) messageData {
    // Create the response message.
    CFHTTPMessageRef message = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
                                                           self.status,
                                                           NULL,
                                                           kCFHTTPVersion1_1);
    // Set the response headers.
    for (NSString *key in [self.headers allKeys]) {
        id value = [self.headers objectForKey:key];
        CFHTTPMessageSetHeaderFieldValue (message, (__bridge CFStringRef)key, (__bridge CFStringRef)value);
    }    
    // Set the response body and add the Content-Length header.
    if (self.body) {
        if ([self.body isKindOfClass:[NSString class]]) {
            self.body = [((NSString *) self.body) dataUsingEncoding:NSUTF8StringEncoding];
        }
        CFStringRef length = CFStringCreateWithFormat(NULL, NULL, CFSTR("%ld"), (unsigned long)[self.body length]);
        CFHTTPMessageSetHeaderFieldValue (message, CFSTR("Content-Length"), length);
        CFHTTPMessageSetBody(message, (__bridge CFDataRef) self.body);
    }    
    // Serialize the message and return the result.
    CFDataRef messageData = CFHTTPMessageCopySerializedMessage(message);
    CFRelease(message);
    return (__bridge_transfer NSData *) messageData;
}

- (NSString *) redirectResponseToLocation:(NSString *) location 
{
    [self setStatus:303];
    [self setValue:location forHTTPHeader:@"Location"];
    return @"redirecting";
}

@end
