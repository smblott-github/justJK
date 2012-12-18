
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
    if href.length + 1 == window.location.href
      if stringStartsWith window.location.href, href
        if window.location.href.substring(href.length) is "#"
          score -= 1000
    #
    # Prefer internal/external links.
    switch config?.prefer
      when "internal"
        if 7 <= href.indexOf(window.location.host) <= 8
          score += 20
      #
      when "external"
        if not ( 7 <= href.indexOf(window.location.host) <= 8 )
          score += 20
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
        score += 15 if stringContains href, lk
    #
    if config?.dislike
      for dlk in config.dislike
        score -= 15 if stringContains href, dlk
    #
    # Dislike redirects.
    if stringContains href, "%3A%2F%2F" # == "://" URI encoded
      score -= 30
    #
    score

