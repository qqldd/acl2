; Typed Osets -- Fixtype Generator
;
; Copyright (C) 2019 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "FTY")

(include-book "centaur/fty/top" :dir :system)
(include-book "kestrel/utilities/xdoc/constructors" :dir :system)
(include-book "std/util/defrule" :dir :system)
(include-book "std/osets/top" :dir :system)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc defset

  :parents (typed-osets std/osets)

  :short "Generate a <see topic='@(url fty::fty)'>fixtype</see>
          of <see topic='@(url set::std/osets)'>osets</see>
          whose elements have a specified fixtype."

  :long

  (xdoc::topstring

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   (xdoc::h3 "Introduction")

   (xdoc::p
    "This is analogous to @(tsee fty::deflist) and @(tsee fty::defalist).
     Besides the fixtype itself,
     this macro also generates theorems about the fixtype.")

   (xdoc::p
    "Future versions of this macro may be modularized to provide
     a ``sub-macro'' that generates only the recognizer and theorems about it,
     without the fixtype (and without the fixer and equivalence),
     similarly to @(tsee std::deflist) and @(tsee std::defalist).
     That sub-macro could be called @('set::defset').")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   (xdoc::h3 "General Form")

   (xdoc::@code
    "(defset type"
    "        :elt-type ..."
    "        :pred ..."
    "        :fix ..."
    "        :equiv ..."
    "        :parents ..."
    "        :short ..."
    "        :long ...")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   (xdoc::h3 "Inputs")

   (xdoc::desc
    "@('type')"
    (xdoc::p
     "The name of the new fixtype."))

   (xdoc::desc
    "@(':elt-type')"
    (xdoc::p
     "The (existing) fixtype of the elements of the new set fixtype."))

   (xdoc::desc
    "@(':pred')
     <br/>
     @(':fix')
     <br/>
     @(':equiv')"
    (xdoc::p
     "The name of the recognizer, fixer, and equivalence for the new fixtype.")
    (xdoc::p
     "The defaults are @('name') followed by
      @('-p'), @('-fix'), and @('-equiv')."))

   (xdoc::desc
    "@(':parents')
     <br/>
     @(':short')
     <br/>
     @(':long')"
    (xdoc::p
     "These are used to generate XDOC documentation
      for the topic @('name').")
    (xdoc::p
     "If any of these is not supplied, the corresponding component
      is omitted from the generated XDOC topic."))

   (xdoc::p
    "This macro currently does not perform a thorough validation of its inputs.
     Erroneous inputs may result in failures of the generated events.
     Errors should be easy to diagnose,
     also since this macro has a very simple and readable implementation.
     Future versions of this macro
     should perform more thorough input validation.")

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   (xdoc::h3 "Generated Events")

   (xdoc::p
    "The following are generated, inclusive of XDOC documentation:")

   (xdoc::ul

    (xdoc::li
     "The recognizer, the fixer, the equivalence, and the fixtype.")

    (xdoc::li
     "Several theorems about the recognizer, fixer, and equivalence."))

   (xdoc::p
    "See the implementation, which uses a readable backquote notation,
     for details.")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc defset-implementation
  :parents (defset)
  :short "Implementation of @(tsee defset).")

; TODO: move to a more general place:
(define get-fixtype-pred ((type symbolp) (wrld plist-worldp))
  :returns (pred "A @(tsee symbolp).")
  :verify-guards nil
  :parents (defset-implementation)
  :short "Retrieve the recognizer of an existing fixtype."
  (b* ((fixtypes-table (table-alist 'fixtypes wrld))
       (fixtypes-map (cdar fixtypes-table))
       (type-map (cdr (assoc-eq type fixtypes-map)))
       (pred (cdr (assoc-eq 'pred type-map))))
    pred))

(define defset-fn (type elt-type pred fix equiv parents short long state)
  :returns (mv erp
               (event "A @(tsee acl2::maybe-pseudo-event-formp).")
               state)
  :mode :program
  :parents (defset-implementation)
  :short "Event generated by @(tsee defset)."
  (b* ((pred (or pred (acl2::add-suffix-to-fn type "-P")))
       (fix (or fix (acl2::add-suffix-to-fn type "-FIX")))
       (equiv (or equiv (acl2::add-suffix-to-fn type "-EQUIV")))
       (setp-when-pred (acl2::packn-pos (list 'setp-when- pred)
                                        (pkg-witness
                                         (symbol-package-name pred))))
       (fix-when-pred (acl2::packn-pos (list fix '-when- pred)
                                       (pkg-witness
                                        (symbol-package-name pred))))
       (elt-pred (get-fixtype-pred elt-type (w state))))
    (value
     `(encapsulate
        ()
        (define ,pred (x)
          :returns (yes/no booleanp)
          :parents (,type)
          :short ,(concatenate
                   'string
                   "Recognizer for the fixtype @(tsee "
                   (acl2::string-downcase (symbol-package-name type))
                   "::"
                   (acl2::string-downcase (symbol-name type))
                   ").")
          (if (atom x)
              (null x)
            (and (,elt-pred (car x))
                 (or (null (cdr x))
                     (and (consp (cdr x))
                          (acl2::fast-<< (car x) (cadr x))
                          (,pred (cdr x))))))
          :no-function t
          ///
          (defrule ,setp-when-pred
            (implies (,pred x)
                     (set::setp x))
            :enable set::setp))
        (define ,fix ((x ,pred))
          :returns (fixed-x ,pred)
          :parents (,type)
          :short ,(concatenate
                   'string
                   "Fixer for the fixtype @(tsee "
                   (acl2::string-downcase (symbol-package-name type))
                   "::"
                   (acl2::string-downcase (symbol-name type))
                   ").")
          (mbe :logic (if (,pred x) x nil)
               :exec x)
          :no-function t
          ///
          (defrule ,fix-when-pred
            (implies (,pred x)
                     (equal (,fix x) x))))
        (defsection ,type
          ,@(and parents (list :parents parents))
          ,@(and short (list :short short))
          ,@(and long (list :long long))
          (fty::deffixtype ,type
            :pred ,pred
            :fix ,fix
            :equiv ,equiv
            :define t
            :forward t))))))

(defsection defset-macro-definition
  :parents (defset-implementation)
  :short "Definition of the @(tsee defset) macro."
  :long (xdoc::def "defset")
  (defmacro defset (type &key
                         elt-type
                         pred fix equiv
                         parents short long)
    `(make-event (defset-fn
                   ',type
                   ',elt-type
                   ',pred
                   ',fix
                   ',equiv
                   ',parents
                   ,short
                   ,long
                   state))))
