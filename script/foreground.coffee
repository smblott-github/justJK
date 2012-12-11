
# ####################################################################
# Utilities and constants.

stringContains    = (haystack, needle) -> haystack.indexOf(needle) != -1
extractKey        = (event)            -> event.which.toString()
namespaceResolver = (namespace)        -> if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

xPathResultType   =  XPathResult.ANY_TYPE
highlightCSS      = "justjk_highlighted"

#                                  j   k   z   J    K    Z
jkKeys = ( k.toString() for k in [ 74, 75, 90, 106, 107, 122 ] )

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
  return ( element while xPathResult and element = xPathResult.iterateNext() )

# ####################################################################
# Header offsets.
#
# Try to adjust the scroll offset for pages known to have static headers.  Content must no scroll up
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

# Smooth scrolling.
#
smoothScroll = (element) ->
  offSetTop = ssGetOffsetTop element
  target    = Math.max 0, offSetTop - ( ssOffset + ssOffsetAdjustment() )
  offset    = window.pageYOffset
  delta     = target - offset
  duration  = 400
  #
  ssStart   = Date.now()
  ssFactor  = 0
  #
  clearInterval ssTimer if ssTimer
  #
  intervalFunc = ->
    ssFactor = (Date.now() - ssStart) / duration
    #
    if 1 <= ssFactor
      clearInterval ssTimer
      ssTimer = null
      ssFactor = 1
    else
      # Scroll faster at the start, slowing down towards the end.
      ssFactor = Math.sqrt ssFactor
    #
    y = ssFactor * delta + offset
    window.scrollBy 0, y - window.pageYOffset
  #
  ssTimer = setInterval intervalFunc, 10
  #
  element

# ####################################################################
# Element identifiers.
#
# For Facebook, use the mf_story_key field of the JSON date-ft attribute.
# This seems to be stable.
#
extractIDFacebook = (element) ->
  try
    if dataFT = JSON.parse element.getAttribute "data-ft"
      if dataFT.mf_story_key
        return dataFT.mf_story_key
  return element.id

# For all other sites, just use element.id, if it is defined.
#
extractID = (element) ->
  switch window.location.host
    when "www.facebook.com" then extractIDFacebook element
    else element.id

# Notify the background script of the current ID for this page.
#
saveID = (element) ->
  if id = extractID element
    chrome.extension.sendMessage
      request: "saveID"
      id:       id
      host:     window.location.host
      pathname: window.location.pathname
      # No callback.
  #
  element

# ####################################################################
# Highlighting.
#
currentElement = null

# Highlight an element and scroll it into view.
#
highlight = (element) ->
  if element
    if currentElement
      currentElement.classList.remove highlightCSS
    #
    (currentElement = element).classList.add highlightCSS
    #
    saveID smoothScroll currentElement
    #
    # No element should have the focus.  Google Plus likes to grab the focus, which interferes with keystroke
    # handling.
    #
    document.activeElement.blur()
    #
    return true # Do not propagate.
  #
  return false # Propagate.

# ####################################################################
# Navigation: element cache.
#

elementCache = null

updateElementCache = (xPath) ->
  elementCache = evaluateXPath xPath

# ####################################################################
# Navigation.
#
# xPath is the XPath query for selecting elements.
# mover is a function.  It expects the current index and list length as arguments and returns a new index
# (usually i-1, i+1 or 0).
#
navigate = (xPath, mover) ->
  #
  unless elementCache? and elementCache.length
    updateElementCache xPath
  #
  elements = elementCache
  n = elements.length
  #
  if 0 < n
    index = (i for e, i in elements when e.classList.contains highlightCSS)
    if index.length == 0
      return highlight elements[0]
    else
      index = mover index[0], n
      # Update the element cache (to pick up any new entries) if we're in danger of falling of either end of
      # the lits.
      #
      updateElementCache xPath if index == 0 or index == n-1
      #
      return highlight elements[index]
  #
  return false # Propagate.

# ####################################################################
# Key handling routines.

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
# Given a list of HREFs associated with an element, pick the best one to follow.
# Scoring is ad hoc, based on heuristics which seem mostly to work.
#
# TODO: Move scoring to the background page.

# Host specific score adjustments.
#
scoreAdjustmentHost =
  "www.facebook.com": (href) ->
    score = 0
    # Boost score of photos on Facebook.
    if stringContains href, "/photo.php?fbid="
      score += 2
    score

doScoreAdjustmentHost = (href) ->
  if scoreAdjustmentHost[window.location.host]
    scoreAdjustmentHost[window.location.host](href)
  else
    0

# Pathname specific score adjustments.
# The key here is the first component of the pathname.
#
scoreAdjustmentPathname =
  "vbulletin": (href) ->
    score = 0
    # Prefer links to threads (over links to forums).
    if stringContains href, "/vbulletin/showthread.php"
      score += 1
      # Prefer links to new posts.
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
#
scoreHRef = (href) ->
  score = 0
  #
  # Prefer URLs containing redirects; they are often the main link.
  score += 4 if stringContains href, "%3A%2F%2"
  #
  # Prefer external links.
  # FIXME: apps.facebook.com is *not* an external link.  Fix this and similar.
  score += 3 unless stringContains href, window.location.host
  #
  # Score adjustments based on host and pathname.
  score += doScoreAdjustmentHost href
  score += doScoreAdjustmentPathname href
  #
  score

# Comparison for sorting.
#
compareHRef = (a,b) -> scoreHRef(a) - scoreHRef(b)

# ####################################################################
# Handle <enter>.
#
followLink = (xPath) ->
  if currentElement
    #
    anchors = currentElement.getElementsByTagName "a"
    anchors = Array.prototype.slice.call anchors, 0
    anchors = anchors.map (a) -> a.href
    anchors = anchors.sort compareHRef
    #
    if 0 < anchors.length
      request =
        request: "open"
        url:      anchors.pop()
      chrome.extension.sendMessage request
      return true
  #
  return false

# ####################################################################
# Handle j, k, z, and <enter>.
#
onKeypress = (xPath) -> (event) ->
  #
  if document.activeElement.nodeName in [ "BODY", "DIV" ]
    switch extractKey event
      # Lower, upper case.
      when "106", "74" then return killKeyEvent event, navigate xPath, (i,n) -> Math.min i+1, n-1 # j, J
      when "107", "75" then return killKeyEvent event, navigate xPath, (i,n) -> Math.max i-1, 0   # k, K
      when "122", "90" then return killKeyEvent event, navigate xPath, (i,n) -> 0                 # z, Z
      # And <enter>.
      when "13"        then return killKeyEvent event, followLink xPath                           # <enter>
  #
  return true # Propagate.

# ####################################################################
# Start up.
# Try to return to last known position (based on saved IDs).
# Otherwise, go to first element.

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
    #
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
    #
    document.addEventListener "keypress", onKeypress(xPath),   true
    document.addEventListener "keydown",  onKeypress(xPath),   true
    document.addEventListener "keyup",    killKeyEventHandler, true
    startUpAtLastKnownPosition xPath
  else
    #
    console.log "justJK inactive #{window.location.host} #{window.location.pathname}"

# ####################################################################
# Done.

