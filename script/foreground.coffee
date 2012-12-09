
# Copied and adapted from Vimium.
# Return a list of nodes under `node` matching `xPath`.
#
evaluateXPath = (xPath, node=document) ->
  resultType = XPathResult.ANY_TYPE
  namespaceResolver = (namespace) ->
    if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null
  xpathResult = document.evaluate(xPath, node, namespaceResolver, resultType, null)
  nodes = []
  if xpathResult
    node = xpathResult.iterateNext()
    while node
      nodes.push node
      node = xpathResult.iterateNext()
  nodes

# Smooth scrolling.
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#
timer  = null
start  = null
factor = null

smoothScroll = (element) ->
  target   = element.offsetTop
  offset   = window.pageYOffset
  delta    = target - offset
  duration = 300
  #
  start    = Date.now()
  factor   = 0

  if timer
    clearInterval timer

  timer = setInterval ->
      factor = (Date.now() - start) / duration
      if factor >= 1
        clearInterval timer
        factor = 1
      y = factor * delta + offset
      window.scrollBy 0, y - window.pageYOffset
    # Interval.
    10

# Highlighting state.
#
previous = null

# Highlight a node and scroll it into view.
#
highlight = (node) ->
  if node isnt null
    if previous isnt null
      previous.classList.remove "justjk_highlighted"
    previous = node
    node.classList.add "justjk_highlighted"
    smoothScroll node

# Navigate.
#
navigate = (xPath, mover) ->
  nodes = evaluateXPath xPath
  n = nodes.length
  #
  if 0 < n
    index = [0...n].filter (i) -> previous != null and nodes[i] is previous
    if index.length == 0
      highlight nodes[0]
    else
      highlight nodes[mover index[0], n]
  #
  true

# KeyPress handler.
#
onKeypress = (xPath) -> (event) ->
  if document.activeElement.nodeName == "BODY"
    console.log String.fromCharCode event.charCode
    switch String.fromCharCode event.charCode
      when "j" then navigate xPath, (i,n) -> Math.min i+1, n-1
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
    document.addEventListener "keypress", onKeypress(xPath), true

