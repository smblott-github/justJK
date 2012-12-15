
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
#
echo   = Util.echo

Dom = justJK.Dom =
  #
  xPathResultType: XPathResult.ANY_TYPE
  namespaceResolver: (namespace) -> if namespace == "xhtml" then "http://www.w3.org/1999/xhtml" else null

  # Return list of all elements of given class name.
  getElementsByClassName: (name) ->
    e for e in document.getElementsByTagName '*' when e.className is name

  # Is elements visible?
  visible: (element) ->
    while element
      return false if element?.style?.display is "none" or element.offsetHeight <= 0
      element = element.parentNode
    #
    return true

  # Filter out hidden elements.
  filterVisibleElements: (elements) ->
    # e for e in elements when e?.style?.display isnt "none"
    e for e in elements when @visible e

  # Return active element.
  # WARNING: This operation is proxied in "hacks.coffee".
  getActiveElement: ->
    document.activeElement

  # Return list of elements matching given XPath expression.
  evaluateXPath: (xPath) ->
    return [] unless xPath
    #
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

  # Return offset of the top of element vis-a-vis the top of the window.
  offsetTop: (element) ->
    ( Util.flatten element, (e,n) -> [ e.offsetTop, e.offsetParent ] )
      .reduce Util.sum, 0

  # Return offset of the bottom of element vis-a-vis the top of the window.
  offsetBottom: (element) ->
    element.offsetHeight + @offsetTop element

  # Return both the offsets of the top and the bottom of element vis-a-vis the top of the window.
  offsetTopBottom: (element) ->
    offsetTop = @offsetTop element
    [ offsetTop, offsetTop + element.offsetHeight ]

  # Compare two elements by their top position within the window.
  byElementPosition: (a,b) ->
    Dom.offsetTop(a) - Dom.offsetTop(b)

  # Return list of element together with all its offset parents.
  offsetParents: (element) ->
    Util.flatten element, (e) -> [ e, e.offsetParent ]

  # Is the position of element fixed?
  isFixed: (element) ->
    "fixed" in window.getComputedStyle(e).position for e in @offsetParents element

  # Return largest position of the bottom of a fixed banner.
  pageTopAdjustment: (xPath) ->
    ( @offsetBottom banner for banner in @evaluateXPath xPath when @isFixed banner )
      .reduce Math.max, 0

  # Call function "func" unless an input element is active.
  # WARNING: This operation is proxied in "hacks.coffee".
  doUnlessInputActive: (func) ->
    if document.activeElement?.nodeName in Const.verboten
      return true # Propagate.
    #
    func()
    return false # Prevent propagation.

