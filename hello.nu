#!/usr/local/bin/nush
(load "RadHTTP:macros")

(get "/" "Hi there")

(get "/ps"
     (RESPONSE setValue:"text/plain" forHTTPHeader:"Content-Type")
     (NSString stringWithShellCommand:"ps uax"))

(get "/get" "GET")
(post "/post" "POST")
(put "/put" "PUT")
(delete "/delete" "DELETE")

(RadHTTPServer run)

