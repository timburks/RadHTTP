//
//  RadHTTPHelpers.h
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSString (RadHTTPHelpers)
- (NSString *) urlEncodedString;
- (NSString *) urlDecodedString;
- (NSDictionary *) urlQueryDictionary;
@end

@interface NSData (RadHTTPHelpers)
- (NSDictionary *) urlQueryDictionary;
@end

@interface NSDictionary (RadHTTPHelpers)
- (NSString *) urlQueryString;
- (NSData *) urlQueryData;
@end

@interface NSData (RadBinaryEncoding)
- (NSString *) hexEncodedString;
+ (id) dataWithHexEncodedString:(NSString *) string;
@end

