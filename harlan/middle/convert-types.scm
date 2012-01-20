(library
  (harlan middle convert-types)
  (export convert-types convert-type)
  (import (rnrs) (elegant-weapons helpers))
  
;; This pass converts Harlan types into C types.
(define-match convert-types
  ((,[convert-decl -> decl*] ...) decl*))

(define-match convert-decl
  ((include ,h) `(include ,h))
  ((gpu-module ,[convert-kernel -> kernel*] ...)
   `(gpu-module . ,kernel*))
  ((func ,[convert-type -> rtype] ,name
     ((,x* ,[convert-type -> t*]) ...)
     ,[convert-stmt -> stmt])
   `(func ,rtype ,name ,(map list x* t*) ,stmt))
  ((extern ,[convert-type -> t] ,name (,[convert-type -> t*] ...))
   `(extern ,t ,name ,t*)))

(define-match convert-kernel
  ((kernel ,k ((,x* ,[convert-type -> t*]) ...)
     ,[convert-stmt -> stmt*] ...)
   `(kernel ,k ,(map list x* t*) . ,stmt*)))

(define-match convert-stmt
  ((begin ,[stmt*] ...)
   `(begin . ,stmt*))
  ((let ,x ,[convert-type -> type] ,[convert-expr -> e])
   `(let ,x ,type ,e))
  ((if ,test ,[conseq])
   `(if ,test ,conseq))
  ((if ,test ,[conseq] ,[alt])
   `(if ,test ,conseq ,alt))
  ((let-gpu ,x ,[convert-type -> type])
   (guard (ident? x))
   `(let-gpu ,x ,type))
  ((map-gpu ((,x* ,[convert-expr -> e*]) ...) ,[stmt*] ...)
   `(map-gpu ,(map list x* e*) . ,stmt*))
  ((set! ,[convert-expr -> loc] ,[convert-expr -> val])
   `(set! ,loc ,val))
  ((print ,[convert-expr -> e]) `(print ,e))
  ((while ,[convert-expr -> e] ,[stmt])
   `(while ,e ,stmt))
  ((for (,x ,[convert-expr -> begin] ,[convert-expr -> end])
     ,[convert-stmt -> stmt*] ...)
   `(for (,x ,begin ,end) . ,stmt*))
  ((kernel
     (((,x* ,[convert-type -> t*])
       (,xs* ,[convert-type -> ts*])) ...)
     (free-vars (,fx* ,[convert-type -> ft*]) ...)
     ,[body])
   `(kernel ,(map (lambda (x t xs ts)
                    `((,x ,t) (,xs ,ts)))
               x* t* xs* ts*)
      (free-vars . ,(map list fx* ft*))
      ,body))
  ((apply-kernel ,k ,[convert-expr -> e*] ...)
   (guard (ident? k))
   `(apply-kernel ,k . ,e*))
  ((do ,[convert-expr -> e])
   `(do ,e))
  ((return) `(return))
  ((return ,[convert-expr -> expr])
   `(return ,expr)))

(define-match convert-expr
  ((int ,n) `(int ,n))
  ((u64 ,n) `(u64 ,n))
  ((str ,s) `(str ,s))
  ((var ,x) `(var ,x))
  ((float ,f) `(float ,f))
  ((c-expr ,[convert-type -> t] ,x) `(c-expr ,t ,x))
  ((field ,obj ,arg* ...) `(field ,obj . ,arg*))
  ((,op ,[lhs] ,[rhs])
   (guard (or (binop? op) (relop? op)))
   `(,op ,lhs ,rhs))
  ((if ,[test] ,[conseq] ,[alt])
   `(if ,test ,conseq ,alt))
  ((sizeof (vec ,[convert-type -> t] ,n)) `(* (int ,n) (sizeof ,t)))
  ((sizeof ,[convert-type -> t]) `(sizeof ,t))
  ((vector-ref ,[v] ,[i]) `(vector-ref ,v ,i))
  ((cast ,[convert-type -> t] ,[e]) `(cast ,t ,e))
  ((deref ,[e]) `(deref ,e))
  ((addressof ,[e]) `(addressof ,e))
  ((assert ,[expr]) `(assert ,expr))
  ((call ,[e] ,[arg*] ...) `(call ,e . ,arg*)))

(define-match convert-type
  (int 'int)
  (bool 'bool)
  (u64 'uint64_t)
  (float 'float)
  (void 'void)
  (str '(const-ptr char))
  (cl::kernel 'cl::kernel)
  ((cl::buffer ,[t]) `(cl::buffer ,t))
  ((cl::buffer_map ,[t]) `(cl::buffer_map ,t))
  ((ptr ,scalar)
   (guard (scalar-type? scalar))
   `(ptr ,scalar))
  ((ptr (vec ,[find-leaf-type -> t] ,size)) `(ptr ,t))
  ((vec ,[find-leaf-type -> t] ,size)
   `(ptr ,t))
  (((,[t*] ...) -> ,[t])
   `(,t* -> ,t)))

(define-match find-leaf-type
  ((vec ,[t] ,size) t)
  (,t (guard (scalar-type? t))
    (convert-type t)))

;; end library
)
