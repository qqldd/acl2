;; Julien Schmaltz
;; Generic Set of Nodes
;; June 17th 2005
;; File: GeNoC-nodeset.lisp

(in-package "ACL2")

(encapsulate  ;; GenericNodeSet
 ;; abstract set of nodes
 ;; the set is generated by the following function
 ;; its argument is the parameters
 (((NodesetGenerator *) => *) 
  ;; the following predicate recognizes valid parameters
  ((ValidParamsp *) => *)
  ;; the following predicate recognizes a valid node
  ((NodeSetp *) => *))
 
 ;; local witnesses
 (local (defun ValidParamsp (x) (declare (ignore x)) t))
 (local (defun NodesetGenerator (x) 
          (if (zp x) nil 
            (cons x (NodesetGenerator (1- x))))))

 (local (defun NodeSetp (l)
          (if (endp l) t
            (and (natp (car l))
                 (NodeSetp (cdr l))))))

 (defthm nodeset-generates-valid-nodes
   (implies (ValidParamsp params)
            (NodeSetp (NodesetGenerator params))))

 ;; we add a generic lemma 
 (defthm subsets-are-valid
   ;; this lemma is used to prove that routes are made of valid nodes
   (implies (and (NodeSetp x)
                 (subsetp y x))
            (NodeSetp y)))
) ;; end GenericNodeSet
