;; to update the associated source file, run this:
;; nubake RadHTTPServer+Baked.nu --method macros --category Baked --class RadHTTPServer

;; use this to declare get actions.
(macro get (path *body)
       `((RadHTTPService sharedService)
         addHandlerWithHTTPMethod:"GET"
         path:,path
         block:(do (REQUEST)
                   (set RESPONSE ((RadHTTPResponse alloc) init))
                   ((REQUEST bindings) each:(do (key value) (_parser setValue:value forKey:key)))
                   (set result nil)
                   (try (set result (progn ,@*body))
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

;; use this to declare post actions.
(macro post (path *body)
       `((RadHTTPService sharedService)
         addHandlerWithHTTPMethod:"POST"
         path:,path
         block:(do (REQUEST)
                   (set RESPONSE ((RadHTTPResponse alloc) init))
                   ((REQUEST bindings) each:(do (key value) (_parser setValue:value forKey:key)))
                   (set result nil)
                   (try (set result (progn ,@*body))
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

;; use this to declare put actions.
(macro put (path *body)
       `((RadHTTPService sharedService)
         addHandlerWithHTTPMethod:"PUT"
         path:,path
         block:(do (REQUEST)
                   (set RESPONSE ((RadHTTPResponse alloc) init))
                   ((REQUEST bindings) each:(do (key value) (_parser setValue:value forKey:key)))
                   (set result nil)
                   (try (set result (progn ,@*body))
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

;; use this to declare delete actions.
(macro delete (path *body)
       `((RadHTTPService sharedService)
         addHandlerWithHTTPMethod:"DELETE"
         path:,path
         block:(do (REQUEST)
                   (set RESPONSE ((RadHTTPResponse alloc) init))
                   ((REQUEST bindings) each:(do (key value) (_parser setValue:value forKey:key)))
                   (set result nil)
                   (try (set result (progn ,@*body))
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

;; use this to declare file handlers.
(macro files (path directory)
       `((RadHTTPService sharedService)
         addHandlerWithPath:,path directory:,directory))
