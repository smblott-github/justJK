
justJK = window.justJK ?= {}
#
Util   = justJK.Util
#
echo             = Util.echo
stringContains   = Util.stringContains
stringStartsWith = Util.stringStartsWith

Score = justJK.Score =
  #
  # WARNING: This operation is proxied in "hacks.coffee".
  scoreHRef: (config, href) ->
    score = 0
    #
    # Truly dislike the current URL.
    if href is window.location.href
      score -= 1000
    #
    # Or if they differ only in a trailing "#".
    if 1 == Math.abs href.length - window.location.href.length
      do ->
        [ short, long ] = if href.length < window.location.href.length then [ href, window.location.href ] else [ window.location.href, href ]
        #
        if stringStartsWith long, short
          score -= 1000 if long[long.length-1..] is "#"
    #
    # Prefer internal/external links.
    do ->
      internal = ( 7 <= href.indexOf(window.location.host) <= 8 )
      #
      switch config?.prefer
        when "internal"
          score += 20 if internal
        #
        when "external"
          score += 20 if not internal
        #
        # Default to a small preference for external links.
        else
          score += 3 if not internal
    #
    # # Slightly prefer non-static looking links.
    # # Don't do this.  It picks some twitter links.
    # score += 1 if stringContains href, "?"
    #
    for lk in ( config.like or [] )
      score += 15 if stringContains href, lk
    #
    for dlk in ( config.dislike or [] )
      score -= 15 if stringContains href, dlk
    #
    # Dislike things which look like redirects.
    score -= 30 if stringContains href, "%3A%2F%2F" # == "://" URI encoded
    #
    score

