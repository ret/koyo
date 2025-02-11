#lang racket/base

(require "private/filesystem.rkt"
         "private/tool.rkt")

(provide
 start-console
 start-console-here)

(define preload-modules
  '(racket component db koyo))

(define preamble
  '(begin
     (define dev-system
       (system-replace prod-system 'server values))

     (current-system dev-system)

     (define (start) (system-start dev-system))
     (define (stop)  (system-stop  dev-system))

     (start)))

(define (start-console dynamic-module-path)
  (displayln "Compiling application...")
  (make! dynamic-module-path)
  (displayln "Starting REPL...")
  (port-count-lines! (current-input-port))
  (port-count-lines! (current-output-port))
  (current-namespace (make-base-empty-namespace))
  (try-setup-expeditor!)
  (for ([mod (in-list preload-modules)])
    (namespace-require mod))
  (namespace-require dynamic-module-path)
  (eval preamble)
  (read-eval-print-loop))

(define (start-console-here)
  (define dynamic-module-path (find-file-in-project "dynamic.rkt" (current-directory)))
  (unless dynamic-module-path
    (raise-user-error 'koyo/console/dev "could not reach dynamic.rkt from here"))
  (for ([mod (in-list preload-modules)])
    (namespace-require mod))
  (namespace-require dynamic-module-path)
  (eval preamble))

;; Sets up expeditor w/ a Racket lexer if the modules are available at
;; runtime, otherwise falls back to readline (if available).  This
;; whole dance is mean to avoid explicit dependencies on either
;; library since they're not crucial to the operation of koyo.
(define (try-setup-expeditor!)
  (let/ec esc
    (define (fail) (esc (dynamic-require 'readline #f void)))
    (define-syntax-rule (define/require mod id ...)
      (define-values (id ...)
        (dynamic-require* 'mod '(id ...) fail)))
    (define/require racket/file
      get-preference
      put-preferences)
    (define/require expeditor
      current-expeditor-lexer
      current-expeditor-reader
      expeditor-open
      expeditor-read
      expeditor-close)
    (define/require syntax-color/racket-lexer
      racket-lexer)
    (current-expeditor-lexer racket-lexer)
    (current-expeditor-reader (λ (in) (read-syntax (object-name in) in)))
    (define editor
      (expeditor-open
       (map bytes->string/utf-8
            (get-preference 'readline-input-history (λ () null)))))
    (unless editor (esc))
    (current-prompt-read (λ () (expeditor-read editor)))
    (exit-handler
     (let ([old (exit-handler)])
       (λ (v)
         (define hist (expeditor-close editor))
         (put-preferences '(readline-input-history) (list (map string->bytes/utf-8 hist)))
         (old v))))))

(define (dynamic-require* mod ids fail-proc)
  (apply values (for/list ([id (in-list ids)])
                  (dynamic-require mod id fail-proc))))

(module+ dev
  (start-console-here))
