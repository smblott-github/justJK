
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Cache  = justJK.Cache
Dom    = justJK.Dom
Scroll = justJK.Scroll
Score  = justJK.Score
#
echo   = Util.echo
_      = window._

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
  elements = addHighlightOnClickHandlers Cache.callDomCache "navigate", -> Dom.getElementList xPath
  n = elements.length
  #
  if 0 < n
    index = ( i for e, i in elements when e.classList.contains Const.highlightCSS )
    if index.length == 0
      return highlight elements[0]
    #
    if 1 < index.length
      echo "lastJK error: multiple elements selected"
    #
    index = index[0]
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
  # If the active element is an anchor then we click it regardless.
  echo "followLink"
  if document.activeElement?.nodeName is "A"
    return document.activeElement.click()
  #
  element = if xPath is Const.nativeBindings then Dom.getActiveElement() else currentElement
  if element and element isnt document.body
    #
    # Extract top-scoring URLs from element.
    #
    urls = do ->
      maxScore = -Infinity
      updateMax = (score) -> if maxScore < score then maxScore = score else score
      #
      _.chain(element.getElementsByTagName "a")
        # 
        # We have a list of anchors, now:
        #   filter out those that are not of interest ...
        #
        .reject((a) -> Util.stringStartsWith a.href, "javascript:")
        .filter(Dom.visible, Dom)
        #
        # Now:
        #   extract URLs from the anchors ...
        #
        .map(Util.extractURLs, Util)
        .flatten()
        .map(Util.show, Util)
        # 
        # Now:
        #   score each URL, keeping only those with the highest score ...
        #
        .map(    (  url        ) -> [ url, updateMax Score.scoreHRef config, url ] )
        .filter( ( [url,score] ) -> score == maxScore )
        .map(    ( [url,score] ) -> url )
        #
        .value()
    #
    if 0 < urls.length
      chrome.extension.sendMessage
        request: "open"
        url:      urls[0]
        # No callback
    else
      # No URLs?  Try "clicking" on the element.
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
    #
    when Const.nativeBindings
      unless "no-enter" in config.options
        keypress.combo "enter", -> Dom.doUnlessInputActive -> followLink xPath
    #
    when Const.simpleBindings
      keypress.combo "j",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      keypress.combo "k",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
      keypress.combo ";",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  0
      #
      keypress.combo "down",  -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      keypress.combo "up",    -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
    #
    else
      keypress.combo "j",     -> Dom.doUnlessInputActive -> navigate xPath,  1
      keypress.combo "k",     -> Dom.doUnlessInputActive -> navigate xPath, -1
      keypress.combo ";",     -> Dom.doUnlessInputActive -> navigate xPath,  0
      #
      unless "no-enter" in config.options
        keypress.combo "enter", -> Dom.doUnlessInputActive -> followLink xPath
      #
      keypress.combo "down",  -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      keypress.combo "up",    -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
      #
      # 
      window.addEventListener "DOMContentLoaded", ->
        request =
          request: "lastID"
          host:     window.location.host
          pathname: window.location.pathname
        
        chrome.extension.sendMessage request, (response) ->
          Cache.eleCacheStart ->
            if not currentElement
              if response?.id
                for element in Dom.getElementList xPath
                  if element.id and response.id is element.id
                    return highlight element
              #
              # Go to first element.
              #
              navigate xPath, 0
        
      # ########################
      # Highlight new selection on scroll.
      #
      if true
        document.onscroll =
          Util.throttle ->
            Cache.eleCacheStart ->
              pageTop = window.pageYOffset + Dom.pageTopAdjustment config.header
              pageBottom = window.pageYOffset + window.innerHeight
              pageFocus1 = pageTop + (pageBottom - pageTop) * 0.2
              pageFocus2 = pageTop + (pageBottom - pageTop) * 0.7
              #
              # Stick with the current element if it's in a reasonable position.
              if currentElement
                [ top, bottom ] = Dom.offsetTopBottom currentElement
                return if pageTop < top and bottom < pageBottom          # Still wholly on page.
                return if top <= pageFocus1 <= bottom                    # Spans focus point 1.
              #
              elements = Dom.getElementList config.xPath
              if elements.length
                for element in elements
                  [ top, bottom ] = Dom.offsetTopBottom element
                  #
                  return highlight element, false if pageTop < top
                  return highlight element, false if pageFocus2 < bottom
                #
                # Must be off the bottom.  Highlight the last element.
                return highlight elements.pop(), false

