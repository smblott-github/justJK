
debug = false
debug = true

# Return a list of elements under `element` matching `xPath`.
# Adapted from Vimium.
#

resultType = XPathResult.ANY_TYPE
namespaceResolver = (namespace) ->
  if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

evaluateXPath = (xPath, element=document) ->
  try
    xPathResult = document.evaluate xPath, element, namespaceResolver, resultType
    #
  catch error
    console.log "justJK xPath error: #{xPath}"
    console.log "justJK xPath error: #{error}"
    return []
    #
  finally
    return ( element while xPathResult and element = xPathResult.iterateNext() )

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

#
# Highlight an element and scroll it into view.
#
previousElement = null

highlight = (element) ->
  if element isnt null
    if previousElement isnt null
      previousElement.classList.remove "justjk_highlighted"
    previousElement = element
    element.classList.add "justjk_highlighted"
    smoothScroll element

# Navigate.
#
navigate = (xPath, mover) ->
  elements = evaluateXPath xPath
  n = elements.length
  #
  if 0 < n
    index = [0...n].filter (i) -> previousElement != null and elements[i] is previousElement
    if index.length == 0
      highlight elements[0]
    else
      highlight elements[mover index[0], n]
  return false # Do not propagate.

# KeyPress handler.
#
onKeypress = (xPath) -> (event) ->
  if document.activeElement.nodeName.trim() isnt "BODY"
    return true # Propagate.
  #
  event.stopPropagation()
  #
  switch String.fromCharCode event.charCode
    when "j" then return navigate xPath, (i,n) -> Math.min i+1, n-1
    when "k" then return navigate xPath, (i,n) -> Math.max i-1, 0
    when "z" then return navigate xPath, (i,n) -> 0
  return true # Propagate.

# ####################################################################
# Main: install listener?

request =
  request: "start"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  xPath = response?.xPath
  if xPath
    console.log "justJK: #{xPath}" if debug
    document.addEventListener "keypress", onKeypress(xPath), true
  else
    console.log "justJK inactive" if debug

