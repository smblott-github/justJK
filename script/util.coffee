
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
  sum:               (a, b)             -> a + b

  flatten: (obj,func) ->
    val while obj and [ val, obj ] = func obj

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

