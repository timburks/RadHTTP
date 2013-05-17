//
//  RadHTTPServer.m
//  RadHTTP
//
//  Created by Tim Burks on 2/24/12.
//  Copyright (c) 2012 Radtastical Inc. All rights reserved.
//
#import "RadHTTPServer.h"
#import "RadHTTPRequestRouter.h"

@implementation RadHTTPServer

+ (RadHTTPServer *) sharedServer {
    return nil;
}

static NSMutableDictionary *_mimetypes = nil;

+ (void) initialize
{
    _mimetypes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
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

+ (void) setMimeType:(NSString *) mimeType forExtension:(NSString *) extension
{
    [_mimetypes setObject:mimeType forKey:extension];
}

+ (NSString *) mimeTypeForFilename:(NSString *) filename
{
    NSString *mimetype = [_mimetypes objectForKey:[filename pathExtension]];
    if (mimetype) {
        return mimetype;
    } else {
        return @"text/html";
    }
}

- (id)initWithRequestRouter:(RadHTTPRequestRouter *) router
{
    if (self = [super init]) {
        self.router = router;
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
    return [self initWithRequestRouter:[[RadHTTPRequestRouter alloc] init]];
}

- (void) start
{
    
}

- (void) run
{
    
}

@end

@interface RadHTTPServer (Baked)
+ (void) macros;
@end

