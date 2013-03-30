
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
    (config) ->
      window.pageYOffset + offset + Dom.pageTopAdjustment config

  vanillaScroll: do ->
    vanillaScrollStep = 60
    #
    (move) ->
      @smoothScrollByDelta (if move then move * vanillaScrollStep else 0 - window.pageYOffset), true

  scrollableThing: do ->
    # ???
    ->
      return window
      frames = Dom.getElementList "//iframe[@id='readable_iframe']"
      if frames.length == 1
        return frames[0]
      return window

  smoothScrollByDelta: do ->
    duration = 250
    interval = 20
    #
    timer    = null
    target   = null
    #
    (delta, accumulate, callback) ->
      # If delta is not defined, then just respond true/false to indicate whether we are currently scrolling
      # (or not).
      if not delta?
        return timer?
      #
      dur = duration
      int = interval
      win = Scroll.scrollableThing()
      #
      current =
        if timer
          clearInterval timer
          if accumulate then target else win.pageYOffset
        else
          win.pageYOffset
      #
      target = current + delta
      start  = Date.now()
      #
      timer = Util.setInterval int, =>
        factor = (Date.now() - start) / dur
        #
        if 1 <= factor
          callback() if callback
          clearInterval timer
          timer = null
          factor = 1
        #
        pos = current + factor * delta
        win.scrollBy 0, pos - win.pageYOffset

  smoothScrollToElement: (element, config) ->
    @smoothScrollByDelta (Dom.offsetTop(element) - @pageTop config), false, -> element.focus()

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

