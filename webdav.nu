#!/usr/local/bin/nush
#
# This is a very rough start at a WebDAV server.
# Because of limitations in libevent, it currently only works with the Cocoa HTTP server.
#
# Developed using the litmus WebDAV test suite: http://www.webdav.org/neon/litmus/
#
(load "RadHTTP:macros")
(load "RadXML")
(load "RadJSON")
(load "RadCrypto")
(load "RadMongoDB")

(set ROOT "webdav")
(set SERVER "http://localhost:8080")

(get "/owncloud/remote.php/webdav"
     (puts ((REQUEST headers) description))
     (set authorization ((REQUEST headers) Authorization:))
     (puts authorization)
     (set parts (authorization componentsSeparatedByString:" "))
     (set b64 (parts 1))
     (set data (NSData dataWithBase64EncodedString:b64))
     (set pair ((NSString alloc) initWithData:data encoding:NSUTF8StringEncoding))
     (puts pair)
     nil
     )

(get "/owncloud/status.php"
     (set response (dict installed:"true"
                           version:"6.0.2.2"
                     versionstring:"6.0.2"
                           edition:""))
     (response JSONRepresentation))


(def file-exists (path)
     ((NSFileManager defaultManager) fileExistsAtPath:path))

(get "/*path:"
     (puts "GET")
     (puts (REQUEST path))
     (set pathToGet (+ ROOT "/" *path))
     (puts pathToGet)
     (cond ((not (file-exists pathToGet))
            (puts "NO FILE EXISTS")
            (RESPONSE setStatus:404)
            "")
           (else
                (set data (NSData dataWithContentsOfFile:(+ ROOT "/" *path)))
                (if data (then data) (else "")))))

(put "/*path:"
     (puts "PUTPUTPUTPUTPUT")
     (puts ((NSString alloc) initWithData:(REQUEST body) encoding:4))
     (set pathToWrite (+ ROOT "/" *path))
     (cond ((not (file-exists (pathToWrite stringByDeletingLastPathComponent)))
            (puts "putting into a nonexistent directory: #{pathToWrite}")
            (RESPONSE setStatus:409)
            "")
           (else ((REQUEST body) writeToFile:(+ ROOT "/" *path) atomically:NO)
                 (RESPONSE setStatus:201)
                 "ok")))

(delete "/*path:"
        (puts "DELETE #{*path}")
        (set pathToDelete (+ ROOT "/" *path))
        (cond ((not (file-exists pathToDelete))
               (RESPONSE setStatus:404)
               "")
              (else
                   (set fragment ((REQUEST URL) fragment))
                   (if (and fragment (fragment length))
                       (then (response setStatus:409)
                             "deleting path with nonempty fragment")
                       (else
                            (puts "deleting #{pathToDelete}")
                            (system "rm -rf #{pathToDelete}")
                            ;; delete properties for this path
                            (set mongo (RadMongoDB new))
                            (mongo removeWithCondition:(dict path:pathToDelete) fromCollection:"webdav.properties")
                            "ok")))))

(options "/*path:"
         (RESPONSE setValue:"OPTIONS, GET, HEAD, POST, PUT, DELETE, TRACE, COPY, MOVE, MKCOL, PROPFIND, PROPPATCH, LOCK, UNLOCK, ORDERPATCH"
              forHTTPHeader:"Allow")
         (RESPONSE setValue:"1, 2, ordered-collections"
              forHTTPHeader:"DAV")
         "")

(send &D=resourcetype setEmpty:YES)
(send &D=collection setEmpty:YES)

