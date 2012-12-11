
# ####################################################################
# Utilities and constants.

stringContains = (haystack, needle) -> (haystack.indexOf(needle) != -1)

googlePlus = "XXplus.google.com"
facebook   = "www.facebook.com"

# ####################################################################
# XPath.
#
resultType = XPathResult.ANY_TYPE
namespaceResolver = (namespace) -> if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

# Return a list of document elements matching `xPath`.
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
# Try to adjust the scroll offset for pages known to have static headers.  We don't want to scroll content up
# underneath such headers.
# 
# Basically, provide an XPath specification here.  The bottom of the indicated element (which must be
# unique) is taken to be the top of the normal page area.

# XPath for known headers.
#
ssHeaderXPath =
  "www.facebook.com": "//div[@id='pagelet_bluebar']/div[@id='blueBarHolder']/div['blueBar']/../.."
  "plus.google.com":  "//div[@id='gb']"

# Offset adjustment.
#
ssOffsetAdjustment = ->
  if xPath = ssHeaderXPath[window.location.host]
    if banners = evaluateXPath xPath
      if banners and banners.length == 1
        banner = banners[0]
        if banner.offsetTop == 0 and banner.offsetHeight? and banner.offsetHeight
          return banner.offsetHeight
  return 0

# ####################################################################
# Scrolling.

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

# Smooth scrolling.
#
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

  timerFunc = ->
    ssFactor = (Date.now() - ssStart) / duration
    if 1 <= ssFactor
      clearInterval ssTimer
      ssTimer = null
      ssFactor = 1
    y = ssFactor * delta + offset
    window.scrollBy 0, y - window.pageYOffset

  timerFunc()
  ssTimer = setInterval timerFunc, 10

# ####################################################################
# Element identifiers.
#
extractIDFacebook = (element) ->                                                                                                                               
  try                                                                                                                                                          
    if dataFT = JSON.parse element.getAttribute "data-ft"                                                                                                      
      if dataFT.mf_story_key                                                                                                                                   
        return dataFT.mf_story_key                                                                                                                             
  return element.id

extractID = (element) ->
  switch window.location.host
    when "www.facebook.com" then extractIDFacebook element
    else element.id

# Notify the background script of the current ID for this page.
#
notifyID = (element) ->
  if id = extractID element
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
    if currentElement
      currentElement.classList.remove highlightCSS
    #
    console.log element
    currentElement = element
    currentElement.classList.add highlightCSS
    #
    smoothScroll currentElement
    notifyID currentElement
    #
    # No element should have the focus.  This is necessary for Google Plus.
    document.activeElement.blur()
    #
    return true # Do not propagate.
  #
  return false # Propagate.

# Navigate: forward or backward.
#
navigate = (xPath, mover) ->
  #
  elements = evaluateXPath xPath
  n = elements.length
  console.log n
  #
  if 0 < n
    index = (i for e, i in elements when e.classList.contains highlightCSS)
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
# Scoring HREFs.
#
scoreAdjustmentHost =
  "www.facebook.com": (href) ->
    score = 0
    if stringContains href, "/photo.php?fbid="
      score += 2
    score

doScoreAdjustmentHost = (href) ->
  if scoreAdjustmentHost[window.location.host]
    scoreAdjustmentHost[window.location.host](href)
  else
    0

scoreAdjustmentPathname =
  "vbulletin": (href) ->
    score = 0
    if stringContains href, "/vbulletin/showthread.php"
      score += 1
      if stringContains href, "goto=newpost"
        score += 1
    score

doScoreAdjustmentPathname = (href) ->
  paths = window.location.pathname.split "/"
  if 2 <= paths.length
    path = paths[1]
    if scoreAdjustmentPathname[path]
      return scoreAdjustmentPathname[path](href)
  return 0

# Score an HRef.  Higher is better.
scoreHRef = (href) ->
  score = 0
  # Prefer URLs containing redirects; they are often the main link.
  if stringContains href, "%3A%2F%2"
    score += 4
  # Prefer external links.
  unless stringContains href, window.location.host
    score += 3
  #
  # Score adjustments based on host.
  score += doScoreAdjustmentHost href
  #
  # Score adjustments based on pathname.
  score += doScoreAdjustmentPathname href
  #
  score

# Sort into reverse order, so we can pick the best one off the front of the list.
compareHRef = (a,b) -> scoreHRef(b) - scoreHRef(a)

# ####################################################################
# Handle <enter>.
#
followLink = (xPath) ->
  element = currentElement
  #
  anchors = element.getElementsByTagName "a"
  anchors = Array.prototype.slice.call anchors, 0
  anchors = anchors.map (a) -> a.href
  anchors = anchors.sort compareHRef
  #
  for a in anchors
    console.log ">>>>>>> #{scoreHRef a} #{a}"
  #
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
  switch extractKey event
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

