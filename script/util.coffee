
justJK = window.justJK ?= {}
_      = window._

# ####################################################################
# Additional underscore bindings.
# From: "https://gist.github.com/2624704".
#
do ->
  mixin = {}
  #
  for name in [ "bind", "throttle" ]
    do (name) -> mixin["#{name}R"] = (args..., f) -> _(f)[name](args...)
  #
  _.mixin mixin

# ####################################################################
# Constants.
#
Const = justJK.Const =
  jjkAttribute:   "__justJKExtra__smblott_"
  highlightCSS:   "justjk_highlighted"
  currentClass:   "justjk_current"
  simpleBindings: "/justJKSimpleBindingsForJK" # Hack!
  nativeBindings: "/justJKNativeBindingsForJK" # Hack!
  verboten:       [ "INPUT", "TEXTAREA" ]
  last:           "last"

# ####################################################################
# Utilities.
#
Util = justJK.Util =
  echo:              (args...)          -> console.log arg for arg in args
  #
  # SetInterval and setTimeout, here, expect the function as their *second* argument.
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
  result: (result,func) -> func(); result

  # Keypress wrapper.
  #
  keypress: (keys, func) ->
    keypress.register_combo
      keys            : keys
      on_keydown      : func
      prevent_default : false
      is_exclusive    : true

  # Extract URLs from an anchor, yielding list.  In particular, try extracting URLs from the anchor's
  # search term.
  #
  # Warning: proxied in hacks.coffee.
  #
  extractURLs: do ->               # "%3A%2F%2F" is "://"
    regexp = new RegExp "=(https?(://|%3A%2F%2F)[^&]*)", "g"
    #
    (anchor) ->
      Util.push [ anchor.href ], (decodeURIComponent(matches[1]) while matches = regexp.exec anchor.search)...

  # Synchronous wget.
  #
  wget: (url) ->
    request = new XMLHttpRequest()
    request.open 'GET', url, false
    request.send()
    if request.status is 200 then request.responseText else ""

  # Throttle a function: call it only after 300ms have elapsed, and delay a further 300ms each time throttle
  # is called.  Limitation: assumes 'func' is the same function each time.
  #
  throttle: do ->
    timer = null
    delay = 300
    #
    (func) ->
      ->
        clearTimeout timer if timer
        timer = Util.setTimeout delay, -> timer = null; func()

