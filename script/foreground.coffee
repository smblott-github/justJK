
justJK = window.justJK ?= {}
Util   = justJK.Util
Const  = justJK.Const
Cache  = justJK.Cache
Dom    = justJK.Dom
Scroll = justJK.Scroll
Score  = justJK.Score
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
unhighlight = ->
  if currentElement
    currentElement.classList.remove Const.highlightCSS
    currentElement.classList.remove Const.currentClass
    currentElement = null

highlight = (element, scroll=true) ->
  if element
    if element isnt currentElement
      unhighlight()
      currentElement = element
      currentElement.classList.add Const.currentClass
      currentElement.classList.add Const.highlightCSS unless "no-highlight" in config.option
      # Drop through.
    #
    if currentElement and scroll
      # Grab the focus, but only if we're actually scrolling to an element.  If we're just scrolling
      # independently of justJK, then leave the focus where it is.
      document.activeElement.blur() if document.activeElement
      element.focus()
      #
      Scroll.smoothScrollToElement currentElement, config if scroll

# ####################################################################
# Arm elements for highlighting on click.
#
jjkAttribute = Const.jjkAttribute

addHighlightOnClickHandlers = (elements) ->
  for element in elements
    unless jjkAttribute of elements
      element[jjkAttribute] = true
      clicker = element.onclick
      do (element,clicker) ->
        element.onclick = ->
          highlight element, true
          clicker.apply element if clicker
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
    index = ( i for e, i in elements when e.classList.contains Const.currentClass )
    return highlight elements[0] if not index.length
    #
    index = index[0]
    move  = n - index - 1 if move is Const.last
    #
    # Consider sticking with the current element ... specifically, if scrolling would involve jumping past the
    # current element.
    if move and not Scroll.smoothScrollByDelta() # That is, not already scrolling.
      pageTop = Scroll.pageTop config
      eleTop  = Dom.offsetTop elements[index]
      switch move
        when  1 then return highlight elements[index] if pageTop < eleTop and index is 0
        when -1 then return highlight elements[index] if eleTop < pageTop # and index is n-1 ???
    #
    newIndex = Math.min n-1, Math.max 0, if move then index + move else 0
    return highlight elements[newIndex] if newIndex isnt index
    # Drop through, default to vanillaScroll.
  #
  Scroll.vanillaScroll move

# ####################################################################
# Handle <enter>.
#
followLink = (xPath) ->
  #
  # If the active element is an anchor then we click it, regardless.
  return document.activeElement.click() if document.activeElement?.nodeName is "A"
  #
  # Youtube hack.  Enter key on a youtube video page switches between normal and popup views.
  if window.location.host is "www.youtube.com"
    switch window.location.pathname
      when "/watch"       then return window.location = "/watch_popup#{window.location.search}"
      when "/watch_popup" then return window.location = "/watch#{window.location.search}"
  #
  element = if xPath is Const.nativeBindings then Dom.getActiveElement() else currentElement
  if element and element isnt document.body
    #
    # Extract top-scoring URLs from element.
    #
    urls = do ->
      maxScore = -Infinity
      echo "--"
      updateMax = (score) -> if maxScore < score then maxScore = score else score
      #
      _.chain(element.getElementsByTagName "a")
        # 
        # We have a list of anchors, now:
        #   filter out those that are not of interest ...
        #
        .reject((a) -> Util.stringStartsWith a.href, "javascript:")
        #
        # Now:
        #   extract URLs from the anchors ...
        #
        .map(Util.extractURLs, Util)
        .flatten()
        #
        # Log the URLs and their scores ...
        #
        .map (url) ->
          echo "#{Score.scoreHRef config, url} #{url}"
          url
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
    if urls.length
      chrome.extension.sendMessage
        request: "open"
        url:      urls[0]
        # No callback
    else
      # # No URLs?  Try "clicking" on the element.
      # if element.click and typeof element.click is "function"
      #   element.click.apply element
      #
      # es = element.getElementsByTagName('*')
      # for i in [0..es.length]
      #   if e = es[i]
      #     console.log e
      #     console.log e.onclick
      #     console.log e.click
      #     if e.click and typeof e.click is "function"
      #       console.log "hit click"
      #       return e.click.apply element
      #     if e.onclick and typeof e.onclick is "function"
      #       console.log "hit onclick"
      #       return e.onclick.apply element

# ####################################################################
# Main: install listener and highlight previous element (or first).

request =
  request: "config"
  host:     window.location.host
  pathname: window.location.pathname + window.location.hash

chrome.extension.sendMessage request, (response) ->
  config = response
  xPath  = config.xPath
  #
  switch xPath
    #
    when Const.nativeBindings
      unless "no-enter" in config.option
        Util.keypress "enter", -> Dom.doUnlessInputActive -> followLink xPath
        Util.keypress ";",     -> Dom.doUnlessInputActive -> Scroll.vanillaScroll 0
    #
    when Const.simpleBindings
      Util.keypress "j",       -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      Util.keypress "k",       -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
      Util.keypress ";",       -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  0
      Util.keypress "down",    -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      Util.keypress "up",      -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
    #
    else
      Util.keypress "j",       -> Dom.doUnlessInputActive -> navigate xPath,  1
      Util.keypress "k",       -> Dom.doUnlessInputActive -> navigate xPath, -1
      Util.keypress ";",       -> Dom.doUnlessInputActive -> navigate xPath,  0
      Util.keypress ":",       -> Dom.doUnlessInputActive -> navigate xPath,  Const.last
      Util.keypress "down",    -> Dom.doUnlessInputActive -> Scroll.vanillaScroll  1
      Util.keypress "up",      -> Dom.doUnlessInputActive -> Scroll.vanillaScroll -1
      #
      unless "no-enter" in config.option
        Util.keypress "enter", -> Dom.doUnlessInputActive -> followLink xPath
      #
      document.onscroll =
        Util.throttle ->
          Cache.eleCacheStart ->
            pageTop    = window.pageYOffset + Dom.pageTopAdjustment config
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
            elements = addHighlightOnClickHandlers Cache.callDomCache "navigate", -> Dom.getElementList xPath
            if elements.length
              for element in elements
                [ top, bottom ] = Dom.offsetTopBottom element
                #
                return highlight element, false if pageTop < top
                return highlight element, false if pageFocus2 < bottom
              #
              # Must be off the bottom.  Highlight the last element.
              return highlight elements.pop(), false

