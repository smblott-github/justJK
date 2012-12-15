
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
#
echo   = Util.echo
show   = Util.show

Dom = justJK.Dom =
  #
  xPathResultType: XPathResult.ANY_TYPE
  namespaceResolver: (namespace) -> if namespace == "xhtml" then "http://www.w3.org/1999/xhtml" else null

  # Return list of all elements of given class name.
  getElementsByClassName: (name) ->
    e for e in document.getElementsByTagName '*' when e.className is name

  # # Is element visible?
  # visible: (element) ->
  #   window.getComputedStyle(element).display isnt "none" and
  #     @offsetParents(element)
  #       .reduce ( (p,e) -> p and 0 < e.offsetHeight ), true

  # # Is element visible?
  # visible: (element) ->
  #   for e in @parentNodes element
  #     return false if e.offsetHeight <= 0
  #     if style = window.getComputedStyle(e)
  #       return false if style.display    is "none"
  #       return false if style.visibility is "hidden"
  #   #
  #   true

  # Is element visible?
  visible: (element) ->
    height = 0
    for e in @offsetParents element
      if e.offsetHeight <= 0
        echo "height"
        echo e
        echo e.scrollHeight
        return false
    #
    for e in @parentNodes element
      if style = window.getComputedStyle(e)
        if style.display is "none"
          echo "display"
          return false
        if style.visibility is "hidden"
          echo "visibility"
          return false
        if style.overflow is "hidden"
          top = @offsetTop e
          for p in @offsetParents e
            bottom = @offsetBottom p
            if bottom < top
              echo "overflow"
              return false
    #
    true

  # Filter out hidden elements.
  filterVisibleElements: (elements) ->
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

  # Return list of elements matching given XPath expression sorted by their position within the window.
  getElementList: (xPath) ->
    (e for e in @evaluateXPath xPath when 5 < e.offsetHeight).sort @byElementPosition

  # Compare two elements by their top position within the window.
  byElementPosition: (a,b) ->
    Dom.offsetTop(a) - Dom.offsetTop(b)

  # Return offset of the top of element vis-a-vis the top of the window.
  offsetTop: (element) ->
    ( e.offsetTop for e in @offsetParents element when e.offsetTop )
      .reduce Util.sum, 0

  # Return offset of the bottom of element vis-a-vis the top of the window.
  offsetBottom: (element) ->
    element.offsetHeight + @offsetTop element

  # Return both the offsets of the top and the bottom of element vis-a-vis the top of the window.
  offsetTopBottom: (element) ->
    offsetTop = @offsetTop element
    [ offsetTop, offsetTop + element.offsetHeight ]

  # Return list of element and all its parent nodes.
  # Return list of an element and all of its offset parents.
  parentNodes:   (element) -> Util.flatten element, (e) -> [ e, e.parentNode   ]
  offsetParents: (element) -> Util.flatten element, (e) -> [ e, e.offsetParent ]

  # Is the position of element fixed?
  isFixed: (element) ->
    "fixed" in ( window.getComputedStyle(e).position for e in @offsetParents element )

  # Return largest position of the bottom of a fixed banner.
  pageTopAdjustment: (xPath) ->
    ( @offsetBottom banner for banner in @evaluateXPath xPath when @isFixed banner )
      .reduce Util.max, 0

  # Call function "func" unless an input element is active.
  # WARNING: This operation is proxied in "hacks.coffee".
  doUnlessInputActive: (func) ->
    if document.activeElement.nodeName in Const.verboten
      return true # Propagate.
    #
    func()
    return false # Prevent propagation.

  getElementsByTagName: (element,tag, result=[]) ->
    result.push element if element.nodeName.toLowerCase() is tag
    @getElementsByTagName child, tag, result for child in element.children
    #
    result

