
# ####################################################################
# Utilities and constants.

echo              = (args...)          -> console.log arg for arg in args
stringContains    = (haystack, needle) -> haystack.indexOf(needle) != -1
stringStartsWith  = (haystack, needle) -> haystack.indexOf(needle) ==  0
extractKey        = (event)            -> event.which.toString()
namespaceResolver = (namespace)        -> if namespace == "xhtml" then "http://www.w3.org/1999/xhtml" else null

vanillaScrollStep =  70
xPathResultType   =  XPathResult.ANY_TYPE
highlightCSS      = "justjk_highlighted"
simpleBindings    = "/justJKSimpleBindingsForJK"
nativeBindings    = "/justJKNativeBindingsForJK"
verboten          = [ "INPUT", "TEXTAREA" ]
currentElement    = null
config            = {}

# ####################################################################
# Get elements by class name.
#
getElementsByClassName = (name) ->
  e for e in document.getElementsByTagName '*' when e.className is name

# ####################################################################
# Filter element list by visibility.
#
filterVisibleElements = (elements) ->
  e for e in elements when e?.style?.display isnt "none"

# ####################################################################
# Get active element.
# Return the active element, with special-case handling for Facebook.
#
getActiveElement = ->
  element = document.activeElement
  #
  switch window.location.host
    when "www.facebook.com"
      # With Facebook's native bindings, the active element is some "H5" object deep within the actual post.
      # To find a link worth following, we must first got up the document tree a bit.
      #
      while element and element.nodeName isnt "LI"
        element = element.parentNode
      #
      return element || document.activeElement
  #
  element

# ####################################################################
# XPath.
#
# Return a list of document elements matching `xPath`.
#
evaluateXPath = (xPath) ->
  try
    xPathResult = document.evaluate xPath, document, namespaceResolver, xPathResultType
    #
  catch error
    console.log "justJK xPath error: #{xPath}"
    return []
  #
  element while xPathResult and element = xPathResult.iterateNext()

byElementPosition = (a,b) ->
  ssGetOffsetTop(a) - ssGetOffsetTop(b)

# A wrapper around evaluateXPath which discards vertically small elements.
# TODO: We should probably be discarding non-visible elements here.
#
getElementList = (xPath) ->
  (e for e in evaluateXPath xPath when 5 < e.offsetHeight).sort byElementPosition

# ####################################################################
# Header offsets adjustment.
#
# Try to adjust the scroll offset for pages known to have static headers.  Content should not scroll up
# underneath such headers.
# 
# Basically, config.header is  an XPath specification.  The bottom of the indicated element (which must be
# unique) is taken to be the top of the normal page area.
#
ssOffsetAdjustment = ->
  if xPath = config.header
    if banners = evaluateXPath xPath
      if banners and banners.length == 1 and banner = banners[0]
        if banner.offsetTop == 0 and banner.offsetHeight
          return banner.offsetHeight
  return 0

# ####################################################################
# Smooth scrolling.
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#
ssTimer  = null
ssStart  = null
ssFactor = null

# Scroll to this many pixels from the top of the window.
#
ssOffset = 20

ssGetOffsetTop = (element) ->
  e = element
  (e.offsetTop while e = e.offsetParent).reduce ( (p,c) -> p + c ), element.offsetTop

# Smooth scrolling by pixels.
#
smoothScrollByDelta = (delta) ->
  duration  = 400
  offset    = window.pageYOffset
  #
  ssStart   = Date.now()
  ssFactor  = 0
  #
  intervalFunc = ->
    ssFactor = Math.sqrt Math.sqrt (Date.now() - ssStart) / duration
    #
    if 1 <= ssFactor
      clearInterval ssTimer
      ssTimer = null
      ssFactor = 1
    #
    y = ssFactor * delta + offset
    window.scrollBy 0, y - window.pageYOffset
  #
  clearInterval ssTimer if ssTimer
  ssTimer = setInterval intervalFunc, 10

# Smooth scrolling to element.
#
smoothScrollToElement = (element) ->
  offSetTop = ssGetOffsetTop element
  target    = Math.max 0, offSetTop - ( ssOffset + ssOffsetAdjustment() )
  offset    = window.pageYOffset
  delta     = target - offset
  #
  smoothScrollByDelta delta
  #
  element

# ####################################################################
# Vanilla scroller.
#
vanillaScroll = (move) ->
  position = window.pageYOffset / vanillaScrollStep
  newPosition = if move then position + move else 0
  smoothScrollByDelta (newPosition - position) * vanillaScrollStep
  return true # Do not propagate.

