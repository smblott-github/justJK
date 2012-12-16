
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
    anchors = Dom.getElementsByTagName element, "a"
    anchors = Dom.filterVisibleElements anchors
    anchors = Array.prototype.slice.call anchors, 0
    hrefs   = Util.flattenList ( Util.extractHRefs(a) for a in anchors when a.href and not Util.stringStartsWith a.href, "javascript:" )
    hrefs   = Util.topRanked hrefs, (href) -> Score.scoreHRef config, href
    # For equal-scoring HREFs, prefer the longer one.
    hrefs   = hrefs.sort (a,b) -> a.length - b.length
    #
    if true
      for a in hrefs
        echo "#{Score.scoreHRef config, a} #{a}"
    #
    if 0 < hrefs.length
      chrome.extension.sendMessage
        request: "open"
        url:      hrefs.pop()
        # No callback
    else
      # No links?  Try "clicking" on the element.
      if element.click and typeof element.click is "function"
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
      keypress.combo "down",  -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      keypress.combo "up",    -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
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
      document.onscroll = ->
        Util.onlyOnce ->
          pageTop = Scroll.pageTop config.header
          pageBottom = pageTop + window.innerHeight
          #
          # Stick with the current element if it's in a reasonable position.
          if currentElement
            [ top, bottom ] = Dom.offsetTopBottom currentElement
            return if pageTop < bottom - 60
            # return if top < pageTop < bottom - 60
          #
          for element in Dom.getElementList config.xPath
            if pageTop <= Dom.offsetTop(element) or pageBottom - 300 < Dom.offsetBottom(element)
              return highlight element, false # "false" here means "do not scroll".

