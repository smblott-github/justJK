
# ####################################################################
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#

window.justJK ?= {}
justJK = window.justJK

Util = justJK.Util
Dom  = justJK.Dom

Scroll = justJK.Scroll =
  vanillaScrollStep:  70
  duration: 400
  offset: 20
  timer: null

  smoothScrollByDelta: (delta) ->
    offset = window.pageYOffset
    start  = Date.now()
    #
    intervalFunc = =>
      factor = Math.sqrt Math.sqrt (Date.now() - start) / @duration
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
    @timer = setInterval intervalFunc, 10

  smoothScrollToElement: (element, header) ->
    offSetTop = Dom.offsetTop element
    target    = Math.max 0, offSetTop - ( @offset + Dom.offsetAdjustment header )
    offset    = window.pageYOffset
    delta     = target - offset
    #
    @smoothScrollByDelta delta
    #
    element

  vanillaScroll: (move) ->
    position = window.pageYOffset / @vanillaScrollStep
    newPosition = if move then position + move else 0
    @smoothScrollByDelta (newPosition - position) * @vanillaScrollStep
    return true # Do not propagate.
