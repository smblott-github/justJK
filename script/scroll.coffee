
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
      # If delta is not defined, then just respond true/false to indicate whether we are currently scrolling
      # (or not).
      if not delta?
        return timer?
      #
      dur = duration
      int = interval
      #
      # Partial idea .... currently no-op.
      if typeof accumulate is 'number'
        dur = duration
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
      timer = Util.setInterval int, =>
        factor = (Date.now() - start) / dur
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

  autoscroll: do ->
    base  = 400
    scale = 0.7
    rate  = null
    timer = null
    stamp = null
    #
    (faster) ->
      clearInterval timer if timer
      echo faster
      #
      if faster
        rate = if not rate then base else Math.floor rate * scale
        timer = Util.setInterval rate, -> window.scrollBy 0, 2
      #
      else
        rate = if not rate then base else Math.floor rate / scale
        #
        return timer = rate = stamp = null if base <= rate
        return timer = rate = stamp = null if stamp and Date.now() - stamp < 300
        return timer = rate = stamp = null if document.body.offsetHeight <= window.pageYOffset + window.innerHeight
        #
        stamp = Date.now()
        timer = Util.setInterval rate, -> window.scrollBy 0, 1

