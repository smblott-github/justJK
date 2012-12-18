
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const

Parse = justJK.Parse =

  sites: (host) ->
    hosts = host.split /\s+/
    if Util.stringContains hosts[0], "."
      hosts
    else
      [ base, tlds... ] = hosts
      tlds = ( ( if Util.stringStartsWith tld, "." then tld else ".#{tld}" ) for tld in tlds )
      "#{base}#{tld}" for tld in tlds

  parse: ->
    siteListURL = chrome.extension.getURL "config.txt"

    # From: "https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest/Using_XMLHttpRequest".
    siteRequest = new XMLHttpRequest()
    siteRequest.open 'GET', siteListURL, false
    siteRequest.send()
    config = if siteRequest.status is 200 then siteRequest.responseText else ""

    # ####################################################################
    # Parse sites.

    sites      = {}
    paths      = []
    directives = "site path elements header like dislike prefer option".trim().split /\s+/

    # Strip some whitespace, comments, empty lines and lines which don't seem to contain directives, then
    # rebuild list.
    #
    config = "\n" + # This newline creates bogus entry, see below.
      _.chain( config.split "\n")
        #
        .map(    (s) -> s.trim() )
        .reject( (s) -> s.length is 0 or s[0] is "#" )
        .filter( (s) -> s.split(/\s+/)[0] in directives )
        #
        .value()
        .join("\n")

    proto = ->
      host      : null
      header    : null
      xPath     : []
      pathnames : []
      like      : []
      dislike   : []
      prefer    : "internal"
      options   : []
      #
      map:
        elements: "xPath"
        path: "pathnames"
      #
      install: (opt,val) ->
        opt = @map[opt] if @map[opt]
        #
        if _.isArray @[opt]
          @[opt].push val
        else
          @[opt] = val

    # Parse site list.
    #
    for site in (config.split "\nsite")[1..] # Skip bogus first entry.
      conf = proto()
      site = ( line.trim() for line in site.split "\n" )
      #
      # Host, here, may be the empty string.
      [ host, site... ] = site
      #
      for line in site
        [ directive, line... ] = line.split /\s+/
        conf.install directive, line.join " "
      #
      conf.xPath.push Const.nativeBindings unless conf.xPath.length
      conf.xPath = conf.xPath.join " | "
      #
      if host
        conf.pathnames.push "^/" unless conf.pathnames.length
        #
        for path in conf.pathnames
          entry = _.clone conf
          _.extend entry,
            path:    path
            regexp:  new RegExp path
          #
          for site in @sites host
            sites[site] ?= []
            sites[site].push entry
        #
      else
        # No host.
        for path in conf.pathnames
          entry = _.clone conf
          _.extend entry,
            path:    path
            regexp:  new RegExp path
          #
          paths.push entry
    #
    [ sites, paths ]

