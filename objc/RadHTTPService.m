//
//  RadHTTPService.m
//  RadHTTP
//
//  Created by Tim Burks on 5/16/13.
//  Copyright (c) 2013 Radtastical Inc. All rights reserved.
//

#include <dispatch/dispatch.h>
#import "RadHTTPService.h"
#import "RadHTTPRequestRouter.h"
#import "RadHTTPRequestHandler.h"

@interface RadHTTPService ()
@property (nonatomic, strong) RadHTTPRequestRouter *router;
@property (nonatomic, strong) NSMutableDictionary *mimetypes;
@end

@implementation RadHTTPService
@synthesize router, mimetypes;

+ (RadHTTPService *) sharedService
{
    static dispatch_once_t once;
    static RadHTTPService *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id) init {
    if (self = [super init]) {
        self.router = [[RadHTTPRequestRouter alloc] init];
        self.mimetypes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          @"text/plain", @"txt",
                          @"text/css", @"css",
                          @"text/html", @"html",
                          @"text/javascript", @"js",
                          @"image/jpeg", @"jpeg",
                          @"image/jpeg", @"jpg",
                          @"image/png", @"png",
                          @"image/gif", @"gif",
                          @"image/bmp", @"bmp",
                          @"image/x-icon", @"ico",
                          @"application/vnd.apple.mpegURL", @"m3u8",
                          @"video/MP2T", @"ts",
                          @"video/mp4", @"mp4",
                          @"application/pdf", @"pdf",
                          @"application/xml", @"xml",
                          @"text/xml", @"plist",
                          @"application/octet-stream", @"ipa",
                          @"application/octet-stream", @"mobileprovision",
                          @"application/x-apple-aspen-config", @"mobileconfig",
                          @"application/postscript", @"ai",
                          @"text/plain", @"asc",
                          nil];
        
        /* todo
         "avi"   "video/x-msvideo"
         "bin"   "application/octet-stream"
         "bmp"   "image/bmp"
         "class" "application/octet-stream"
         "cer"   "application/pkix-cert"
         "crl"   "application/pkix-crl"
         "crt"   "application/x-x509-ca-cert"
         "css"   "text/css"
         "dll"   "application/octet-stream"
         "dmg"   "application/octet-stream"
         "dms"   "application/octet-stream"
         "doc"   "application/msword"
         "dvi"   "application/x-dvi"
         "eps"   "application/postscript"
         "etx"   "text/x-setext"
         "exe"   "application/octet-stream"
         "gif"   "image/gif"
         "htm"   "text/html"
         "html"  "text/html"
         "ico"   "application/icon"
         "ics"   "text/calendar"
         "jpe"   "image/jpeg"
         "jpeg"  "image/jpeg"
         "jpg"   "image/jpeg"
         "js"    "text/javascript"
         "lha"   "application/octet-stream"
         "lzh"   "application/octet-stream"
         "mobileconfig"   "application/x-apple-aspen-config"
         "mov"   "video/quicktime"
         "mp4" "video/mp4"
         "mpe"   "video/mpeg"
         "mpeg"  "video/mpeg"
         "mpg"   "video/mpeg"
         "m3u8"  "application/x-mpegURL"
         "pbm"   "image/x-portable-bitmap"
         "pdf"   "application/pdf"
         "pgm"   "image/x-portable-graymap"
         "png"   "image/png"
         "pnm"   "image/x-portable-anymap"
         "ppm"   "image/x-portable-pixmap"
         "ppt"   "application/vnd.ms-powerpoint"
         "ps"    "application/postscript"
         "qt"    "video/quicktime"
         "ras"   "image/x-cmu-raster"
         "rb"    "text/plain"
         "rd"    "text/plain"
         "rtf"   "application/rtf"
         "sgm"   "text/sgml"
         "sgml"  "text/sgml"
         "so"    "application/octet-stream"
         "tif"   "image/tiff"
         "tiff"  "image/tiff"
         "ts"    "video/MP2T"
         "txt"   "text/plain"
         "xbm"   "image/x-xbitmap"
         "xls"   "application/vnd.ms-excel"
         "xml"   "text/xml"
         "xpm"   "image/x-xpixmap"
         "xwd"   "image/x-xwindowdump"
         "zip"   "application/zip"
         */
    }
    return self;
}

- (void) setMimeType:(NSString *) mimeType forExtension:(NSString *) extension
{
    [self.mimetypes setObject:mimeType forKey:extension];
}

- (NSString *) mimeTypeForFilename:(NSString *) filename
{
    NSString *mimetype = [self.mimetypes objectForKey:[filename pathExtension]];
    if (mimetype) {
        return mimetype;
    } else {
        return @"text/html";
    }
}

- (void) addHandlerWithHTTPMethod:(NSString *) method path:(NSString *) path block:(id) block
{
    [self.router insertHandler:[RadHTTPRequestHandler handlerWithHTTPMethod:method path:path block:block]
                  level:0];
}

- (void) addHandlerWithPath:(NSString *) path directory:(NSString *) directory
{
    [self.router insertHandler:[RadHTTPRequestHandler handlerWithPath:path directory:directory]
                  level:0];
}

- (RadHTTPResponse *) responseForHTTPRequest:(RadHTTPRequest *) request
{
    return [self.router responseForHTTPRequest:request];
}

@end
