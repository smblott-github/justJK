
justJK = window.justJK ?= {}
#
Const  = justJK.Const

Parse = justJK.Parse =
  parse: ->
    siteListURL = chrome.extension.getURL "config.txt"

    # From: `https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest/Using_XMLHttpRequest`.
    siteRequest = new XMLHttpRequest()
    siteRequest.open 'GET', siteListURL, false
    siteRequest.send()
    siteList = if siteRequest.status is 200 then siteRequest.responseText else ""

    # ####################################################################
    # Parse sites.

    sites      = {}
    paths      = []
    directives = "site path elements header like dislike"
    directives = directives.trim().split /\s+/

    # Strip some whitespace, comments, empty lines and lines which don't seem to contain directives.
    #
    siteParse = ( s.trim() for s in siteList.split "\n"                            )
    siteParse = ( s        for s in siteParse when s.indexOf("#") isnt 0           )
    siteParse = ( s        for s in siteParse when s                               )
    siteParse = ( s        for s in siteParse when s.split(/\s+/)[0] in directives )

    # Rebuild site list.
    # Prepend blank line so that the split on "\nsite", below, works.
    #
    siteList  = "\n" + siteParse.join "\n"

    # Parse site list.
    #
    for site in (siteList.split "\nsite")[1..] # Skip bogus first entry.
      host      = null
      header    = null
      xPath     = []
      pathnames = []
      like      = []
      dislike   = []
      #
      site = ( line.trim() for line in site.split "\n" )
      #
      # Host, here, may be the empty string.
      [ host, site... ] = site
      #
      for line in site
        [ directive, line... ] = line.split /\s+/
        if line = line.join " "
          switch directive
            when "path"     then pathnames.push line
            when "elements" then xPath.push     line
            when "header"   then header =       line
            when "like"     then like.push      line
            when "dislike"  then dislike.push   line
      #
      xPath.push Const.nativeBindings unless xPath.length
      xPath = xPath.join "|"
      #
      if host
        pathnames.push "^/" if pathnames.length == 0
        #
        for p in pathnames
          for s in host.split /\s+/
            sites[s] ?= []
            sites[s].push
              path:    p
              regexp:  new RegExp p
              xPath:   xPath
              header:  header
              like:    like
              dislike: dislike
      else
        # No host.
        if xPath
          for p in pathnames
            paths.push
              path:    p
              regexp:  new RegExp p
              xPath:   xPath
              header:  header
              like:    like
              dislike: dislike

    #
    #
    [ sites, paths ]

