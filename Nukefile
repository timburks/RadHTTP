;;
;; Nukefile for RadHTTP
;;
;; Commands:
;;	nuke 		- builds RadHTTP as a framework
;;	nuke test	- runs the unit tests in the NuTests directory
;;	nuke install	- installs RadHTTP in /Library/Frameworks
;;	nuke clean	- removes build artifacts
;;	nuke clobber	- removes build artifacts and RadHTTP.framework
;;
;; The "nuke" build tool is installed with Nu (http://programming.nu)
;;

;; the @variables below are instance variables of a NukeProject.
;; for details, see tools/nuke in the Nu source distribution.

;; source files
(set @m_files     (filelist "^objc/.*.m$"))
(set @nu_files     (filelist "^nu/.*.nu$"))

(set SYSTEM ((NSString stringWithShellCommand:"uname") chomp))

(case SYSTEM
      ("Darwin"
               (set @arch (list "x86_64"))
               (set @cflags "-DDARWIN -g -fobjc-arc")
               (set @ldflags "-framework Foundation -framework CoreServices -levent"))
      ("Linux"
              (set @arch (list "x86_64"))
              (set gnustep_flags ((NSString stringWithShellCommand:"gnustep-config --objc-flags") chomp))
              (set gnustep_libs ((NSString stringWithShellCommand:"gnustep-config --base-libs") chomp))
              (set @cflags "-g -DLINUX -I/usr/local/include #{gnustep_flags} -fconstant-string-class=NSConstantString -fobjc-nonfragile-abi -fobjc-arc -fblocks")

              (set @ldflags "#{gnustep_libs} -ldispatch -levent"))
      (else nil))


;; framework description
(set @framework "RadHTTP")
(set @framework_identifier   "com.radtastical.radhttp")
(set @framework_creator_code "????")

(compilation-tasks)
(framework-tasks)

(task "clobber" => "clean" is
      (SH "rm -rf #{@framework_dir}")) ;; @framework_dir is defined by the nuke framework-tasks macro

(task "default" => "framework")

