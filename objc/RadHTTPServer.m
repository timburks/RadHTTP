//
//  RadHTTPServer.m
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import "RadHTTPServer.h"
#import "RadHTTPService.h"

#import "RadCocoaHTTPServer.h"
#import "RadLibEventHTTPServer.h"

@implementation RadHTTPServer
@synthesize service = _service, port, localOnly, verbose;

- (id)initWithService:(RadHTTPService *) service
{
    if (self = [super init]) {
        self.service = service;
        self.port = 8080;
        self.localOnly = NO;
        self.verbose = NO;
        
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        for (int i = 0; i < [arguments count]; i++) {
            NSString *argument = [arguments objectAtIndex:i];
            if (([argument isEqualToString:@"-p"] || [argument isEqualToString:@"--port"]) &&
                (i+1 < [arguments count])) {
                self.port = [[arguments objectAtIndex:++i] intValue];
            }
            else if (([argument isEqualToString:@"-l"] || [argument isEqualToString:@"--local"])) {
                self.localOnly = YES;
            }
            else if (([argument isEqualToString:@"-v"] || [argument isEqualToString:@"--verbose"])) {
                self.verbose = YES;
            }
        }
    }
    return self;
}

- (id) init
{
    return [self initWithService:[RadHTTPService sharedService]];
}

- (void) start
{
    
}

- (void) run
{
    
}

+ (void) run
{
    if ([self isEqual:[RadHTTPServer class]]) {
#ifdef DARWIN
        [[[RadCocoaHTTPServer alloc] init] run];
#else
        [[[RadLibEventHTTPServer alloc] init] run];
#endif
    } else {
        [[[self alloc] init] run];
    }
}

@end
