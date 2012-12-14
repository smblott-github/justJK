
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const

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

  # Return active element.
  # WARNING: This operation is proxied in "hacks.coffee".
  getActiveElement: ->
    document.activeElement

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
      Util.echo 1
      if banners = @evaluateXPath xPath
        Util.echo 2
        if banners and banners.length == 1 and banner = banners[0]
          Util.echo 3
          Util.echo @offsetTop banner
          Util.echo banner.offsetHeight
          if banner.offsetHeight and 0 == @offsetTop banner
            Util.echo "HEADER: #{banner.offsetHeight}"
            return banner.offsetHeight
    Util.echo 4
    #
    0

  # Call function "func" unless an input element is active.
  # WARNING: This operation is proxied in "hacks.coffee".
  doUnlessInputActive: (func) ->
    if document.activeElement?.nodeName in Const.verboten
      return true # Propagate.
    #
    func()
    return false # Prevent propagation.