# ####################################################################
# Highlight an element and scroll it into view.
#
highlight = (element) ->
  if element and element isnt currentElement
    #
    if currentElement
      currentElement.classList.remove highlightCSS
    #
    currentElement = element
    currentElement.classList.add highlightCSS
    #
    smoothScrollToElement currentElement
    #
    chrome.extension.sendMessage
      request: "saveID"
      id:       currentElement.id
      host:     window.location.host
      pathname: window.location.pathname
      # No callback.

# ####################################################################
# Logical navigation.
#
navigate = (xPath, move) ->
  elements = getElementList xPath
  n = elements.length
  #
  echo 1
  if 0 < n
    index = (i for e, i in elements when e.classList.contains highlightCSS)
    if index.length == 0
      return highlight elements[0]
    echo 2
    #
    index = index[0]
    newIndex = Math.min n-1, Math.max 0, if move then index + move else 0
    echo 3
    if newIndex isnt index
      echo 4
      return highlight elements[newIndex]
    # Drop through.
  #
  vanillaScroll move

# ####################################################################
# Key handling routines.

doUnlessInputActive = (func) ->
  if document.activeElement.nodeName not in verboten
    if not (filterVisibleElements getElementsByClassName "vimiumReset vimiumHUD").length
      func()

# ####################################################################
# Scoring HREFs.
# Scoring is ad hoc, based on heuristics which seem mostly to work.
# HREFs with higher scores are prefered.
#
scoreHRef = (href) ->
  score = 0
  #
  # Prefer URLs containing redirects; they are often the primary link.
  score += 4 if stringContains href, "%3A%2F%2" # == "://" URI encoded
  #
  # Prefer external links.
  score += 3 unless stringContains href, window.location.host
  #
  # Slightly prefer non-static looking links.
  score += 1 if stringContains href, "?"
  #
  if config.like
    for like in config.like
      score += 2 if stringContains href, like
  #
  if config.dislike
    for dislike in config.dislike
      score -= 2 if stringContains href, dislike
  #
  score

# Scoring-based Comparison (for sorting).
#
compareHRef = (a,b) -> scoreHRef(a) - scoreHRef(b)

# ####################################################################
# Handle <enter>.
#
followLink = (xPath) ->
  #
  element = if xPath is nativeBindings then getActiveElement() else currentElement
  #
  if element
    anchors = element.getElementsByTagName "a"
    anchors = Array.prototype.slice.call anchors, 0
    anchors = ( a.href for a in anchors when a.href and not stringStartsWith a.href, "javascript:" )
    # Reverse the list here so that, when there are multiple top-scoring HREFs, the originally first-listed of
    # those will end up at the end.
    anchors = anchors.reverse().sort compareHRef
    #
    console.log scoreHRef(a), a for a in anchors
    #
    if 0 < anchors.length
      chrome.extension.sendMessage
        request: "open"
        url:      anchors.pop()
        # No callback
    else
      if typeof element.click is "function"
        element.click.apply element

# ####################################################################
# Main: install listener and highlight previous element (or first).

request =
  request: "config"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  config = response || {}
  xPath = config.xPath || simpleBindings
  console.log "justJK xPath", xPath
  #
  switch xPath
    when simpleBindings
      keypress.combo "j",     -> doUnlessInputActive -> vanillaScroll  1
      keypress.combo "k",     -> doUnlessInputActive -> vanillaScroll -1
      keypress.combo ";",     -> doUnlessInputActive -> vanillaScroll  0
    #
    when nativeBindings
      keypress.combo "enter", -> doUnlessInputActive -> followLink xPath
    #
    else
      keypress.combo "j",     -> doUnlessInputActive -> navigate   xPath,  1
      keypress.combo "k",     -> doUnlessInputActive -> navigate   xPath, -1
      keypress.combo ";",     -> doUnlessInputActive -> navigate   xPath,  0
      keypress.combo "enter", -> doUnlessInputActive -> followLink xPath
      #
      request =
        request: "lastID"
        host:     window.location.host
        pathname: window.location.pathname
      #
      chrome.extension.sendMessage request, (response) ->
        if not currentElement
          if response?.id
            for element in getElementList xPath
              if element.id and response.id is element.id
                return highlight element
          #
          # Go to first element.
          #
          navigate xPath, 0

