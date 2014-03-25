//
//  RadHTTPHelpers.m
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import "RadHTTPHelpers.h"
#import <wctype.h>
#import <time.h>
#import <xlocale.h>

@interface NSString (_RadHTTPHelpers)
- (NSString *) stringValue;
@end

@implementation NSString (_RadHTTPHelpers)
- (NSString *) stringValue {return self;}
@end

static unichar char_to_int(unichar c)
{
    switch (c) {
        case '0': return 0;
        case '1': return 1;
        case '2': return 2;
        case '3': return 3;
        case '4': return 4;
        case '5': return 5;
        case '6': return 6;
        case '7': return 7;
        case '8': return 8;
        case '9': return 9;
        case 'A': case 'a': return 10;
        case 'B': case 'b': return 11;
        case 'C': case 'c': return 12;
        case 'D': case 'd': return 13;
        case 'E': case 'e': return 14;
        case 'F': case 'f': return 15;
    }
    return 0;                                     // not good
}

static char int_to_char[] = "0123456789ABCDEF";

@implementation NSString (RadHTTPHelpers)

- (NSString *) urlEncodedString
{
    NSMutableString *result = [NSMutableString string];
    int i = 0;
    const char *source = [self cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long max = strlen(source);
    while (i < max) {
        unsigned char c = source[i++];
        if (c == ' ') {
            [result appendString:@"%20"];
        }
        else if (iswalpha(c) || iswdigit(c) || (c == '-') || (c == '.') || (c == '_') || (c == '~')) {
            [result appendFormat:@"%c", c];
        }
        else {
            [result appendString:[NSString stringWithFormat:@"%%%c%c", int_to_char[(c/16)%16], int_to_char[c%16]]];
        }
    }
    return result;
}

- (NSString *) urlDecodedString
{
    int i = 0;
    NSUInteger max = [self length];
    char *buffer = (char *) malloc ((max + 1) * sizeof(char));
    int j = 0;
    while (i < max) {
        char c = [self characterAtIndex:i++];
        switch (c) {
            case '+':
                buffer[j++] = ' ';
                break;
            case '%':
                buffer[j++] =
                    char_to_int([self characterAtIndex:i])*16
                    + char_to_int([self characterAtIndex:i+1]);
                i = i + 2;
                break;
            default:
                buffer[j++] = c;
                break;
        }
    }
    buffer[j] = 0;
    NSString *result = [NSMutableString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    if (!result) result = [NSMutableString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    free(buffer);
    return result;
}

- (NSDictionary *) urlQueryDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *pairs = [self componentsSeparatedByString:@"&"];
    int i;
    NSUInteger max = [pairs count];
    for (i = 0; i < max; i++) {
        NSArray *pair = [[pairs objectAtIndex:i] componentsSeparatedByString:@"="];
        if ([pair count] == 2) {
            NSString *key = [[pair objectAtIndex:0] urlDecodedString];
            NSString *value = [[pair objectAtIndex:1] urlDecodedString];
            [result setObject:value forKey:key];
        }
    }
    return result;
}

@end

@implementation NSDictionary (RadHTTPHelpers)

- (NSString *) urlQueryString
{
    NSMutableString *result = [NSMutableString string];
    NSEnumerator *keyEnumerator = [[[self allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject])) {
        if ([result length] > 0) [result appendString:@"&"];
        [result appendString:[NSString stringWithFormat:@"%@=%@", 
                              [key urlEncodedString], 
                              [[[self objectForKey:key] stringValue] urlEncodedString]]];
    }
    return [NSString stringWithString:result];
}

- (NSData *) urlQueryData 
{
    return [[self urlQueryString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation NSData (RadHTTPHelpers)

- (NSDictionary *) urlQueryDictionary {
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] urlQueryDictionary];
}

static NSMutableDictionary *parseHeaders(const char *headers)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    size_t max = strlen(headers);
    int start = 0;
    int cursor = 0;
    while (cursor < max) {
        while ((headers[cursor] != ':') && (headers[cursor] != '=')) {
            cursor++;
        }
        NSString *key = [[NSString alloc] initWithBytes:(headers+start)
                                                  length:(cursor - start) encoding:NSASCIIStringEncoding];
        //NSLog(@"got key[%@]", key);
        cursor++;
        
        // skip whitespace
        while (headers[cursor] == ' ') {cursor++;}
        start = cursor;
        while (headers[cursor] && (headers[cursor] != ';') && ((headers[cursor] != 13) || (headers[cursor+1] != 10))) {
            cursor++;
        }
        
        NSString *value;
        // strip quotes
        if ((headers[start] == '"') && (headers[cursor-1] == '"'))
            value = [[NSString alloc] initWithBytes:(headers+start+1) length:(cursor-start-2) encoding:NSASCIIStringEncoding];
        else
            value = [[NSString alloc] initWithBytes:(headers+start) length:(cursor-start) encoding:NSASCIIStringEncoding];
        //NSLog(@"got value[%@]", value);
        [dict setObject:value forKey:key];
        
        if (headers[cursor] == ';')
            cursor++;
        else cursor += 2;
        // skip whitespace
        while (headers[cursor] == ' ') {cursor++;}
        start = cursor;
    }
    
    return dict;
}

- (NSDictionary *) multipartDictionaryWithBoundary:(NSString *) boundary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    const char *bytes = (const char *) [self bytes];
    const char *pattern = [boundary cStringUsingEncoding:NSUTF8StringEncoding];
    
    //NSLog(@"pattern: %s", pattern);
    
    // scan through bytes, looking for pattern.
    // split on pattern.
    size_t cursor = 0;
    size_t start = 0;
    size_t max = [self length];
    //NSLog(@"max = %ld", (unsigned long) max);
    while (cursor < max) {
        if (bytes[cursor] == pattern[0]) {
            // try to scan pattern
            int i;
            size_t patternLength = strlen(pattern);
            BOOL match = YES;
            for (i = 0; i < patternLength; i++) {
                if (bytes[cursor+i] != pattern[i]) {
                    match = NO;
                    break;
                }
            }
            if (match) {
                if (start != 0) {
                    // skip first cr/lf
                    size_t startOfHeaders = start + 2;
                    // scan forward to end of headers
                    size_t cursor2 = startOfHeaders;
                    while ((bytes[cursor2] != (char) 0x0d) ||
                           (bytes[cursor2+1] != (char) 0x0a) ||
                           (bytes[cursor2+2] != (char) 0x0d) ||
                           (bytes[cursor2+3] != (char) 0x0a)) {
                        cursor2++;
                        if (cursor2 + 4 == max) {
                            // something is wrong.
                            break;
                        }
                    }
                    if (cursor2 + 4 == max) {
                        // it's over
                        break;
                    }
                    else {
                        size_t lengthOfHeaders = cursor2 - startOfHeaders;
                        char *headers = (char *) malloc((lengthOfHeaders + 1) * sizeof(char));
                        strncpy(headers, bytes+startOfHeaders, lengthOfHeaders);
                        headers[lengthOfHeaders] = 0;
                        
                        // Process headers.
                        NSMutableDictionary *item = parseHeaders(headers);
                        
                        // skip CR/LF pair
                        size_t startOfData = cursor2 + 4;
                        // skip CR/LF and final two hyphens
                        size_t lengthOfData = cursor - startOfData - 2;
                        
                        if (([item valueForKey:@"Content-Type"] == nil) && ([item valueForKey:@"filename"] == nil)) {
                            NSString *string = [[NSString alloc]
                                                 initWithBytes:(bytes+startOfData)
                                                 length:lengthOfData
                                                 encoding:NSUTF8StringEncoding];
                            //NSLog(@"saving %@ for %@", string, [item valueForKey:@"name"]);
                            [dict setObject:string forKey:[item valueForKey:@"name"]];
                        }
                        else {
                            NSData *data = [NSData dataWithBytes:(bytes+startOfData) length:lengthOfData];                            
                            //NSLog(@"saving data of length %lu for %@", (unsigned long) [data length], [item valueForKey:@"name"]);
                            [item setObject:data forKey:@"data"];
                            [dict setObject:item forKey:[item valueForKey:@"name"]];
                        }
                    }
                }
                cursor = cursor + patternLength - 1;
                start = cursor + 1;
            }
        }
        cursor++;
    }
    
    return dict;
}

- (NSDictionary *) multipartDictionary
{
    // scan for pattern
    const char *bytes = (const char *) [self bytes];
    size_t cursor = 0;
    size_t max = [self length];
    while (cursor < max) {
        if (bytes[cursor] == 0x0d) {
            break;
        }
        else {
            cursor++;
        }
    }
    char *pattern = (char *) malloc((cursor+1) * sizeof(char));
    strncpy(pattern, bytes, cursor);
    pattern[cursor] = 0x00;
    NSString *boundary = [[NSString alloc] initWithCString:pattern encoding:NSUTF8StringEncoding];
    free(pattern);
    return [self multipartDictionaryWithBoundary:boundary];
}

@end

@implementation NSData (RadBinaryEncoding)

static const char *const hexEncodingTable = "0123456789abcdef";

- (NSString *) hexEncodedString
{
    NSString *result = nil;
    size_t length = [self length];
    if (0 != length) {
        NSMutableData *temp = [NSMutableData dataWithLength:(length << 1)];
        if (temp) {
            const unsigned char *src = [self bytes];
            unsigned char *dst = [temp mutableBytes];
            if (src && dst) {
                while (length-- > 0) {
                    *dst++ = hexEncodingTable[(*src >> 4) & 0x0f];
                    *dst++ = hexEncodingTable[(*src++ & 0x0f)];
                }
                result = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
            }
        }
    }
    return result;
}

#define HEXVALUE(c) (((c >= '0') && (c <= '9')) ? (c - '0') : ((c >= 'a') && (c <= 'f')) ? (c - 'a' + 10) : 0)

+ (id) dataWithHexEncodedString:(NSString *) string
{
    if (string == nil)
        return nil;
    if ([string length] == 0)
        return [NSData data];
    
    const char *characters = [[string lowercaseString] cStringUsingEncoding:NSASCIIStringEncoding];
    if (characters == NULL)                       //  Not an ASCII string!
        return nil;
    
    NSUInteger length = [string length] / 2;
    char *bytes = (char *) malloc(length * sizeof (char));
    const char *cursor = characters;
    for (int i = 0; i < length; i++) {
        char ch = *(cursor++);
        char cl = *(cursor++);
        bytes[i] = HEXVALUE(ch)*16 + HEXVALUE(cl);
    }
    return [NSData dataWithBytesNoCopy:bytes length:length];
}
@end

@implementation NSDate (RadHTTPHelpers)
// Get an RFC822-compliant representation of a date.
- (NSString *) rfc822
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:enUS];
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:[dateFormatter stringFromDate:self]];
    [result appendString:[[NSTimeZone localTimeZone] abbreviation]];
    return result;
}

