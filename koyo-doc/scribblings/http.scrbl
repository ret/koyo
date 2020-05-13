#lang scribble/doc

@(require (for-label koyo
                     net/url
                     racket/base
                     racket/contract
                     web-server/http)
          scribble/example
          "koyo.rkt")

@title[#:tag "http"]{HTTP}

@defmodule[koyo/http]

This module provides utilities for working with HTTP-related data
structures.

@defproc[(request-path [req request?]) string?]{
  Returns the absolute request path for @racket[req], scrubbed of path params.
}

@deftogether[
  (@defproc[(bindings-ref [bindings (listof binding?)]
                          [name symbol?]
                          [default (or/c false/c string?) #f]) (or/c false/c string?)]
   @defproc[(bindings-ref-bytes [bindings (listof binding?)]
                                [name symbol?]
                                [default (or/c false/c bytes?) #f]) (or/c false/c bytes?)]
   @defproc[(bindings-ref-number [bindings (listof binding?)]
                                 [name symbol?]
                                 [default (or/c false/c number?) #f]) (or/c false/c number?)]
   @defproc[(bindings-ref-symbol [bindings (listof binding?)]
                                 [name symbol?]
                                 [default (or/c false/c symbol?) #f]) (or/c false/c symbol?)])]{

  Finds the first binding in @racket[bindings] whose name is
  @racket[name] and returns its value or @racket[default].
}

@defproc[(url-scrub [u url?]) url?]{
  Removes all the path params from @racket[u], while leaving its path
  intact.  This is used by the default continuation mismatch handler
  to strip the current URL of its continuation id.

  @examples[
  #:label #f
    (require koyo/http
             net/url)

    (url->string
     (url-scrub
      (string->url "https://127.0.0.1/foo/bar;(\"k\" . \"123\")/baz")))
  ]
}
