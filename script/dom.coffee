
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Cache  = justJK.Cache
#
echo   = Util.echo
show   = Util.show

Dom = justJK.Dom =
  #
  xPathResultType: XPathResult.ANY_TYPE
  namespaceResolver: (namespace) -> if namespace == "xhtml" then "http://www.w3.org/1999/xhtml" else null

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

  # Return active element.
  # WARNING: This operation is proxied in "hacks.coffee".
  getActiveElement: ->
    document.activeElement

  # Is element visible?
  visible: (element) ->
    Cache.eleCacheUse "visible", element, =>
      for ele in @offsetParents(element)[1..]
        if ele.offsetHeight <= 0
          return false
      #
      for ele in @parentNodes element
        if style = window.getComputedStyle ele
          if style.display is "none"
            return false
          if style.visibility is "hidden"
            return false
          if style.overflow is "hidden"
            top = @offsetTop ele
            for parent in @offsetParents ele
              bottom = @offsetBottom parent
              if bottom <= top
                return false
      #
      true

  # Return list of elements matching given XPath expression sorted by their position within the window.
  # Additionally, strip out elements which aren't very high.  Many of these are in fact hidden.
  #
  getElementList: (xPath) ->
    (e for e in @evaluateXPath xPath when @visible e).sort @byElementPosition

  # Compare two elements by their position within the window, top before bottom, then left before right.
  #
  byElementPosition: (a,b) ->
      aTop = Dom.offsetTop a
      bTop = Dom.offsetTop b
      if aTop == bTop then Dom.offsetLeft(a) - Dom.offsetLeft(b) else aTop - bTop

  # Return offset of the top of element vis-a-vis the top of the window.
  #
  offsetTop: (element) ->
    Cache.eleCacheUse "offSetTop", element, =>
      Util.sum ( e.offsetTop for e in @offsetParents element when e.offsetTop )...

  # Return offset of the left of element vis-a-vis the left of the window.
  #
  offsetLeft: (element) ->
    Cache.eleCacheUse "offSetLeft", element, =>
      Util.sum ( e.offsetLeft for e in @offsetParents element when e.offsetLeft )...

  # Return offset of the bottom of element vis-a-vis the top of the window.
  #
  offsetBottom: (element) ->
    Cache.eleCacheUse "offSetBottom", element, =>
      element.offsetHeight + @offsetTop element

  # Return both the offsets of the top and the bottom of element vis-a-vis the top of the window.
  #
  offsetTopBottom: (element) ->
    Cache.eleCacheUse "offSetTopBottom", element, =>
      offsetTop = @offsetTop element
      [ offsetTop, offsetTop + element.offsetHeight ]

  # Return list of element and all of its parent nodes.
  #
  parentNodes: (element) ->
    Cache.eleCacheUse "parentNodes", element, =>
      if not element then [] else [ element ].concat @parentNodes element.parentNode

  # Return list of element and all of its offset parents.
  #
  offsetParents: (element) ->
    Cache.eleCacheUse "offsetParents", element, =>
      if not element then [] else [ element ].concat @offsetParents element.offsetParent

  # Is the position of element fixed?
  #
  isFixed: (element) ->
    Cache.eleCacheUse "isFixed", element, =>
      if element
        window.getComputedStyle(element).position is "fixed" or @isFixed element.offsetParent
      else
        false

  # Return largest position of the bottom of a fixed element.
  # 
  pageTopAdjustment: (xPath) ->
    Cache.callDomCache xPath, =>
      Math.max 0,
        Math.max ( @offsetBottom element for element in @evaluateXPath xPath when @isFixed element )...

  # Call function "func" unless an input element is active.
  # WARNING: This operation is proxied in "hacks.coffee".
  #
  doUnlessInputActive: (func) ->
    if document.activeElement.nodeName in Const.verboten
      return true # Propagate.
    #
    Cache.eleCacheStart func
    return false # Prevent propagation.

