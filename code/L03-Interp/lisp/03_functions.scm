(define (apply-twice f x)
  (f (f x)))

(define (square x)
  (* x x))

(display (apply-twice square 2))
(newline)
