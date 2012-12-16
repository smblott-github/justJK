
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

replace = (obj,method,func) ->
  orig = obj[method]
  unless orig
    echo "   ... does not exist!"
  obj[method] = (args...) ->
    func (orig.apply obj, args), args

# With Facebook's native bindings, the active element is some "H5" object deep within the actual post.
# To find a link worth following, we must first got up the document tree a bit.
#
replace Dom, "getActiveElement", (result, args) ->
  element = result
  #
  if window.location.host is "www.facebook.com"
    while element and element.nodeName.toLowerCase() isnt "li"
      element = element.parentNode
  #
  if element then element else result

# # Do not follow certain social networking links.
# #
# poorHRefs = [ "facebook.com/dialog", "twitter.com/share",  ]
# 
# replace Score, "scoreHRef", (score, args) ->
#   [ like, dislike, href ] = args
#   for str in poorHRefs
#     if Util.stringContains href, str
#       score -= 1000000
#   #
#   score

# Vimium's search box is not an input element.  So, we shouldn't handle keys if the search box is active.
#
doUnlessInputActiveOrig = Dom.doUnlessInputActive

Dom.doUnlessInputActive = (args...) ->
  # Note: @/this here is Dom.
  if (@filterVisibleElements @getElementsByClassName "vimiumReset vimiumHUD").length
    return true # Propagate.
  doUnlessInputActiveOrig.apply Dom, args

