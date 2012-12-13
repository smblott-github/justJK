
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Dom    = justJK.Dom
Scroll = justJK.Scroll
#
echo   = Util.echo

# ####################################################################
# State.
#
currentElement = null
config         = {}

# ####################################################################
# Highlight an element and scroll it into view.
#
highlight = (element) ->
  if element
    if element isnt currentElement
      #
      if currentElement
        currentElement.classList.remove Const.highlightCSS
      #
      currentElement = element
      currentElement.classList.add Const.highlightCSS
      #
      chrome.extension.sendMessage
        request: "saveID"
        id:       currentElement.id
        host:     window.location.host
        pathname: window.location.pathname
        # No callback.
    #
    Scroll.smoothScrollToElement currentElement, config.header

# ####################################################################
# Logical navigation.
#
navigate = (xPath, move) ->
  elements = Dom.getElementList xPath
  n = elements.length
  #
  if 0 < n
    index = (i for e, i in elements when e.classList.contains Const.highlightCSS)
    if index.length == 0
      return highlight elements[0]
    #
    index = index[0]
    newIndex = Math.min n-1, Math.max 0, if move then index + move else 0
    if newIndex isnt index
      return highlight elements[newIndex]
    # Drop through.
  #
  Scroll.vanillaScroll move

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
  element = if xPath is Const.nativeBindings then Dom.getActiveElement() else currentElement
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
  xPath = config.xPath || Const.simpleBindings
  echo "justJK xPath: #{xPath}"
  #
  switch xPath
    when Const.simpleBindings
      keypress.combo "j",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      keypress.combo "k",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
      keypress.combo ";",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  0
    #
    when Const.nativeBindings
      keypress.combo "enter", -> Dom.doUnlessInputActive -> followLink xPath
    #
    else
      keypress.combo "j",     -> Dom.doUnlessInputActive -> navigate   xPath,  1
      keypress.combo "k",     -> Dom.doUnlessInputActive -> navigate   xPath, -1
      keypress.combo ";",     -> Dom.doUnlessInputActive -> navigate   xPath,  0
      keypress.combo "enter", -> Dom.doUnlessInputActive -> followLink xPath
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

