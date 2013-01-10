

(in-package "GL")


(include-book "bvecs")

(include-book "tools/bstar" :dir :system)

(defthm consp-bfr-eval-list
  (equal (consp (bfr-eval-list x env))
         (consp x))
  :hints(("Goal" :in-theory (enable bfr-eval-list))))

(defthm bfr-eval-list-consts
  (implies (and (syntaxp (and (quotep x)
                              (boolean-listp (cadr x))))
                (boolean-listp x))
           (equal (bfr-eval-list x env) x)))

(local (bfr-reasoning-mode t))

;; If/then/else where the branches are (unsigned) bit vectors
(defn bfr-ite-bvv-fn1 (c v1 v0)
  (declare (xargs :measure (+ (acl2-count v1) (acl2-count v0))
                  :guard (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))))
  (if (and (atom v1) (atom v0))
      nil
    (let ((tail (bfr-ite-bvv-fn1 c (if (atom v1) nil (cdr v1))
                          (if (atom v0) nil (cdr v0))))
          (head (bfr-ite-fn c (if (atom v1) nil (car v1))
                            (if (atom v0) nil (car v0)))))
      (if (or head tail)
          (cons head tail)
        nil))))

(defn bfr-ite-bvv-fn (c v1 v0)
  (declare (xargs :guard (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))))
  (bfr-fix-vars
   (c)
   (bfr-list-fix-vars
    (v1 v0)
    (bfr-ite-bvv-fn1 c v1 v0))))

(defcong bfr-equiv equal (bfr-ite-bvv-fn c v1 v0) 1)
(defcong bfr-list-equiv equal (bfr-ite-bvv-fn c v1 v0) 2)
(defcong bfr-list-equiv equal (bfr-ite-bvv-fn c v1 v0) 3)

(defmacro bfr-ite-bvv (c v1 v0)
  `(let ((bfr-ite-bvv-test ,c))
     (if bfr-ite-bvv-test
         (if (eq bfr-ite-bvv-test t)
             ,v1
           (bfr-ite-bvv-fn bfr-ite-bvv-test ,v1 ,v0))
       ,v0)))

(defn bfr-ite-bss-fn1 (c v1 v0)
  (declare (xargs :measure (+ (acl2-count v1) (acl2-count v0))
                  :guard (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))))
  (b* (((mv head1 tail1 end1) (if (atom v1)
                                  (mv nil nil t)
                                (if (atom (cdr v1))
                                    (mv (car v1) v1 t)
                                  (mv (car v1) (cdr v1) nil))))
       ((mv head0 tail0 end0) (if (atom v0)
                                  (mv nil nil t)
                                (if (atom (cdr v0))
                                    (mv (car v0) v0 t)
                                  (mv (car v0) (cdr v0) nil)))))
    (if (and end1 end0)
        (list (bfr-ite-fn c head1 head0))
      (let ((rst (bfr-ite-bss-fn1 c tail1 tail0))
            (head (bfr-ite c head1 head0)))
        (if (and (atom (cdr rst)) (hqual head (car rst)))
            rst
          (cons head rst))))))

(defn bfr-ite-bss-fn (c v1 v0)
  (declare (xargs :guard (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))))
  (bfr-fix-vars
   (c)
   (bfr-list-fix-vars
    (v1 v0)
    (bfr-ite-bss-fn1 c v1 v0))))

(defcong bfr-equiv equal (bfr-ite-bss-fn c v1 v0) 1)
(defcong bfr-list-equiv equal (bfr-ite-bss-fn c v1 v0) 2)
(defcong bfr-list-equiv equal (bfr-ite-bss-fn c v1 v0) 3)

(defmacro bfr-ite-bss (c v1 v0)
  `(let ((bfr-ite-bss-test ,c))
     (if bfr-ite-bss-test
         (if (eq bfr-ite-bss-test t)
             ,v1
           (bfr-ite-bss-fn bfr-ite-bss-test ,v1 ,v0))
       ,v0)))


(add-macro-alias bfr-ite-bss bfr-ite-bss-fn)

(defthmd v2n-bfr-eval-list-atom
  (implies (atom x)
           (equal (v2n (bfr-eval-list x env)) 0))
  :hints (("goal" :in-theory (enable v2n bfr-eval-list))))


(defthmd bfr-ite-bvv-fn1-nil
  (implies (and (not (bfr-ite-bvv-fn1 c v1 v0))
                (bfr-p c) (bfr-listp v1) (bfr-listp v0))
           (and (implies (bfr-eval c env)
                         (equal (v2n (bfr-eval-list v1 env)) 0))
                (implies (not (bfr-eval c env))
                         (equal (v2n (bfr-eval-list v0 env)) 0))))
  :hints (("Goal" :in-theory (enable v2n bfr-eval-list bfr-listp)))
  :otf-flg t)