// Get an RFC1123-compliant representation of a date.
- (NSString *) rfc1123
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"];
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:[dateFormatter stringFromDate:self]];
    return result;
}

+ (NSDate *) dateFromRFC1123String:(NSString *) dateString
{
    if (dateString == nil)
        return nil;
    
    const char *str = [dateString UTF8String];
    const char *fmt;
    NSDate *retDate;
    char *ret;
    
    fmt = "%a, %d %b %Y %H:%M:%S %Z";
    struct tm rfc1123timeinfo;
    memset(&rfc1123timeinfo, 0, sizeof(rfc1123timeinfo));
    ret = strptime_l(str, fmt, &rfc1123timeinfo, NULL);
    if (ret) {
        time_t rfc1123time = mktime(&rfc1123timeinfo);
        retDate = [NSDate dateWithTimeIntervalSince1970:rfc1123time];
        if (retDate != nil)
            return retDate;
    }
    
    
    fmt = "%A, %d-%b-%y %H:%M:%S %Z";
    struct tm rfc850timeinfo;
    memset(&rfc850timeinfo, 0, sizeof(rfc850timeinfo));
    ret = strptime_l(str, fmt, &rfc850timeinfo, NULL);
    if (ret) {
        time_t rfc850time = mktime(&rfc850timeinfo);
        retDate = [NSDate dateWithTimeIntervalSince1970:rfc850time];
        if (retDate != nil)
            return retDate;
    }
    
    fmt = "%a %b %e %H:%M:%S %Y";
    struct tm asctimeinfo;
    memset(&asctimeinfo, 0, sizeof(asctimeinfo));
    ret = strptime_l(str, fmt, &asctimeinfo, NULL);
    if (ret) {
        time_t asctime = mktime(&asctimeinfo);
        return [NSDate dateWithTimeIntervalSince1970:asctime];
    }
    
    return nil;
}


// Get an RFC1123-compliant representation of a date.
- (NSString *) rfc1123String
{
    time_t date = (time_t) [self timeIntervalSince1970];
    struct tm timeinfo;
    gmtime_r(&date, &timeinfo);
    char buffer[32];
    size_t ret = strftime(buffer, sizeof(buffer), "%a, %d %b %Y %H:%M:%S GMT", &timeinfo);
    if (ret) {
        return @(buffer);
    } else {
        return nil;
    }
}

// Get an RFC3339-compliant representation of a date.
- (NSString *) rfc3339
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:[dateFormatter stringFromDate:self]];
    [result insertString:@":" atIndex:([result length] - 2)];
    return result;
}
@end

