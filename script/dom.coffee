
window.justJK ?= {}
justJK = window.justJK

Util = justJK.Util
echo = Util.echo

Dom = justJK.Dom =
  getElementsByClassName: (name) ->
    e for e in document.getElementsByTagName '*' when e.className is name

  filterVisibleElements: (elements) ->
    e for e in elements when e?.style?.display isnt "none"

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

  xPathResultType: XPathResult.ANY_TYPE
  namespaceResolver: (namespace) -> if namespace == "xhtml" then "http://www.w3.org/1999/xhtml" else null

  evaluateXPath: (xPath) ->
    try
      xPathResult = document.evaluate xPath, document, @namespaceResolver, @xPathResultType
      #
    catch error
      echo "justJK xPath error: #{xPath}"
      return []
    #
    element while xPathResult and element = xPathResult.iterateNext()

  offsetTop: (element) ->
    e = element
    (e.offsetTop while e = e.offsetParent).reduce ( (p,c) -> p + c ), element.offsetTop

  byElementPosition: (a,b) ->
    Dom.offsetTop(a) - Dom.offsetTop(b)

  getElementList: (xPath) ->
    (e for e in @evaluateXPath xPath when 5 < e.offsetHeight).sort @byElementPosition

  offsetAdjustment: (xPath) ->
    if xPath
      if banners = @evaluateXPath xPath
        if banners and banners.length == 1 and banner = banners[0]
          if banner.offsetTop == 0 and banner.offsetHeight
            return banner.offsetHeight
    #
    return 0
