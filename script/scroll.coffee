
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
  #
  vanillaScrollStep:  70
  offset:             20
  #
  duration:           250
  durationScale:      6
  interval:           20
  #
  timer:              null

  scrolling:            -> @timer != null
  pageTop: (header)     -> window.pageYOffset + @offset + Dom.pageTopAdjustment header
  vanillaScroll: (move) -> @smoothScrollByDelta if move then move * @vanillaScrollStep else 0 - window.pageYOffset

  smoothScrollByDelta: do ->
    target = null
    #
    (delta) ->
      base =
        if @timer
          clearInterval @timer
          target
        else
          window.pageYOffset
      #
      target = base + delta
      offset = window.pageYOffset
      start  = Date.now()
      #
      @timer = Util.setInterval @interval, =>
        factor = (Date.now() - start) / @duration
        #
        if 1 <= factor
          clearInterval @timer
          @timer = null
          factor = 1
        #
        y = factor * delta + offset
        window.scrollBy 0, y - window.pageYOffset

  smoothScrollToElement: (element, header) ->
    @smoothScrollByDelta Dom.offsetTop(element) - @pageTop header

