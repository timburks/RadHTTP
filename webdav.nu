#!/usr/local/bin/nush
#
# This is a very rough start at a WebDAV server.
# Because of limitations in libevent, it currently only works with the Cocoa HTTP server.
#
# Developed using the litmus WebDAV test suite: http://www.webdav.org/neon/litmus/
#
(load "RadHTTP:macros")
(load "RadXML")

(set ROOT "webdav")
(set SERVER "http://localhost:8080")

(def file-exists (path)
     ((NSFileManager defaultManager) fileExistsAtPath:path))

(get "/*path:"
     (puts (REQUEST path))
     (set pathToGet (+ ROOT "/" *path))
     (cond ((not (file-exists pathToGet))
            (RESPONSE setStatus:404)
            "")
           (else (NSData dataWithContentsOfFile:(+ ROOT "/" *path)))))

(put "/*path:"
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
              (else (puts "deleting #{pathToDelete}")
                    (system "rm -rf #{pathToDelete}")
                    "ok")))

(options "/*path:"
         (RESPONSE setValue:"OPTIONS, GET, HEAD, POST, PUT, DELETE, TRACE, COPY, MOVE, MKCOL, PROPFIND, PROPPATCH, LOCK, UNLOCK, ORDERPATCH"
              forHTTPHeader:"Allow")
         (RESPONSE setValue:"1, 2, ordered-collections"
              forHTTPHeader:"DAV")
         "")

(send &D=resourcetype setEmpty:YES)

(propfind "/*path:"
          (puts "propfind '#{*path}'")
          (set string (NSString stringWithData:(REQUEST body) encoding:NSUTF8StringEncoding))
          
          (set reader ((RadXMLReader alloc) init))
          (set stuff (reader readXMLFromString:string error:nil))
          
          (puts string )
          (puts (stuff description))
          
          
          (unless stuff
                  (RESPONSE setStatus:400)
                  (return ""))
          
          (set files ((NSFileManager defaultManager)
                      contentsOfDirectoryAtPath:(+ ROOT "/" *path) error:nil))
          (set files (array (+ ROOT "/" *path)))
          
          (RESPONSE setStatus:207)
          (set result (+ "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
                         (&D=multistatus xmlns:D:"DAV:"
                                         (files map:
                                                (do (filename)
                                                    (set resourcename (filename stringByReplacingOccurrencesOfString:ROOT withString:SERVER))
                                                    (set exists ((NSFileManager defaultManager)
                                                                 fileExistsAtPath:filename
                                                                 isDirectory:(set isDirectory (NuPointer new))))
                                                    (set attributes ((NSFileManager defaultManager) attributesOfItemAtPath:filename error:nil))
                                                    (NSLog "FILE ATTRIBUTES")
                                                    (NSLog (attributes description))
                                                    (NSLog "is directory: #{(isDirectory value)}")
                                                    (&D=response (&D=href resourcename)
                                                                 (&D=propstat (&D=prop (&D=getlastmodified ((attributes NSFileModificationDate:) description))
                                                                                       (&D=getcontentlength (attributes NSFileSize:))
                                                                                       (&D=creationdate ((attributes NSFileCreationDate:) description))
                                                                                       (&D=resourcetype (if (isDirectory value)
                                                                                                            (then (&D=collection))))
                                                                                       ;(&D=displayname "Example HTML resource")
                                                                                       ;(&D=getcontenttype "text/plain")
                                                                                       ;(&D=getetag "zzyzx")
                                                                                       ;(&D=supportedlock (&D=lockentry (&D=lockscope (&D=exclusive))
                                                                                       ;                                (&D=locktype (&D=write)))
                                                                                       ;                  (&D=lockentry (&D=lockscope (&D=shared))
                                                                                       ;                                (&D=locktype (&D=write))))
                                                                                       )
                                                                              (&D=status "HTTP/1.1 200 OK"))))))))
          (puts result)
          result)

(proppatch "/*path:"
           (set string (NSString stringWithData:(REQUEST body) encoding:NSUTF8StringEncoding))
           
           (set reader ((RadXMLReader alloc) init))
           (set stuff (reader readXMLFromString:string error:nil))
           
           (puts string )
           (puts (stuff description))
           "ok"
           )


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
      
      (set overwrite ((REQUEST headers) Overwrite:))
      
      (set pathToMoveTo (+ ROOT (destination stringByReplacingOccurrencesOfString:SERVER withString:"")))
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
                 (if destinationExists
                     (then (RESPONSE setStatus:204))
                     (else (RESPONSE setStatus:201)))
                 "")))

(RadHTTPServer run)

