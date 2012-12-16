
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
    # Prefer internal/external links.
    switch config?.prefer
      when "internal"
        if stringContains href, window.location.host
          score += 20
      #
      when "external"
        if not stringContains href, window.location.host
          score += 20
        # else
        #   score += 20 if stringContains href, "%3A%2F%2" # == "://" URI encoded
      #
      # Default to a small preference for external links.
      else
        if not stringContains href, window.location.host
          score += 3 
    #
    # Slightly prefer non-static looking links.
    score += 1 if stringContains href, "?"
    #
    if config?.like
      for lk in config.like
        score += 2 if stringContains href, lk
    #
    if config?.dislike
      for dlk in config.dislike
        score -= 2 if stringContains href, dlk
    #
    score

  # scoreAnchor: (config,anchor) ->
  #   ( @scoreHRef(config,a) for a in @extractHRefs anchor ).reduce Util.max, -1000

  compareHRef: (config) -> (a,b) ->
    aScore = Score.scoreHRef config, a
    bScore = Score.scoreHRef config, b
    #
    if aScore == bScore
      if stringStartsWith(a,b) or stringStartsWith b, a
        return a.length - b.length
    #
    aScore - bScore

