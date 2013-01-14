
justJK = window.justJK ?= {}
#
_      = window._

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

# ####################################################################
# Constants.
#
Const = justJK.Const =
  jjkAttribute:   "__justJKExtra__smblott_"
  highlightCSS:   "justjk_highlighted"
  simpleBindings: "/justJKSimpleBindingsForJK" # FIXME
  nativeBindings: "/justJKNativeBindingsForJK" # FIXME
  verboten:       [ "INPUT", "TEXTAREA" ]

# ####################################################################
# Utilities.
#
Util = justJK.Util =
  echo:              (args...)          -> console.log arg for arg in args
  #
  # It's sometimes more convenient to have setInterval and setTimeout expect the function as their *second*
  # argument.
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

  # Keypress wrapper.
  #
  keypress: (keys, func) ->
    keypress.register_combo
      keys            : keys
      on_keydown      : func
      prevent_default : false
      is_exclusive    : true

  # Extract URLs from an anchor, yielding list.  In particular, we try extracting URLs from the anchor's
  # search term.
  #
  extractURLs: do ->
    regexp = new RegExp "=(https?(://|%3A%2F%2F)[^&]*)" # "%3A%2F%2F" is "://"
    #
    (anchor) ->
      # # Youtube hack.
      # if anchor.host is "www.youtube.com" and anchor.pathname is "/watch"
      #   anchor.pathname = "/watch_popup"
      #
      search = anchor.search.match(regexp)
      #
      urls = 
        if search?.length
          Util.push (decodeURIComponent href for href, i in search when i % 2), anchor.href
        else
          [ anchor.href ]
      urls.map (url) -> url.replace "://www.youtube.com/watch?", "://www.youtube.com/watch_popup?"

  # Synchronous wget.
  #
  wget: (url) ->
    request = new XMLHttpRequest()
    request.open 'GET', url, false
    request.send()
    if request.status is 200 then request.responseText else ""

  throttle: do ->
    timer = null
    delay = 300
    #
    (func) ->
      ->
        if timer
          clearTimeout timer
        #
        timer = Util.setTimeout delay, ->
          timer = null
          func()


