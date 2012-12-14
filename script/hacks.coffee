
# These functions proxy/replace their general definitions elsewhere,  They provide new implementations which
# handle known, site-specific issues, falling back to the general implementation for other cases.

justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Dom    = justJK.Dom
Scroll = justJK.Scroll
Score  = justJK.Score
#
echo   = Util.echo

# With Facebook's native bindings, the active element is some "H5" object deep within the actual post.
# To find a link worth following, we must first got up the document tree a bit.
#
getActiveElementOrig = Dom.getActiveElement

Dom.getActiveElement = (args...) ->
    element = getActiveElementOrig.apply Dom, args
    #
    if window.location.host is "www.facebook.com"
      while element and element.nodeName isnt "LI"
        element = element.parentNode
      #
      return element if element
    #
    getActiveElementOrig.apply Dom, args

# Vimium's search box is not an input element.  So, we shouldn't handle keys if the search box is active.
#
doUnlessInputActiveOrig = Dom.doUnlessInputActive

Dom.doUnlessInputActive = (args...) ->
  # Note: @/this here is Dom.
  if (@filterVisibleElements @getElementsByClassName "vimiumReset vimiumHUD").length
    return true # Propagate.
  doUnlessInputActiveOrig.apply Dom, args

