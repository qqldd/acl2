; OSLIB -- Operating System Utilities
; Copyright (C) 2013-2014 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Jared Davis <jared@centtech.com>

(in-package "OSLIB")

(defun argv-fn (state)

   (unless (live-state-p state)
     (error "ARGV can only be called on a live state.")
     (mv nil state))

   #+Clozure
   (let ((args ccl::*unprocessed-command-line-arguments*))
     ;; For this to work, the proper way to invoke CCL is through a wrapper
     ;; script along the lines of:
     ;;
     ;;   #!/bin/sh
     ;;   export CCL_DEFAULT_DIRECTORY=/blah/blah
     ;;   exec ccl -I my-image.ccl -K ISO-8859-1 -e "(myprog::main)" -- "$@"
     ;;
     ;; CCL removes the arguments it processes and doesn't include any program
     ;; name or anything like that, and just gives us the arguments past --, so
     ;; that's perfectly good.
     (cond ((string-listp args)
            (mv args state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+SBCL
   (let ((args sb-ext:*posix-argv*))
     ;; For this to work, the proper way to invoke SBCL is through a wrapper
     ;; script along the lines of:
     ;;
     ;;  #!/bin/sh
     ;;  export SBCL_HOME=/blah/blah
     ;;  exec /blah/blah/sbcl --core my-image.core --end-runtime-options \
     ;;    --eval "(myprog::main)" --end-toplevel-options "$@"
     ;;
     ;; The SBCL manual (section, "Command Line Options") talks about the differences
     ;; between runtime options and top-level options.  So see that if you want to also
     ;; include things like --dynamic-space-size, etc.
     ;;
     ;; SBCL removes the arguments it processes but leaves the program name as
     ;; the first member of args.  So to make ARGV consistent across Lisps,
     ;; we'll remove that.
     (cond ((atom args)
            (error "Expected ARGV on SBCL to always have at least the program name.")
            (mv nil state))
           ((string-listp args)
            ;; Strip out the program name
            (mv (cdr args) state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+Allegro
   (let ((args (sys:command-line-arguments :application t)))
     ;; For this to work, the proper way to invoke Allegro is through a wrapper
     ;; script along the lines of:
     ;;
     ;;  #!/bin/sh
     ;;  exec /blah/blah/alisp -I /blah/blah/blah.dxl -- "$@"
     ;;
     ;; By using :application t, we tell Allegro to throw away the arguments it
     ;; processes like -I.  But it still leaves in the program name, so as in
     ;; SBCL we need to CDR the args to throw that away.
     (cond ((atom arg)
            (error "Expected ARGV on Allegro to always have at least the program name.")
            (mv nil state))
           ((string-listp args)
            (mv (cdr args) state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+CLISP
   (let ((args ext:*args*))
     ;; For this to work, the proper way to invoke Clisp is through a wrapper
     ;; script along the lines of:
     ;;
     ;;   #!/bin/sh
     ;;   exec /blah/blah/clisp -i /blah/blah -M /blah/blah.mem -E ISO-8859-1 -- "$@"
     ;;
     ;; CLISP automatically throws away everything before the -- for us, and leaves
     ;; us just with the arguments, which is perfect.
     (cond ((string-listp args)
            (mv args state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+CMU
   (let ((args ext:*command-line-application-arguments*))
     ;; For this to work, the proper way to invoke CMUCL is through a wrapper
     ;; script along the lines of:
     ;;
     ;;   #!/bin/sh
     ;;   exec /blah/blah/lisp -core /blah/blah.core -eval '(myprog::main)' -- "$@"
     ;;
     ;; CMUCL puts the arguments after -- into the above, without any program
     ;; name or anything like that, which is perfect.
     (cond ((string-listp args)
            (mv args state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+gcl
   (let ((args si::*command-args*))
     ;; BOZO.  This isn't going to work perfectly because GCL doesn't seem to
     ;; have an equivalent of --.  For now I'm going to at least expect that the
     ;; wrapper script uses -- anyway, e.g., a proper wrapper script is:
     ;;
     ;;   #!/bin/sh
     ;;   exec /blah/blah/blah.gcl -eval '(myprog::main)' -- "$@"
     ;;
     ;; This way we can at least cut out the stuff that comes before --.  But
     ;; it's not perfect because GCL will still try to process options like
     ;; -eval, -f, etc., that happen to come in $@.
     (cond ((atom args)
            (error "ARGV expected GCL to have at least the program name.")
            (mv nil state))
           ((string-listp args)
            (mv (cdr (member-equal "--" args)) state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+lispworks
   (let ((args sys:*line-arguments-list*))
     ;; BOZO this is very similar to GCL.  There's apparently no proper support
     ;; for --, so do the smae hack as for GCL, which sort of works.  A proper
     ;; wrapper script is, e.g.,
     ;;
     ;;   #/bin/sh
     ;;   exec /blah/blah/image.lw -init - -siteinit - -- "$@"
     ;;
     ;; Again this isn't perfect.
     (cond ((atom args)
            (error "ARGV expected Lispworks to have at least the program name."))
           ((string-listp args)
            (mv (cdr (member-equal "--" args)) state))
           (t
            (error "ARGV found non string-listp arguments? ~a" args)
            (mv nil state))))

   #+(and (not Clozure)
          (not SBCL)
          (not Allegro)
          (not CLISP)
          (not CMU)
          (not gcl)
          (not lispworks))
   (progn
     (error "ARGV is not yet implemented on this host Lisp.")
     (mv nil state)))

