
justJK = window.justJK ?= {}
#
Util   = justJK.Util
#
stringContains   = Util.stringContains
stringStartsWith = Util.stringStartsWith

Score = justJK.Score =
  #
  scoreHRef: (like,dislike,href) ->
    score = 0
    #
    # Prefer URLs containing redirects; they are often the primary link.
    score += 4 if stringContains href, "%3A%2F%2" # == "://" URI encoded
    #
    # Prefer external links.
    score += 3 unless stringContains href, window.location.host
    #
    # Slightly prefer non-static looking links.
    score += 1 if stringContains href, "?"
    #
    if like
      for lk in like
        score += 2 if stringContains href, lk
    #
    if dislike
      for dlk in dislike
        score -= 2 if stringContains href, dlk
    #
    score

  compareHRef: (like,dislike) ->
    (a,b) ->
      aScore = Score.scoreHRef(like,dislike,a)
      bScore = Score.scoreHRef(like,dislike,b)
      #
      if aScore == bScore
        if stringStartsWith(a,b) or stringStartsWith b, a
          return a.length - b.length
      #
      aScore - bScore

