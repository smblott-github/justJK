
# ####################################################################
# Utilities and constants.

stringContains    = (haystack, needle) -> haystack.indexOf(needle) != -1
stringStartsWith  = (haystack, needle) -> haystack.indexOf(needle) ==  0
extractKey        = (event)            -> event.which.toString()
namespaceResolver = (namespace)        -> if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

vanillaScrollSize =  50
xPathResultType   =  XPathResult.ANY_TYPE
highlightCSS      = "justjk_highlighted"
simpleBindings    = "/justJKSimpleBindingsForJK"
nativeBindings    = "/justJKNativeBindingsForJK"
bogusXPath        = [ simpleBindings, nativeBindings ]

#                                  j   k   z   J    K    Z
jkKeys = ( k.toString() for k in [ 74, 75, 90, 106, 107, 122 ] )

normalNodeNames   = [ "DIV", "LI", "H1", "H2", "H3", "H4", "H5", "H6", "H7" ]
allNodeNames      = normalNodeNames.concat [ "BODY" ]

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
# Try to adjust the scroll offset for pages known to have static headers.  Content must not scroll up
# underneath such headers.
# 
# Basically, provide an XPath specification here.  The bottom of the indicated element (which must be
# unique) is taken to be the top of the normal page area.

# XPath for known headers.
#
ssHeaderXPath =
  "www.facebook.com": "//div[@id='pagelet_bluebar']/div[@id='blueBarHolder']/div['blueBar']/../.."
  "plus.google.com":  "//div[@id='gb']"
  "twitter.com":      "//div[starts-with(@class,'topbar')]/div[@class='global-nav']"

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
# Vanilla scroller.
#
vanillaScroll = (mover) ->
  position = window.pageYOffset / vanillaScrollSize
  newPosition = if mover then position + mover else 0
  window.scrollBy 0, (newPosition - position) * vanillaScrollSize
  return true # Do not propagate.

# ####################################################################
# Notify the background script of the current ID for this page.
#
saveID = (element) ->
  if id = element.id
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
    smoothScroll currentElement
    saveID currentElement
    return true # Do not propagate.
  #
  return false # Propagate.

# ####################################################################
# Navigation.
#
# xPath is the XPath query for selecting elements.
# mover is an integer, usually -1, 0 or 1
#
navigate = (xPath, mover) ->
  #
  if xPath is simpleBindings
    return vanillaScroll mover
  #
  if xPath is nativeBindings
    return false # Propagate
  #
  elements = evaluateXPath xPath
  elements = ( e for e in elements when 5 < e.offsetHeight )
  n = elements.length
  #
  if 0 < n
    index = (i for e, i in elements when e.classList.contains highlightCSS)
    if index.length == 0
      return highlight elements[0]
    else
      index = index[0]
      newIndex = Math.min n-1, Math.max 0, if mover then index + mover else mover
      console.log "#{n} #{index} -> #{newIndex}"
      unless newIndex is index
        return highlight elements[newIndex]
      # Drop through ...
  #
  vanillaScroll mover

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

  "www.google.com": (href) ->
    score = 0
    # Boost score of photos on Facebook.
    if stringContains href, "://webcache.googleusercontent.com/"
      score -= 2
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
# Find active element.
#
findActiveElement = ->
  element = document.activeElement
  #
  # With Facebook native bindings, the active element is some "H5" object deep within the actual post.  To
  # find a link worth following, we must first got up the document tree a bit.
  #
  if window.location.host is "www.facebook.com"
    while element and element.nodeName isnt "LI"
      element = element.parentNode
  #
  element

# ####################################################################
# Handle <enter>.
#
followLink = (xPath) ->
  #
  switch xPath
    when simpleBindings then element = null
    when nativeBindings then element = findActiveElement()
    else                     element = currentElement
  #
  unless element and element.nodeName in normalNodeNames
    return false # Propagate.
  #
  anchors = element.getElementsByTagName "a"
  anchors = Array.prototype.slice.call anchors, 0
  anchors = ( a.href for a in anchors when not stringStartsWith a.href, "javascript:" )
  anchors = anchors.sort compareHRef
  #
  if 0 < anchors.length
    request =
      request: "open"
      url:      anchors[anchors.length - 1]
    chrome.extension.sendMessage request
    return true # Do not propagate.
  #
  return false # Propagate.

# ####################################################################
# Handle j, k, z, and <enter>.
#
onKeypress = (xPath) ->
  (event) ->
    #
    if document.activeElement.nodeName in allNodeNames
      switch key = extractKey event
        # Lower, upper case.
        when "106", "74" then return killKeyEvent event, navigate xPath,  1 # j, J
        when "107", "75" then return killKeyEvent event, navigate xPath, -1 # k, K
        when "122", "90" then return killKeyEvent event, navigate xPath,  0 # z, Z
        # And <enter>.
        when "13"        then return killKeyEvent event, followLink xPath   # <enter>
        #
        # Else: drop through ...
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
          # Don't return to last known element if we've already selected an element.
          unless xPath in bogusXPath
            unless currentElement
              return highlight element
    #
    # Not found.
    # Go to first element, if appropriate.
    #
    unless xPath in bogusXPath
      unless currentElement
        navigate xPath, 0

# ####################################################################
# Main: install listener and highlight previous element (or first).

request =
  request: "lookup"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  xPath = response?.xPath
  xPath ?= simpleBindings
  #
  document.addEventListener "keypress", onKeypress(xPath),   true
  document.addEventListener "keydown",  onKeypress(xPath),   true
  document.addEventListener "keyup",    killKeyEventHandler, true if xPath isnt nativeBindings
  #
  startUpAtLastKnownPosition xPath unless xPath in bogusXPath

# ####################################################################
# Done.