(macro &MARKUP (tag *stuff)
       `(progn (set operator (NuMarkupOperator operatorWithTag:,tag))
               (operator ,@*stuff)))

(def CDATA (value)
     (+ "<![CDATA[" value "]]>"))

(propfind "/*path:"
          (puts "propfind '#{*path}'")
          (puts (REQUEST body))
          
          (set props nil)
          (if (REQUEST body)
              (set string (NSString stringWithData:(REQUEST body) encoding:NSUTF8StringEncoding))
              (puts string)
              (set mongo (RadMongoDB new))
              (mongo connect)
              
              (set reader ((RadXMLReader alloc) init))
              (set command (reader readXMLFromString:string error:nil))
              
              (unless command
                      (RESPONSE setStatus:400)
                      (return "invalid XML"))
              
              (puts (command description))
              (set props "")
              (if (eq (command name) "propfind")
                  ((command children) each:
                   (do (prop)
                       (puts "PROP")
                       (puts (prop name))
                       (if (eq (prop name) "prop")
                           ((prop children) each:
                            (do (keyEntity)
                                (puts "KEY")
                                (set key (keyEntity name))
                                (puts key)
                                (set pathkey (+ *path "." key))
                                (set property (mongo findOne:(dict pathkey:pathkey) inCollection:"webdav.properties"))
                                (if property
                                    (puts (property description))
                                    (set value (property value:))
                                    (puts value)
                                    (set m (&MARKUP key xmlns:"http://example.com/neon/litmus/" value))
                                    (props appendString:m))))))))
              (puts props))
          (if (and props (props length))
              (then
                   (RESPONSE setStatus:207)
                   (set result (+ "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
                                  (&D=multistatus xmlns:D:"DAV:"
                                                  (&D=response (&D=href *path)
                                                               (&D=propstat (&D=prop props)
                                                                            (&D=status "HTTP/1.1 200 OK"))))))
                   (puts result)
                   result)
              (else
                   (set depth ((REQUEST headers) Depth:))
                   (puts "DEPTH: #{depth}")
                   (set files ((NSFileManager defaultManager)
                               contentsOfDirectoryAtPath:(+ ROOT "/" *path) error:nil))
                   (puts "FILES")
                   (puts (files description))
                   ;(set files (array (+ ROOT "/" *path)))
                   
                   (set pathForHREF *path)
                   (if (pathForHREF length) (set pathForHREF (+ pathForHREF "/")))
                   
                   (RESPONSE setStatus:207)
                   (set result (+ "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
                                  (&D=multistatus xmlns:D:"DAV:"
                                                  (&D=response (&D=href (+ SERVER "/" pathForHREF))
                                                               (&D=propstat (&D=prop (&D=getlastmodified "Sat, 15 Mar 2014 21:03:36 GMT")
                                                                                     ;(&D=getcontentlength (attributes NSFileSize:))
                                                                                     (&D=creationdate "Sat, 15 Mar 2014 21:03:36 GMT")
                                                                                     (&D=displayname (CDATA "."))
                                                                                     (&D=resourcetype (&D=collection)))
                                                                            (&D=status "HTTP/1.1 200 OK")))
                                                  "\n"
                                                  (files map:
                                                         (do (filename)
                                                             (set resourcename (+ SERVER "/" pathForHREF filename))
                                                             (set localname (+ ROOT "/" *path "/" filename))
                                                             (set exists ((NSFileManager defaultManager)
                                                                          fileExistsAtPath:localname
                                                                          isDirectory:(set isDirectory (NuPointer new))))
                                                             (set attributes ((NSFileManager defaultManager)
                                                                              attributesOfItemAtPath:localname error:nil))
                                                             (NSLog "FILE ATTRIBUTES")
                                                             (NSLog (attributes description))
                                                             (NSLog "is directory: #{(isDirectory value)}")
                                                             (+ (&D=response (&D=href resourcename)
                                                                             (&D=propstat (&D=prop (&D=getlastmodified "Sat, 15 Mar 2014 21:03:36 GMT")
                                                                                                   (&D=getcontentlength (attributes NSFileSize:))
                                                                                                   (&D=creationdate "Sat, 15 Mar 2014 21:03:36 GMT")
                                                                                                   (&D=resourcetype (if (isDirectory value)
                                                                                                                        (then (&D=collection))))
                                                                                                   ;(&D=displayname (CDATA filename))
                                                                                                   ;(&D=getcontenttype "text/plain")
                                                                                                   ;(&D=getetag "zzyzx")
                                                                                                   ;(&D=supportedlock (&D=lockentry (&D=lockscope (&D=exclusive))
                                                                                                   ;                                (&D=locktype (&D=write)))
                                                                                                   ;                  (&D=lockentry (&D=lockscope (&D=shared))
                                                                                                   ;                                (&D=locktype (&D=write))))
                                                                                                   )
                                                                                          (&D=status "HTTP/1.1 200 OK")))
                                                                "\n"))))))
                   (puts result)
                   result)))


(proppatch "/*path:"
           (set string (NSString stringWithData:(REQUEST body) encoding:NSUTF8StringEncoding))
           (set reader ((RadXMLReader alloc) init))
           (puts string)
           (set stuff (reader readXMLFromString:string error:nil))
           (set mongo (RadMongoDB new))
           (mongo connect)
           ((stuff children) each:
            (do (node)
                (set command (node name))
                (if (eq command "D:set")
                    ((node children) each:
                     (do (node2)
                         (set item (node2 name))
                         (if (eq item "D:prop")
                             ((node2 children) each:
                              (do (node3)
                                  (set key (node3 name))
                                  ((node3 children) each:
                                   (do (node4)
                                       (set value (node4 text))
                                       (puts "saving #{key}=#{value} for path #{*path}")
                                       (set pathkey (+ *path "." key))
                                       (mongo updateObject:(dict key:key value:value path:*path pathkey:pathkey)
                                              inCollection:"webdav.properties"
                                             withCondition:(dict pathkey:pathkey)
                                         insertIfNecessary:YES
                                     updateMultipleEntries:NO)
                                       ))))))))))
           "ok")


(mkcol "/*path:"
       (puts "MKCOL #{*path}")
       (set pathToCreate (+ ROOT "/" *path))
       (cond ((file-exists pathToCreate)
              (RESPONSE setStatus:405)
              "")
             ((and (not (file-exists (pathToCreate stringByDeletingLastPathComponent)))
                   (ne (*path stringByDeletingLastPathComponent) ""))
              (puts (+ "'" (pathToCreate stringByDeletingLastPathComponent) "' doesn't exist"))
              (RESPONSE setStatus:409)
              "")
             (((REQUEST body) length)
              (RESPONSE setStatus:415)
              "")
             (else (puts "creating #{pathToCreate}")
                   (system "mkdir -p #{pathToCreate}")
                   (RESPONSE setStatus:201)
                   "ok")))

(copy "/*path:"
      (puts "copy #{*path}")
      (set pathToCopyFrom (+ ROOT "/" *path))
      
      (set destination ((REQUEST headers) Destination:))
      (puts "DESTINATION: #{destination}")
      
      (set overwrite ((REQUEST headers) Overwrite:))
      
      (set pathToCopyTo (+ ROOT (destination stringByReplacingOccurrencesOfString:SERVER withString:"")))
      (puts "copying #{pathToCopyFrom} to #{pathToCopyTo}")
      
      (set destinationExists (file-exists pathToCopyTo))
      
      (cond ((and (eq overwrite "F") destinationExists)
             (RESPONSE setStatus:412)
             "")
            ((not (file-exists (pathToCopyTo stringByDeletingLastPathComponent)))
             (puts "no destination directory: #{(pathToCopyTo stringByDeletingLastPathComponent)}")
             (RESPONSE setStatus:409)
             "")
            (else
                 (system "cp -r #{pathToCopyFrom} #{pathToCopyTo}")
                 (if destinationExists
                     (then (RESPONSE setStatus:204))
                     (else (RESPONSE setStatus:201)))
                 "")))

(move "/*path:"
      (puts "move #{*path}")
      (set pathToMoveFrom (+ ROOT "/" *path))
      
      (set destination ((REQUEST headers) Destination:))
      (puts "DESTINATION: #{destination}")
      (set destination (destination stringByReplacingOccurrencesOfString:SERVER withString:""))
      
      (set overwrite ((REQUEST headers) Overwrite:))
      
      (set pathToMoveTo (+ ROOT destination))
      (puts "copying #{pathToMoveFrom} to #{pathToMoveTo}")
      
      (set destinationExists (file-exists pathToMoveTo))
      
      (cond ((and (eq overwrite "F") destinationExists)
             (RESPONSE setStatus:412)
             "")
            ((not (file-exists (pathToMoveTo stringByDeletingLastPathComponent)))
             (puts "no destination directory: #{(pathToMoveTo stringByDeletingLastPathComponent)}")
             (RESPONSE setStatus:409)
             "")
            (else
                 (system "mv #{pathToMoveFrom} #{pathToMoveTo}")
                 ;; transfer properties from source path to destination path
                 (set mongo (RadMongoDB new))
                 (mongo connect)
                 (set properties (mongo findArray:(dict path:*path) inCollection:"webdav.properties"))
                 (puts "properties to move")
                 (puts (properties description))
                 (properties each:
                             (do (property)
                                 (property path:destination pathkey:(+ destination "." (property key:)))
                                 (property removeObjectForKey:"_id")
                                 (puts (property description))
                                 (mongo updateObject:property inCollection:"webdav.properties" withCondition:(dict pathkey:(property pathkey:)) insertIfNecessary:NO updateMultipleEntries:NO)))
                 (if destinationExists
                     (then (RESPONSE setStatus:204))
                     (else (RESPONSE setStatus:201)))
                 "")))

(RadLibEVHTPServer run)

