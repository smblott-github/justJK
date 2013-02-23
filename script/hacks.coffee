
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
_      = window._

# With Facebook's native bindings, the active element is some "H5" object deep within the actual post.
# To find a link worth following, we must first got up the document tree a bit.
#
Dom.getActiveElement = _.wrap (_.bindR Dom, Dom.getActiveElement),
  (func,args...) ->
    switch window.location.host
      when "www.facebook.com"
        element = active = func args...
        while element and element.nodeName.toLowerCase() isnt "li"
          element = element.parentNode
        #
        return element or active
        #
      else
        return func args...

# Vimium's search box is not an input element.  So, we shouldn't handle keys if the search box is active.
# Whether this is necessary depends upon the order in which chrome layers its extensions.
#
do ->
  vimiumElement = null
  #
  document.addEventListener "DOMNodeInsertedIntoDocument",
    (mutation) ->
      if not vimiumElement
        if className = mutation?.srcElement?.className
          if className is "vimiumReset vimiumHUD"
            vimiumElement = mutation.srcElement
    #
    true
  #
  Dom.doUnlessInputActive = _.wrap (_.bindR Dom, Dom.doUnlessInputActive),
    (func,args...) ->
      if vimiumElement
        if Dom.visible vimiumElement
          return true # Propagate.
      #
      switch window.location.host
        when "plus.google.com"
          active = document.activeElement
          if active.nodeName is 'DIV'
            if active.attributes.getNamedItem('g_editable')
              # May have to also check that it's true!
              return true # Propagate.
      #
      func args...

