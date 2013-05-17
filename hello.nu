#!/usr/local/bin/nush
(load "RadHTTP:macros")

(get "/" "hello, world.")

(set s ((RadCocoaHTTPServer alloc) initWithRequestRouter:(RadHTTPRequestRouter sharedRouter)))
(s run)

