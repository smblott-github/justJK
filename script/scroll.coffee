
# ####################################################################
# Adapted from: `http://codereview.stackexchange.com/questions/13111/smooth-page-scrolling-in-javascript`.
#

justJK = window.justJK ?= {}
Dom    = justJK.Dom
Util   = justJK.Util
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
      document.activeElement.blur() if document.activeElement
      @smoothScrollByDelta (if move then move * vanillaScrollStep else 0 - window.pageYOffset), true

  scrollableThing: ->
    return window
    # Broken.
    frames = Dom.getElementList "//iframe[@id='readable_iframe']"
    if frames.length == 1 then frames[0] else window

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
      return timer? if not delta?
      #
      dur     = duration
      int     = interval
      win     = Scroll.scrollableThing()
      current = win.pageYOffset
      #
      if timer
        clearInterval timer
        current = target if accumulate
      #
      target = current + delta
      start  = Date.now()
      #
      timer = Util.setInterval int, =>
        factor = (Date.now() - start) / dur
        #
        if 1 <= factor
          clearInterval timer
          timer  = null
          factor = 1
          callback() if callback
        #
        pos = current + factor * delta
        win.scrollBy 0, pos - win.pageYOffset

  smoothScrollToElement: (element, config) ->
    @smoothScrollByDelta (Dom.offsetTop(element) - @pageTop config), false, -> element.focus()

