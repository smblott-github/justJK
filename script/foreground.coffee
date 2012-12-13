
window.justJK ?= {}
justJK = window.justJK

Util = justJK.Util
Dom  = justJK.Dom

echo = Util.echo

# ####################################################################
# Utilities and constants.

vanillaScrollStep =  70
highlightCSS      = "justjk_highlighted"
simpleBindings    = "/justJKSimpleBindingsForJK"
nativeBindings    = "/justJKNativeBindingsForJK"
verboten          = [ "INPUT", "TEXTAREA" ]
currentElement    = null
config            = {}

# ####################################################################
# Header offsets adjustment.
#
# Try to adjust the scroll offset for pages known to have static headers.  Content should not scroll up
# underneath such headers.
# 
# Basically, config.header is  an XPath specification.  The bottom of the indicated element (which must be
# unique) is taken to be the top of the normal page area.
#

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
  offSetTop = Dom.offsetTop element
  target    = Math.max 0, offSetTop - ( ssOffset + Dom.offsetAdjustment config.header )
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
  elements = Dom.getElementList xPath
  n = elements.length
  #
  if 0 < n
    index = (i for e, i in elements when e.classList.contains highlightCSS)
    if index.length == 0
      return highlight elements[0]
    #
    index = index[0]
    newIndex = Math.min n-1, Math.max 0, if move then index + move else 0
    if newIndex isnt index
      return highlight elements[newIndex]
    # Drop through.
  #
  vanillaScroll move

# ####################################################################
# Key handling routines.

doUnlessInputActive = (func) ->
  if document.activeElement.nodeName not in verboten
    if not (Dom.filterVisibleElements Dom.getElementsByClassName "vimiumReset vimiumHUD").length
      func()
      return false # Prevent propagation.
  return true # Propagate.

# ####################################################################
# Scoring HREFs.
# Scoring is ad hoc, based on heuristics which seem mostly to work.
# HREFs with higher scores are prefered.
#
scoreHRef = (href) ->
  score = 0
  #
  # Prefer URLs containing redirects; they are often the primary link.
  score += 4 if Util.stringContains href, "%3A%2F%2" # == "://" URI encoded
  #
  # Prefer external links.
  score += 3 unless Util.stringContains href, window.location.host
  #
  # Slightly prefer non-static looking links.
  score += 1 if Util.stringContains href, "?"
  #
  if config.like
    for like in config.like
      score += 2 if Util.stringContains href, like
  #
  if config.dislike
    for dislike in config.dislike
      score -= 2 if Util.stringContains href, dislike
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
  element = if xPath is nativeBindings then Dom.getActiveElement() else currentElement
  #
  if element
    anchors = element.getElementsByTagName "a"
    anchors = Array.prototype.slice.call anchors, 0
    anchors = ( a.href for a in anchors when a.href and not Util.stringStartsWith a.href, "javascript:" )
    # Reverse the list here so that, when there are multiple top-scoring HREFs, the originally first-listed of
    # those will end up at the end.
    anchors = anchors.reverse().sort compareHRef
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
  echo "justJK xPath: #{xPath}"
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
            for element in Dom.getElementList xPath
              if element.id and response.id is element.id
                return highlight element
          #
          # Go to first element.
          #
          navigate xPath, 0

