
# ####################################################################
# XPath.

# Return a list of elements matching `xPath`.
# Adapted from Vimium.
#

resultType = XPathResult.ANY_TYPE
namespaceResolver = (namespace) ->
  if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

evaluateXPath = (xPath) ->
  try
    xPathResult = document.evaluate xPath, document, namespaceResolver, resultType
    #
  catch error
    console.log "justJK xPath error: #{xPath}"
    console.log "justJK xPath error: #{error}"
    return []
    #
  finally
    return ( element while xPathResult and element = xPathResult.iterateNext() )

# ####################################################################
# Scrolling.

# Smooth scrolling.
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#
timer  = null
start  = null
factor = null

getOffsetTop = (element) ->
  return 0 unless element != null
  return element.offsetTop + getOffsetTop element.offsetParent

smoothScroll = (element) ->
  offSetTop = getOffsetTop element
  target    = Math.max 0, offSetTop - 50
  offset    = window.pageYOffset
  delta     = target - offset
  duration  = 300
  #
  start     = Date.now()
  factor    = 0

  if timer
    clearInterval timer

  timer = setInterval ->
      factor = (Date.now() - start) / duration
      if 1 <= factor
        clearInterval timer
        timer = null
        factor = 1
      y = factor * delta + offset
      window.scrollBy 0, y - window.pageYOffset
    # Interval.
    10

# ####################################################################
# Element identifiers.

# Hack for Facebook.
#
# The Facebook id attribute changes each time the page is reloaded.  So here - for Facebook only - we pick out
# a different id, one that is static.
#
# Attribute data-ft is JSON;  therein, mf_story_key is static.
#
extractIDFacebook = (element) ->
  try
    if dataFT = JSON.parse element.getAttribute "data-ft"
      if dataFT.mf_story_key
        return dataFT.mf_story_key
  catch error
    true # no-op
  return element.id

# Extract an ID for `element`.
#
extractID = (element) ->
  switch window.location.host
    when "www.facebook.com" then extractIDFacebook element
    else element.id

# Notify the background script of the current ID.
#
notifyID = (element) ->
  id = extractID element
  if id isnt null
    chrome.extension.sendMessage
      request: "saveID"
      id:       id
      host:     window.location.host
      pathname: window.location.pathname

# ####################################################################
# Highlighting.

#
# Highlight an element and scroll it into view.
#
currentElement = null
highlightCSS   = "justjk_highlighted"

highlight = (element) ->
  if element isnt null
    if currentElement isnt null
      currentElement.classList.remove highlightCSS
    currentElement = element
    currentElement.classList.add highlightCSS
    smoothScroll currentElement
    notifyID currentElement

# Navigate.
#
navigate = (xPath, mover) ->
  elements = evaluateXPath xPath
  n = elements.length
  #
  if 0 < n
    index = [0...n].filter (i) -> currentElement != null and elements[i] is currentElement
    if index.length == 0
      highlight elements[0]
    else
      highlight elements[mover index[0], n]
  return false # Do not propagate.

# ####################################################################
# Handle <ENTER>.
# Incomplete.

# Follow link or focus first element.
#
followLink = (xPath) ->
  if currentElement is null
    return navigate xPath, (i,n) -> 0
  for element in currentElement.getElementsByTagName "a"
    href = element.getAttribute "href"
    console.log href

# KeyPress handler.
#
onKeypress = (xPath) -> (event) ->
  if document.activeElement.nodeName.trim() isnt "BODY"
    return true # Propagate.
  #
  event.stopPropagation()
  #
  key = event.which.toString()
  key = String.fromCharCode event.charCode unless key is "13"
  switch key
    when "j"  then navigate xPath, (i,n) -> Math.min i+1, n-1
    when "k"  then navigate xPath, (i,n) -> Math.max i-1, 0
    when "z"  then navigate xPath, (i,n) -> 0
    when "13" then followLink xPath
    else true # Propagate.
  return true

# ####################################################################
# Start up.
# Try to return to last known position (based on element IDs).
# Otherwise, navigate to first element.

lastKnownPosition = (xPath) ->
  request =
    request: "lastID"
    host:     window.location.host
    pathname: window.location.pathname
  chrome.extension.sendMessage request, (response) ->
    if response and response.id
      for element in evaluateXPath xPath
        if element.id and response.id is extractID element
          highlight element
          return
    navigate xPath, (i,n) -> 0

# ####################################################################
# Main: install listener and highlight previous element (or first).

request =
  request: "start"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  xPath = response?.xPath
  if xPath
    document.addEventListener "keypress", onKeypress(xPath), true
    lastKnownPosition xPath

