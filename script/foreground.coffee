
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Dom    = justJK.Dom
Scroll = justJK.Scroll
Score  = justJK.Score
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
highlight = (element, scroll=true) ->
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
    if scroll
      Scroll.smoothScrollToElement currentElement, config.header

# ####################################################################
# Arm elements for highlighting on click.
#
jjkAttribute = Const.jjkAttribute

addHighlightOnClickHandlers = (elements) ->
  for element in elements
    unless element[jjkAttribute]
      do (element) ->
        element.onclick = ->
          highlight element, false # "false" here means "do not scroll".
        #
        element[jjkAttribute] = true
  #
  elements

# ####################################################################
# Handle logical navigation.
#
navigate = (xPath, move) ->
  elements = addHighlightOnClickHandlers Dom.getElementList xPath
  n = elements.length
  #
  if 0 < n
    index = (i for e, i in elements when e.classList.contains Const.highlightCSS)
    if index.length == 0
      return highlight elements[0]
    #
    index = index[0]
    #
    # When mixing logical scrolling with other scrolling, the selected element can be in a variety of
    # positions.  The UX is better with the following adjustments.
    #
    if move and not Scroll.scrolling()
      element = elements[index]
      #
      if currentElement and element is currentElement
        elementTop = Dom.offsetTop element
        pageTop = Scroll.pageTop config.header
        #
        switch move
          when  1 then return highlight element if pageTop    < elementTop
          when -1 then return highlight element if elementTop < pageTop
        # Drop through.
    #
    # Normal navigation.
    #
    newIndex = Math.min n-1, Math.max 0, if move then index + move else 0
    if newIndex isnt index
      return highlight elements[newIndex]
    # Drop through.
  #
  Scroll.vanillaScroll move

# ####################################################################
# Handle <enter>.
#
followLink = (xPath) ->
  #
  # If the active element is an anchor then we follow the link regardless.
  if document.activeElement?.nodeName is "A"
    return document.activeElement.click()
  #
  element = if xPath is Const.nativeBindings then Dom.getActiveElement() else currentElement
  #
  if element
    anchors = Dom.filterVisibleElements element.getElementsByTagName "a"
    anchors = Array.prototype.slice.call anchors, 0
    anchors = ( a.href for a in anchors when a.href and not Util.stringStartsWith a.href, "javascript:" )
    # Reverse the list so that, when there are multiple top-scoring HREFs, the originally first of those ends
    # up last.
    anchors = anchors.reverse().sort Score.compareHRef config.like, config.dislike
    #
    echo.apply Util, anchors
    #
    if 0 < anchors.length
      chrome.extension.sendMessage
        request: "open"
        url:      anchors.pop()
        # No callback
    else
      # No links.  Try "clicking" the the element.
      if typeof element.click is "function"
        element.click.apply element

# ####################################################################
# Main: install listener and highlight previous element (or first).

request =
  request: "config"
  host:     window.location.host
  pathname: window.location.pathname

chrome.extension.sendMessage request, (response) ->
  config = response
  config.logical = false
  #
  xPath = config.xPath
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
      keypress.combo "down",  -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      keypress.combo "up",    -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
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
      #
      # ########################
      # Highlight new selection on scroll.
      #
      onscrollTimer = null
      onscrollCallback  = ->
        onscrollTimer = null
        pageTop = Scroll.pageTop config.header
        #
        if currentElement
          [ top, bottom ] = Dom.offsetTopBottom currentElement
          return if top < pageTop < bottom - 60
        #
        for element in Dom.getElementList config.xPath
          if pageTop <= Dom.offsetTop element
            return highlight element, false # "false" here means "do not scroll".
      #
      document.onscroll = ->
        clearInterval onscrollTimer if onscrollTimer
        onscrollTimer = setTimeout onscrollCallback, 300

