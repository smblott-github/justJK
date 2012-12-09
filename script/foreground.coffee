
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
    xpathResult = document.evaluate(xPath, element, namespaceResolver, resultType, null)
    #
  catch error
    console.log "justJK xPath error: #{xPath}"
    return []
    #
  finally
    return ( element while xpathResult and element = xpathResult.iterateNext() )

# Smooth scrolling.
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#
timer  = null
start  = null
factor = null

smoothScroll = (element) ->
  offSetTop = element.offsetTop
  # offSetTop = element.offsetTop + findPos element
  target    = Math.max 0, offSetTop - 10
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
      if factor >= 1
        clearInterval timer
        timer = null
        factor = 1
      y = factor * delta + offset
      window.scrollBy 0, y - window.pageYOffset
    # Interval.
    10

# Highlighting state.
#
previous = null

# Highlight an element and scroll it into view.
#
highlight = (element) ->
  if element isnt null
    if previous isnt null
      previous.classList.remove "justjk_highlighted"
    previous = element
    element.classList.add "justjk_highlighted"
    smoothScroll element

# Navigate.
#
navigate = (xPath, mover) ->
  elements = evaluateXPath xPath
  n = elements.length
  #
  if 0 < n
    index = [0...n].filter (i) -> previous != null and elements[i] is previous
    if index.length == 0
      highlight elements[0]
    else
      highlight elements[mover index[0], n]
  #
  true

# KeyPress handler.
#
onKeypress = (xPath) -> (event) ->
  if document.activeElement.nodeName.trim() == "BODY"
    switch String.fromCharCode event.charCode
      when "j"
        navigate xPath, (i,n) -> Math.min i+1, n-1
      when "k" then navigate xPath, (i,n) -> Math.max i-1, 0
      when "z" then navigate xPath, (i,n) -> 0
      else false

# ####################################################################
# Main.

request =
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  xPath = response?.xPath
  if xPath
    console.log "justJK: #{xPath}" if debug
    document.addEventListener "keypress", onKeypress(xPath), true
  else
    console.log "justJK inactive" if debug

