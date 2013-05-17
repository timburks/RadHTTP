#!/usr/local/bin/nush
(load "RadHTTP:macros")

(get "/" (&html (&body (&h1 "Hello, world."))))

(RadHTTPServer run)

