
justJK = window.justJK ?= {}
#
Util   = justJK.Util

Score = justJK.Score =
  #
  scoreHRef: (like,dislike,href) ->
    score = 0
    #
    # Prefer URLs containing redirects; they are often the primary link.
    score += 4 if Util.stringContains href, "%3A%2F%2" # == "://" URI encoded
    #
    # Prefer external links.
    score += 3 unless Util.stringContains href, window.location.host
    #
    # Slightly prefer non-static looking links.
    score += 1 if Util.stringContains href, "?"
    #
    if like
      for lk in like
        score += 2 if Util.stringContains href, lk
    #
    if dislike
      for dlk in dislike
        score -= 2 if Util.stringContains href, dlk
    #
    score

  compareHRef: (like,dislike) ->
    (a,b) ->
      Score.scoreHRef(like,dislike,a) - Score.scoreHRef(like,dislike,b)

