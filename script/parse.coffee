
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const

Parse = justJK.Parse =

  # Xpath syntax for a tag (e.g. class) containg a token is archaic.
  # Instead, allow terms of the form "//div[HAS/class/something]" and replace
  # them with valid Xpath.
  #
  patch_xpath: do ->
    token  = "[-_a-zA-Z0-9]+"
    parser = new RegExp "(.*)HAS/(#{token})/(#{token})(.*)"
    (xPath) ->
      #
      if parse = parser.exec xPath
        [ _, prefix, tag, value, suffix ] = parse
        #
        archaic = "contains(concat(' ', @#{tag}, ' '), ' #{value} ')"
        Parse.patch_xpath prefix + archaic + suffix
      else
        xPath

  sites: (host) ->
    hosts = host.split /\s+/
    if Util.stringContains hosts[0], "."
      hosts
    else
      [ base, tlds... ] = hosts
      tlds = ( ( if Util.stringStartsWith tld, "." then tld else ".#{tld}" ) for tld in tlds )
      "#{base}#{tld}" for tld in tlds

  parse: ->
    #
    sites      = {}
    paths      = []
    directives = "site path elements header like dislike prefer option offset".trim().split /\s+/
    config     = Util.wget chrome.extension.getURL "config.txt"

    # Strip some whitespace, comments, empty lines and lines which don't seem to contain directives, then
    # rebuild config.
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

    # Prototype configuration.
    #
    proto = ->
      host      : null
      header    : []
      xPath     : []
      pathnames : []
      like      : []
      dislike   : []
      option    : []
      prefer    : "internal"
      offset    : "0"
      #
      map:
        elements: "xPath"
        path: "pathnames"
      #
      install: (opt,val) ->
        opt = @map[opt] if opt of @map
        #
        if _.isArray @[opt]
          @[opt].push val
        else
          @[opt] = val

    # Parse configuration.
    #
    for site in (config.split "\nsite")[1..] # Skip bogus first entry.
      [ host, site... ] = ( line.trim() for line in site.split "\n" )
      conf = proto()
      #
      for line in site
        [ directive, line... ] = line.split /\s+/
        conf.install directive, line.join " "
      #
      conf.header = conf.header.join(" | ")
      conf.xPath  = conf.xPath.join (" | ")
      conf.xPath  = Const.nativeBindings unless conf.xPath
      #
      conf.xPath  = Parse.patch_xpath conf.xPath
      conf.header = Parse.patch_xpath conf.header
      #
      conf.offset = parseInt conf.offset
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

