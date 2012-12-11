
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
# Header offsets.
# Try to adjust the scroll offset for pages known to have static headers.

# XPath for known headers.
#
ssHeaderXPath =
  "www.facebook.com": "//div[@id='pagelet_bluebar']/div[@id='blueBarHolder']/div['blueBar']/../.."

# Offset adjustment.
#
ssOffsetAdjustment = ->
  if xPath = ssHeaderXPath[window.location.host]
    if headers = evaluateXPath xPath
      if headers and headers.length == 1
        header = headers[0]
        if header.offsetTop == 0 and header.offsetHeight? and header.offsetHeight
          return header.offsetHeight
  return 0

# ####################################################################
# Scrolling.

# Smooth scrolling.
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#
ssTimer  = null
ssStart  = null
ssFactor = null
ssOffset = 10 # This many pixels from top of window.

ssGetOffsetTop = (element) ->
  e = element
  (e.offsetTop while e = e.offsetParent).reduce ( (p,c) -> p + c ), element.offsetTop

smoothScroll = (element) ->
  offSetTop = ssGetOffsetTop element
  target    = Math.max 0, offSetTop - ( ssOffset + ssOffsetAdjustment() )
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
# The Facebook id attribute for a post is dynamic.  So here - for Facebook only - we pick out a different id,
# one that is static. fbid is static.
#
extractFBID = (element) ->
  return (element.getAttribute "fbid") || element.id

# Extract an ID for `element`.
#
extractID = (element) ->
  switch window.location.host
    when "www.facebook.com" then extractFBID element
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

# focusAll = (element) ->
#   if element
#     focusAll element.parentNode
#     element.focus() if element?.focus

highlight = (element) ->
  if element isnt null
    if currentElement isnt null
      currentElement.classList.remove highlightCSS
    #
    currentElement = element
    currentElement.classList.add highlightCSS
    # focusAll currentElement
    #
    smoothScroll currentElement
    notifyID     currentElement
    #
    document.activeElement.blur()
    #
    true # Do not propagate.
  else
    false # Propagate.

# Navigate.
#
navigate = (xPath, mover) ->
  #
  elements = evaluateXPath xPath
  n = elements.length
  #
  if 0 < n
    index = [0...n].filter (i) -> elements[i].classList.contains highlightCSS
    if index.length == 0
      highlight elements[0]
    else
      highlight elements[mover index[0], n]
  else
    false # Propagate.

# ####################################################################
# Key handling routines.

extractKey = (event) ->
  event.which.toString()

killKeyEvent = (event, killEvent=false) ->
  if killEvent
    event.stopPropagation()
    event.preventDefault()
    false # Do not propagate.
  else
    true # Propagate.

killKeyEventHandler = (event) ->
  switch extractKey event
    # Lower, upper case.
    when "106", "74" then killKeyEvent event, true # j, J
    when "107", "75" then killKeyEvent event, true # k, K
    when "122", "90" then killKeyEvent event, true # z, Z
    # And <enter>.
    when "13"        then killKeyEvent event, true # <enter>
    #
    else killKeyEvent event, false

# ####################################################################
# Handle <enter>.
# Incomplete.

# Score an HRef.  Higher is better.
scoreHRef = (href) ->
  score = 0
  # URLs containing redirects get a high score.
  score += 5 if 0 < href.indexOf "%3A%2F%2"
  # Facebook photos.
  score += 2 if 0 < href.indexOf "/photo.php?fbid="
  # Prefer external links.
  score += 3 unless 0 < href.indexOf window.location.host
  #
  score

# Sort into reverse order, so we can pick the best one off the front of the list.
compareHRef = (a,b) -> scoreHRef(b) - scoreHRef(a)

# Follow link.
#
followLink = (xPath) ->
  element = if window.location.host is "plus.google.com" then document.activeElement else currentElement
  #
  anchors = element.getElementsByTagName "a"
  anchors = Array.prototype.slice.call anchors, 0
  anchors = anchors.map (a) -> a.href
  anchors = anchors.sort compareHRef
  if 0 < anchors.length
    request =
      request: "open"
      url:      anchors[0]
    chrome.extension.sendMessage request
    true
  else
    false

# ####################################################################
# Handle j, k, z (and forward <enter>).
# Incomplete.

#          j   k   z   J    K    Z
jkKeys = [ 74, 75, 90, 106, 107, 122 ].map (k) -> k.toString()

# KeyPress handler.
#
onKeypress = (eventName, xPath) -> (event) ->
  unless document.activeElement.nodeName.trim() in [ "BODY", "DIV" ]
    return true # Propagate.
  #
  # Just let Google Plus do its own j/k thing.
  key = extractKey event
  if window.location.host is "plus.google.com" and key in jkKeys
    return true # Propagate.
  #
  switch key
    # Lower, upper case.
    when "106", "74" then return killKeyEvent event, navigate xPath, (i,n) -> Math.min i+1, n-1 # j, J
    when "107", "75" then return killKeyEvent event, navigate xPath, (i,n) -> Math.max i-1, 0   # k, K
    when "122", "90" then return killKeyEvent event, navigate xPath, (i,n) -> 0                 # z, Z
    # And <enter>.
    when "13"        then return killKeyEvent event, followLink xPath                           # <enter>
  return true # Propagate.

# ####################################################################
# Start up.
# Try to return to last known position (based on element IDs).
# Otherwise, navigate to first element.

startUpAtLastKnownPosition = (xPath) ->
  # Disable on Google Plus.
  #
  if window.location.host is "plus.google.com"
    return true # Propagate.
  #
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
  request: "lookup"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  if xPath = response?.xPath
    console.log "justJK activated #{window.location.host} #{window.location.pathname}"
    document.addEventListener "keypress", onKeypress("keypress", xPath), true
    document.addEventListener "keydown", onKeypress("keydown", xPath), true
    document.addEventListener "keyup", killKeyEventHandler, true
    startUpAtLastKnownPosition xPath
  else
    console.log "justJK inactive #{window.location.host} #{window.location.pathname}"

# ####################################################################
# Temporary tests.

work = ->
  styles = evaluateXPath "//*[@style]"
  for s in styles
    s.style.parentNode = s
  styles = styles.map (s) -> s.style
  styles = styles.filter (s) -> s.position? and s.position and s.position in [ "relative" ] # in [ "relative", "absolute" ]
  console.log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  for s in styles
    console.log "#{s.position} top=#{s.top} height=#{s.height} #{s.parentNode.offsetTop} #{s.parentNode.height}"
    console.log s.parentNode

setTimeout work, 2000
