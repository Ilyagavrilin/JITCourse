(define (make-adder x)
  (lambda (y) (+ x y)))

(define add5 (make-adder 5))

(display (add5 10))
(newline)
