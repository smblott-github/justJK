
# ####################################################################
# XPath.

resultType        = XPathResult.ANY_TYPE
namespaceResolver = (namespace) -> if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

# Return a list of elements matching `xPath`.
#
evaluateXPath = (xPath) ->
  try
    xPathResult = document.evaluate xPath, document, namespaceResolver, resultType
    #
  catch error
    console.log "justJK xPath error: #{xPath}"
    return []
  #
  return ( element while xPathResult and element = xPathResult.iterateNext() )

# ####################################################################
# Scrolling.

# Smooth scrolling.
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#
ssTimer  = null
ssStart  = null
ssFactor = null
ssOffset = 50 # This many pixels from top of window.

ssGetOffsetTop = (element) ->
  e = element
  (e.offsetTop while e = e.offsetParent).reduce ( (p,c) -> p + c ), element.offsetTop

smoothScroll = (element) ->
  offSetTop = ssGetOffsetTop element
  target    = Math.max 0, offSetTop - ssOffset
  offset    = window.pageYOffset
  delta     = target - offset
  duration  = 300
  #
  ssStart   = Date.now()
  ssFactor  = 0

  clearInterval ssTimer if ssTimer

  ssTimer = setInterval ->
      ssFactor = (Date.now() - ssStart) / duration
      if 1 <= ssFactor
        clearInterval ssTimer
        ssTimer = null
        ssFactor = 1
      y = ssFactor * delta + offset
      window.scrollBy 0, y - window.pageYOffset
    # Interval.
    10

# ####################################################################
# Element identifiers.

# Hack for Facebook.
#
# The Facebook id attribute for a post  changes each time the page is reloaded.  So here - for Facebook only -
# we pick out a different id, one that is static.
#
# Attribute data-ft is JSON;  therein, mf_story_key is static.
#
extractIDFacebook = (element) ->
  try
    if dataFT = JSON.parse element.getAttribute "data-ft"
      if dataFT.mf_story_key
        return dataFT.mf_story_key
  return element.id

# Extract an ID for `element`.
#
extractID = (element) ->
  switch window.location.host
    when "www.facebook.com" then extractIDFacebook element
    else element.id

# Notify the background script of the current ID for this page.
#
notifyID = (element) ->
  id = extractID element
  if id isnt null and 0 < id.length
    chrome.extension.sendMessage
      request: "saveID"
      id:       id
      host:     window.location.host
      pathname: window.location.pathname
      # No callback.

# ####################################################################
# Highlighting.

# Highlight an element and scroll it into view.
#
currentElement = null
highlightCSS   = "justjk_highlighted"

highlight = (element) ->
  if element isnt null
    if currentElement isnt null
      currentElement.classList.remove highlightCSS
    #
    currentElement = element
    currentElement.classList.add highlightCSS
    #
    smoothScroll currentElement
    notifyID     currentElement

# Navigate.
#
navigate = (xPath, mover) ->
  #
  elements = evaluateXPath xPath
  n = elements.length
  #
  if 0 < n
    index = [0...n].filter (i) -> currentElement != null and elements[i] is currentElement
    if index.length == 0
      highlight elements[0]
    else
      highlight elements[mover index[0], n]

# ####################################################################
# Key handling routines.

extractKey = (event) ->
  event.which.toString()

killKeyEvent = (event, ignored) ->
  event.stopPropagation()
  event.preventDefault()
  false # Do not propagate.

killKeyEventHandler = (event) ->
  switch extractKey event
    # Lower case.
    when "106" then return killKeyEvent event # j
    when "107" then return killKeyEvent event # k
    when "122" then return killKeyEvent event # z
    # Upper case.
    when "74"  then return killKeyEvent event # J
    when "75"  then return killKeyEvent event # K
    when "90"  then return killKeyEvent event # Z
    # And <enter>.
    when "13"  then return killKeyEvent event # <enter>
  return true # Propagate.

# ####################################################################
# Handle <enter>.
# Incomplete.

scoreHRef = (href) ->
  score = 0
  # URLs containing redirects get a high score.
  score += 5 if 0 < href.indexOf "%3A%2F%2"
  # Facebook photos.
  score += 3 if 0 < href.indexOf "/photo.php?fbid="
  #
  return score

# Sorts into reverse order, so we can just pick the best one of the front of the list.
compareHRef = (a,b) -> scoreHRef(b) - scoreHRef(a)

# Follow link or focus first element.
#
followLink = (xPath) ->
  #
  if currentElement is null
    return navigate xPath, (i,n) -> 0
  anchors = currentElement.getElementsByTagName "a"
  anchors = Array.prototype.slice.call anchors, 0
  anchors = anchors.map (a) -> a.toString()
  anchors = anchors.sort compareHRef
  if 0 < anchors.length
    request =
      request: "open"
      url:      anchors[0]
    chrome.extension.sendMessage request

# ####################################################################
# Handle j, k, z (and forward <enter>).
# Incomplete.

# KeyPress handler.
#
onKeypress = (eventName, xPath) -> (event) ->
  if document.activeElement.nodeName.trim() isnt "BODY"
    return true # Propagate.
  #
  switch extractKey event
    # Lower case.
    when "106" then return killKeyEvent event, navigate xPath, (i,n) -> Math.min i+1, n-1 # j
    when "107" then return killKeyEvent event, navigate xPath, (i,n) -> Math.max i-1, 0   # k
    when "122" then return killKeyEvent event, navigate xPath, (i,n) -> 0                 # z
    # Upper case.
    when "74"  then return killKeyEvent event, navigate xPath, (i,n) -> Math.min i+1, n-1 # J
    when "75"  then return killKeyEvent event, navigate xPath, (i,n) -> Math.max i-1, 0   # K
    when "90"  then return killKeyEvent event, navigate xPath, (i,n) -> 0                 # Z
    # And <enter>.
    when "13"  then return killKeyEvent event, followLink xPath                           # <enter>
  return true # Propagate.

# ####################################################################
# Start up.
# Try to return to last known position (based on element IDs).
# Otherwise, navigate to first element.

startUpAtLastKnownPosition = (xPath) ->
  request =
    request: "lastID"
    host:     window.location.host
    pathname: window.location.pathname
  chrome.extension.sendMessage request, (response) ->
    if response?.id
      for element in evaluateXPath xPath
        if element.id and response.id is extractID element
          return highlight element
    # Not found.
    # Go to first element.
    #
    navigate xPath, (i,n) -> 0

# ####################################################################
# Main: install listener and highlight previous element (or first).

request =
  request: "start"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  if xPath = response?.xPath
    document.addEventListener "keypress", onKeypress("keypress", xPath), true
    document.addEventListener "keydown", onKeypress("keydown", xPath), true
    document.addEventListener "keyup", killKeyEventHandler, true
    startUpAtLastKnownPosition xPath

