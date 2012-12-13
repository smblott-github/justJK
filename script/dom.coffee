
justJK = window.justJK ?= {}
#
Util   = justJK.Util

Dom = justJK.Dom =
  #
  xPathResultType: XPathResult.ANY_TYPE
  namespaceResolver: (namespace) -> if namespace == "xhtml" then "http://www.w3.org/1999/xhtml" else null

  # Return list of all elements of given class name.
  getElementsByClassName: (name) ->
    e for e in document.getElementsByTagName '*' when e.className is name

  # Filter out hidden elements.
  filterVisibleElements: (elements) ->
    e for e in elements when e?.style?.display isnt "none"

  # Return active element (or its proxy).
  getActiveElement: ->
    element = document.activeElement
    #
    switch window.location.host
      when "www.facebook.com"
        # With Facebook's native bindings, the active element is some "H5" object deep within the actual post.
        # To find a link worth following, we must first got up the document tree a bit.
        #
        while element and element.nodeName isnt "LI"
          element = element.parentNode
        #
        return element || document.activeElement
    #
    element

  # Return list of elements matching given XPath expression.
  evaluateXPath: (xPath) ->
    try
      xPathResult = document.evaluate xPath, document, @namespaceResolver, @xPathResultType
      #
    catch error
      Util.echo "justJK xPath error: #{xPath}"
      return []
    #
    element while xPathResult and element = xPathResult.iterateNext()

  # Return list of element matcing given XPath expression sorted by their position within the window.
  getElementList: (xPath) ->
    (e for e in @evaluateXPath xPath when 5 < e.offsetHeight).sort @byElementPosition

  # Return offset of element vis-a-vis the top of the window.
  offsetTop: (element) ->
    e = element
    (e.offsetTop while e = e.offsetParent).reduce ( (p,c) -> p + c ), element.offsetTop

  # Compare two elements by their position within the window.
  byElementPosition: (a,b) ->
    Dom.offsetTop(a) - Dom.offsetTop(b)

  # Return position of banner (specified by xPath) within the window.
  offsetAdjustment: (xPath) ->
    if xPath
      if banners = @evaluateXPath xPath
        if banners and banners.length == 1 and banner = banners[0]
          if banner.offsetTop == 0 and banner.offsetHeight
            return banner.offsetHeight
    #
    0

