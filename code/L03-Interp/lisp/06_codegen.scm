(define (make-sum a b)
  (list '+ a b))

(define expr (make-sum 10 20))

(display expr)
(newline)

(display (eval expr (interaction-environment)))
(newline)
