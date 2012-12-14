
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
    element = document.activeElement
    #
    switch window.location.host
      when "www.facebook.com"
        while element and element.nodeName isnt "LI"
          element = element.parentNode
        #
        return element if element
    #
    getActiveElementOrig.call Dom, args

