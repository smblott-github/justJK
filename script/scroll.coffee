
# ####################################################################
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#

justJK = window.justJK ?= {}
Dom = justJK.Dom

Scroll = justJK.Scroll = 
  #
  vanillaScrollStep:  70
  offset:             20
  #
  duration:           350
  durationScale:      6
  interval:           10
  #
  timer:              null

  scrolling:            -> @timer != null
  pageTop: (header)     -> window.pageYOffset + @offset + Dom.pageTopAdjustment header
  vanillaScroll: (move) -> @smoothScrollByDelta if move then move * @vanillaScrollStep else 0 - window.pageYOffset

  smoothScrollByDelta: (delta) ->
    offset = window.pageYOffset
    start  = Date.now()
    duration = @duration + @durationScale * Math.sqrt Math.abs delta
    #
    intervalFunc = =>
      factor = Math.sqrt Math.sqrt (Date.now() - start) / duration
      #
      if 1 <= factor
        clearInterval @timer
        @timer = null
        factor = 1
      #
      y = factor * delta + offset
      window.scrollBy 0, y - window.pageYOffset
    #
    clearInterval @timer if @timer
    @timer = setInterval intervalFunc, @interval

  smoothScrollToElement: (element, header) ->
    offSetTop = Dom.offsetTop element
    target    = offSetTop - ( @offset + Dom.pageTopAdjustment header )
    offset    = window.pageYOffset
    delta     = target - offset
    #
    @smoothScrollByDelta delta
    #
    element

