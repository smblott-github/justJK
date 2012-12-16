
justJK = window.justJK ?= {}

Const = justJK.Const =
  jjkAttribute:   "__justJKExtra__smblott_"
  highlightCSS:   "justjk_highlighted"
  simpleBindings: "/justJKSimpleBindingsForJK"
  nativeBindings: "/justJKNativeBindingsForJK"
  verboten:       [ "INPUT", "TEXTAREA" ]

Util = justJK.Util =
  echo:              (args...)          -> console.log arg for arg in args
  stringContains:    (haystack, needle) -> haystack.indexOf(needle) != -1
  stringStartsWith:  (haystack, needle) -> haystack.indexOf(needle) ==  0
  setInterval:       (ms, func)         -> window.setInterval func, ms
  sum:               (args...)          -> args.reduce ( (p,c) -> p + c ), 0
  max:               (args...)          -> Math.max.apply Math, args

  show: (thing) ->
    Util.echo thing
    thing

  flatten: (obj,func) ->
    val while obj and [ val, obj ] = func obj

  # From: "http://rosettacode.org/wiki/Flatten_a_list#CoffeeScript"
  #
  flattenList: (arr) ->
    arr.reduce ((xs, el) -> if Array.isArray el then xs.concat Util.flattenList el else xs.concat [el]), []

  # Sometimes, a function call is triggered unnecessarily multiple times in quick succession.  "onlyOnce",
  # here, arranges to call a function 100ms after it was last asked to do so.  However, it quietly swallows
  # successive calls which arrive too rapidly.  Typical use is as an "onscroll" handler, in which we really
  # only care about the final position.
  #
  onlyOnceTimer: null
  #
  onlyOnceFunc: (func) ->
    ->
      Util.onlyOnceTimer = null
      func()
  #
  onlyOnce: (func) ->
    clearInterval @onlyOnceTimer if @onlyOnceTimer
    @onlyOnceTimer = setTimeout @onlyOnceFunc(func), 100

  # Extract HREFs from an anchor.
  #
  extractHRefRegExp: new RegExp "^https?%3A%2F%2F" # "%3A%2F%2F" is "://"

  extractHRefs: (anchor) ->
    anchors = [ anchor.href ]
    #
    if anchor.search
      for arg in anchor.search.split "&"
        [ key, value ] = arg.split "="
        if @extractHRefRegExp.test value
          anchors.push decodeURIComponent value
    #
    anchors

  topRanked: (list, scorer) ->
    tops = []
    if list.length
      [ first, rest... ] = list
      max = scorer first
      tops.push first
      for obj in rest
        score = scorer obj
        if max < score
          tops = [ obj ]
          max = score
        else
          if max == score
            tops.push obj
    #
    tops
