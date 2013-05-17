#!/usr/local/bin/nush
(load "RadHTTP:macros")

(get "/" (&html (&body (&h1 "Hello, world."))))

(get "/ps"
     (RESPONSE setValue:"text/plain" forHTTPHeader:"Content-Type")
     (NSString stringWithShellCommand:"ps uax"))

(RadHTTPServer run)

