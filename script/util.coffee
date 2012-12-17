
justJK = window.justJK ?= {}

Const = justJK.Const =
  jjkAttribute:   "__justJKExtra__smblott_"
  highlightCSS:   "justjk_highlighted"
  simpleBindings: "/justJKSimpleBindingsForJK"
  nativeBindings: "/justJKNativeBindingsForJK"
  verboten:       [ "INPUT", "TEXTAREA" ]

Util = justJK.Util =
  echo:              (args...)          -> console.log arg for arg in args
  setInterval:       (ms, func)         -> window.setInterval func, ms
  setTimeout:        (ms, func)         -> window.setTimeout  func, ms
  #
  stringContains:    (haystack, needle) -> haystack.indexOf(needle) != -1
  stringStartsWith:  (haystack, needle) -> haystack.indexOf(needle) ==  0
  #
  flatten:           (arr)              -> [].concat.apply [], arr
  #
  sum:               (args...)          -> args.reduce ( (p,c) -> p + c ), 0
  max:               (args...)          -> Math.max.apply Math, args

  show: (thing) ->
    Util.echo thing
    thing

  # From: "http://rosettacode.org/wiki/Flatten_a_list#CoffeeScript"
  #

  # Sometimes, a function call is triggered unnecessarily multiple times in quick succession.  "onlyOnce",
  # here, arranges to call a function 100ms after it was last asked to do so.  It quietly swallows successive
  # calls which arrive too rapidly.
  #
  onlyOnce: do ->
    timer = null
    #
    (func) ->
      clearInterval timer if timer
      timer = Util.setTimeout 100, ->
        timer = null
        func()

  # Extract HREFs from an anchor, yielding list.
  #
  extractHRefs: do ->
    regexp = new RegExp "=(https?%3A%2F%2F[^&=]*)" # "%3A%2F%2F" is "://"
    #
    (anchor) ->
      [ anchor.href ].concat( decodeURIComponent href for href, i in anchor.search.match(regexp) or [] when i % 2 )

  # Score each element (href) in list, returning a new list containing only those which are top ranking.
  #
  topRanked: (list, scorer) ->
    scores = list.map (href) -> [ href, scorer href ]
    max    = Math.max ( score for [ href, score ] in scores )...
    #
    href for [ href, score ] in scores when score is max

