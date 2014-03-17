;; to update the associated source file, run this:
;; nubake RadHTTPServer+Baked.nu --method macros --category Baked --class RadHTTPServer

(macro _httphandler (method path body)
       `((RadHTTPService sharedService)
         addHandlerWithHTTPMethod:,method
         path:,path
         block:(do (REQUEST)
                   (set RESPONSE ((RadHTTPResponse alloc) init))
                   ((REQUEST bindings) each:(do (key value) (_parser setValue:value forKey:key)))
                   (set result nil)
                   (try (set result (progn ,@body))
                        (catch (exception)
                               (if (exception isKindOfClass:(NuReturnException class))
                                   (then (set result (exception value))
                                         (else (puts (exception description))))
                                   (else (puts (exception description))
                                         (throw exception)))))
                   (if result
                       (then (RESPONSE setBody:result)
                             RESPONSE)
                       (else nil)))))

;; Use these to declare the standard HTTP actions.

(macro head (path *body)
       `(_httphandler "HEAD" ,path ,*body))

(macro get (path *body)
       `(_httphandler "GET" ,path ,*body))

(macro post (path *body)
       `(_httphandler "POST" ,path ,*body))

(macro put (path *body)
       `(_httphandler "PUT" ,path ,*body))

(macro delete (path *body)
       `(_httphandler "DELETE" ,path ,*body))

;; Use this to declare "get" handlers for files in a specified directory.

(macro files (path directory)
       `((RadHTTPService sharedService)
         addHandlerWithPath:,path directory:,directory))

;; Use these additional macros to declare WebDAV actions.

(macro mkcol (path *body)
       `(_httphandler "MKCOL" ,path ,*body))

(macro copy (path *body)
       `(_httphandler "COPY" ,path ,*body))

(macro move (path *body)
       `(_httphandler "MOVE" ,path ,*body))

(macro options (path *body)
       `(_httphandler "OPTIONS" ,path ,*body))

(macro propfind (path *body)
       `(_httphandler "PROPFIND" ,path ,*body))

(macro proppatch (path *body)
       `(_httphandler "PROPPATCH" ,path ,*body))

(macro lock (path *body)
       `(_httphandler "LOCK" ,path ,*body))

(macro unlock (path *body)
       `(_httphandler "UNLOCK" ,path ,*body))

(macro trace (path *body)
       `(_httphandler "TRACE" ,path ,*body))

(macro connect (path *body)
       `(_httphandler "CONNECT" ,path ,*body))

(macro patch (path *body)
       `(_httphandler "PATCH" ,path ,*body))
