
# These functions proxy/replace their general definitions elsewhere,  They provide new implementations which
# handle known, site-specific issues, falling back to the general implementation as appropriate.

justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Dom    = justJK.Dom
Scroll = justJK.Scroll
Score  = justJK.Score
#
echo   = Util.echo

replaceValue = (obj,method,func) ->
  orig = obj[method]
  obj[method] = (args...) ->
    func (orig.apply obj, args), args

# With Facebook's native bindings, the active element is some "H5" object deep within the actual post.
# To find a link worth following, we must first got up the document tree a bit.
#
replaceValue Dom, "getActiveElement", (result, args) ->
  element = result
  #
  if window.location.host is "www.facebook.com"
    while element and element.nodeName.toLowerCase() isnt "li"
      element = element.parentNode
  #
  if element then element else result

# Vimium's search box is not an input element.  So, we shouldn't handle keys if the search box is active.
#
doUnlessInputActiveOrig = Dom.doUnlessInputActive

Dom.doUnlessInputActive = (args...) ->
  return doUnlessInputActiveOrig.apply Dom, args
  # Note: @/this here is Dom.
  if (@filterVisibleElements @getElementsByClassName "vimiumReset vimiumHUD").length
    return true # Propagate.
  #
  doUnlessInputActiveOrig.apply Dom, args

# Vimium's search box is not an input element.  So, we shouldn't handle keys if the search box is active.
#
vimiumFinderTimer = Util.setInterval 1000, ->
  true


