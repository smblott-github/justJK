
justJK = window.justJK ?= {}
#
_      = window._

Const = justJK.Const =
  jjkAttribute:   "__justJKExtra__smblott_"
  highlightCSS:   "justjk_highlighted"
  simpleBindings: "/justJKSimpleBindingsForJK"
  nativeBindings: "/justJKNativeBindingsForJK"
  verboten:       [ "INPUT", "TEXTAREA" ]

Util = justJK.Util =
  echo:              (args...)          -> console.log arg for arg in args
  #
  # It's more convenient to have setInterval and setTimeout accept the function as their *second* argument.
  #
  setInterval:       (ms, func)         -> window.setInterval func, ms
  setTimeout:        (ms, func)         -> window.setTimeout  func, ms
  #
  stringContains:    (haystack, needle) -> haystack.indexOf(needle) != -1
  stringStartsWith:  (haystack, needle) -> haystack.indexOf(needle) ==  0
  #
  sum:               (args...)          -> args.reduce ( (p,c) -> p + c ), 0
  #
  push:              (list,args...)     -> @result list, -> list.push args...
  show:              (obj)              -> @result obj,  => @echo obj

  # Call function then return result.
  #
  result: (result,func) ->
    func()
    return result

  # Extract HREFs from an anchor, yielding list.
  #
  extractHRefs: do ->
    regexp = new RegExp "=(https?(://|%3A%2F%2F)[^&=]*)" # "%3A%2F%2F" is "://"
    #
    (anchor) ->
      Util.push ( decodeURIComponent href for href, i in anchor.search.match(regexp) or [] when i % 2 ), anchor.href

# ####################################################################
# Additional underscore bindings.
# From: "https://gist.github.com/2624704".
#

do ->
  mixin = {}
  #
  for name in [ "bind", "throttle" ]
    do (name) ->
      mixin["#{name}R"] = (args..., f) -> _(f)[name](args...)
  #
  _.mixin mixin