(defthmd bfr-ite-bvv-fn-nil
  (implies (not (bfr-ite-bvv-fn c v1 v0))
           (and (implies (bfr-eval c env)
                         (equal (v2n (bfr-eval-list v1 env)) 0))
                (implies (not (bfr-eval c env))
                         (equal (v2n (bfr-eval-list v0 env)) 0))))
  :hints (("Goal" :use ((:instance bfr-ite-bvv-fn1-nil
                                   (c (bfr-fix c))
                                   (v1 (bfr-list-fix v1))
                                   (v0 (bfr-list-fix v0))))))
  :otf-flg t)


(defthmd v2n-bfr-ite-bvv-fn1
  (implies (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))
           (equal (v2n (bfr-eval-list (bfr-ite-bvv-fn1 c v1 v0) env))
                  (if (bfr-eval c env)
                      (v2n (bfr-eval-list v1 env))
                    (v2n (bfr-eval-list v0 env)))))
  :hints (("Goal" :in-theory (enable v2n bfr-eval-list))))

(defthm v2n-bfr-ite-bvv-fn
  (equal (v2n (bfr-eval-list (bfr-ite-bvv-fn c v1 v0) env))
         (if (bfr-eval c env)
             (v2n (bfr-eval-list v1 env))
           (v2n (bfr-eval-list v0 env))))
  :hints (("Goal" :use ((:instance v2n-bfr-ite-bvv-fn1
                                   (c (bfr-fix c))
                                   (v1 (bfr-list-fix v1))
                                   (v0 (bfr-list-fix v0)))))))


(defthmd v2i-bfr-ite-bss-fn1
  (implies (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))
           (equal (v2i (bfr-eval-list (bfr-ite-bss-fn1 c v1 v0) env))
                  (if (bfr-eval c env)
                      (v2i (bfr-eval-list v1 env))
                    (v2i (bfr-eval-list v0 env)))))
  :hints(("Goal" :in-theory (enable v2i bfr-eval-list))))

(defthm v2i-bfr-ite-bss-fn
  (equal (v2i (bfr-eval-list (bfr-ite-bss-fn c v1 v0) env))
         (if (bfr-eval c env)
             (v2i (bfr-eval-list v1 env))
           (v2i (bfr-eval-list v0 env))))
  :hints (("Goal" :use ((:instance v2i-bfr-ite-bss-fn1
                                   (c (bfr-fix c))
                                   (v1 (bfr-list-fix v1))
                                   (v0 (bfr-list-fix v0)))))))


(defthmd bfr-listp-bfr-ite-bvv-fn1
  (implies (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))
           (bfr-listp (bfr-ite-bvv-fn1 c v1 v0))))

(defthm bfr-listp-bfr-ite-bvv-fn
  (bfr-listp (bfr-ite-bvv-fn c v1 v0))
  :hints(("Goal" :in-theory (enable bfr-listp-bfr-ite-bvv-fn1))))

(defthmd bfr-listp-bfr-ite-bss-fn1
  (implies (and (bfr-p c) (bfr-listp v1) (bfr-listp v0))
           (bfr-listp (bfr-ite-bss-fn1 c v1 v0))))

(defthm bfr-listp-bfr-ite-bss-fn
  (bfr-listp (bfr-ite-bss-fn c v1 v0))
  :hints(("Goal" :in-theory (enable bfr-listp-bfr-ite-bss-fn1))))




(defthmd boolean-listp-bfr-listp
  (implies (boolean-listp x)
           (bfr-listp x)))


(defthmd boolean-listp-bfr-ite-bvv-fn-v2n-bind-env-car-env
  (implies (and (bind-free '((env . (car env))) (env))
                (boolean-listp (bfr-ite-bvv-fn c v1 v0)))
           (equal (v2n (bfr-ite-bvv-fn c v1 v0))
                  (if (bfr-eval c env)
                      (v2n (bfr-eval-list v1 env))
                    (v2n (bfr-eval-list v0 env)))))
  :hints (("goal" :use ((:instance bfr-eval-list-consts
                                   (x (bfr-ite-bvv-fn c v1 v0)))
                        v2n-bfr-ite-bvv-fn)
           :in-theory (e/d (boolean-listp-bfr-listp)
                           (bfr-ite-bvv-fn v2n-bfr-ite-bvv-fn
                               bfr-eval-list-consts)))))

(defthmd boolean-listp-bfr-ite-bss-fn-v2i-bind-env-car-env
  (implies (and (bind-free '((env . (car env))) (env))
                (boolean-listp (bfr-ite-bss-fn c v1 v0)))
           (equal (v2i (bfr-ite-bss-fn c v1 v0))
                  (if (bfr-eval c env)
                      (v2i (bfr-eval-list v1 env))
                    (v2i (bfr-eval-list v0 env)))))
  :hints (("goal" :use ((:instance bfr-eval-list-consts
                                   (x (bfr-ite-bss-fn c v1 v0)))
                        v2i-bfr-ite-bss-fn)
           :in-theory (e/d (boolean-listp-bfr-listp)
                           (bfr-ite-bss-fn v2i-bfr-ite-bss-fn
                               bfr-eval-list-consts)))))






(in-theory (disable bfr-ite-bss-fn bfr-ite-bvv-fn))


