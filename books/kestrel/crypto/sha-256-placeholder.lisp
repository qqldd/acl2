; Cryptography -- SHA-256 Placeholder
;
; Copyright (C) 2019 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "CRYPTO")

(include-book "kestrel/utilities/unsigned-byte-list-fixing" :dir :system)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection sha-256-placeholder
  :parents (placeholders)
  :short "SHA-256 placeholder."
  :long
  (xdoc::topstring
   (xdoc::p
    "SHA-256 is specified in the
     <a href=\"https://csrc.nist.gov/publications/detail/fips/180/4/final\"
     >FIPS PUB 180-4 standard</a>.")
   (xdoc::p
    "According to FIPS PUB 180-4,
     the input of SHA-256 is a sequence of less than @($2^{64}$) bits,
     or less than @($2^{61}$) bytes.
     This is formalized by the guard of the constrained function below.")
   (xdoc::p
    "According to FIPS PUB 180-4,
     the output of SHA-256 is a sequence of exactly 256 bits, or 32 bytes.
     We constrain our function to return a list of 32 bytes unconditionally.")
   (xdoc::p
    "We also constrain our function to fix its input to a true list of bytes.")
   (xdoc::def "sha-256"))

  (encapsulate

    (((sha-256 *) => *
      :formals (bytes)
      :guard (and (unsigned-byte-listp 8 bytes)
                  (< (len bytes) (expt 2 61)))))

    (local
     (defun sha-256 (bytes)
       (declare (ignore bytes))
       (make-list 32 :initial-element 0)))

    (defrule unsigned-byte-listp-8-of-sha-256
      (unsigned-byte-listp 8 (sha-256 bytes)))

    (defrule len-of-sha-256
      (equal (len (sha-256 bytes))
             32))

    (defrule sha-256-fixes-input
      (equal (sha-256 (unsigned-byte-list-fix 8 bytes))
             (sha-256 bytes))
      :enable unsigned-byte-list-fix))

  (defrule true-listp-of-sha-256
    (true-listp (sha-256 bytes))
    :rule-classes :type-prescription
    :use (:instance acl2::true-listp-when-unsigned-byte-listp
          (width 8) (x (sha-256 bytes)))
    :disable acl2::true-listp-when-unsigned-byte-listp)

  (defrule consp-of-sha-256
    (consp (sha-256 bytes))
    :rule-classes :type-prescription
    :use len-of-sha-256
    :disable len-of-sha-256))
