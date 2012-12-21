
# ####################################################################
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#

justJK = window.justJK ?= {}
#
Dom    = justJK.Dom
Util   = justJK.Util
#
echo   = Util.echo

Scroll = justJK.Scroll = 

  pageTop: do ->
    offset = 20
    #
    (header) ->
      window.pageYOffset + offset + Dom.pageTopAdjustment header

  vanillaScroll: do ->
    vanillaScrollStep = 60
    #
    (move) ->
      @smoothScrollByDelta (if move then move * vanillaScrollStep else 0 - window.pageYOffset), true

  smoothScrollByDelta: do ->
    duration = 250
    interval = 20
    #
    timer    = null
    target   = null
    #
    (delta, accumulate=false) ->
      current =
        if timer
          clearInterval timer
          if accumulate then target else window.pageYOffset
        else
          window.pageYOffset
      #
      target = current + delta
      start  = Date.now()
      #
      timer = Util.setInterval interval, =>
        factor = (Date.now() - start) / duration
        #
        if 1 <= factor
          clearInterval timer
          timer = null
          factor = 1
        #
        pos = current + factor * delta
        window.scrollBy 0, pos - window.pageYOffset

  smoothScrollToElement: (element, header) ->
    @smoothScrollByDelta Dom.offsetTop(element) - @pageTop header

