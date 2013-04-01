
justJK           = window.justJK ?= {}
Util             = justJK.Util
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
    return -1000 if href is window.location.href
    #
    # Or if they differ only in a trailing "#".
    if 1 == Math.abs href.length - window.location.href.length
      do ->
        [ short, long ] = if href.length < window.location.href.length then [ href, window.location.href ] else [ window.location.href, href ]
        #
        if stringStartsWith long, short
          return -1000 if long[long.length-1..] is "#"
    #
    # Dislike mail links.
    if stringStartsWith href, 'mailto:'
      score -= 100
    #
    # Prefer internal/external links.
    do ->
      internal = ( 7 <= href.indexOf(window.location.host) <= 8 )
      external = not internal
      #
      switch config?.prefer
        when "internal"
          score += 20 if internal
          score -= 20 if external
        #
        when "external"
          score -= 20 if internal
          score += 20 if external
        #
        # Default to a small preference for external links.
        else
          score += 3 if external
    #
    do ->
      for like in ( config.like or [] )
        score += 15 if stringContains href, like
    #
    do ->
      for dislike in ( config.dislike or [] )
        score -= 15 if stringContains href, dislike
    #
    # Like redirects: they tend to go interesting places!
    do ->
      tail = href[1..]
      score = 5 if stringContains tail, "http://"
      score = 5 if stringContains tail, "https://"
      score = 5 if stringContains tail, "http%3A%2F%2F" # == "://" URI encoded
      score = 5 if stringContains tail, "https%3A%2F%2F" # == "://" URI encoded
    #
    score

