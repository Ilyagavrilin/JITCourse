(define expr '(+ 1 2 3))

(display expr)
(newline)

(display (eval expr (interaction-environment)))
(newline)
