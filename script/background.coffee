
justJK = window.justJK ?= {}
#
Const  = justJK.Const

# ####################################################################
# Customisation.

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
directives = [ "site", "path", "elements", "header", "like", "dislike" ]

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
    sites[host] ?= []
    pathnames.push "^/" if pathnames.length == 0
    #
    for p in pathnames
      sites[host].push
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

# ####################################################################
# Lookup configuration.

config = (host,pathname) ->
  if host and pathname
    if host of sites
      for page in sites[host]
        if page.regexp.test pathname
          return page
  for path in paths
    if path.regexp.test pathname
      return path
  return { xPath: Const.simpleBindings }

# ####################################################################
# Save and look up most recent @id for a page.

mkKey = (host,pathname) -> "#{host}#{pathname}"

saveID = (host, pathname, id) ->
  if host and pathname
    key = mkKey host, pathname
    console.log "#{id} <- #{key}"
    localStorage[key] = id
  null

lastID = (host,pathname) ->
  # If the selected element does not have an id, then id here will be null.  It must neverthe less be recorded
  # ... so that we don't later jump back to a previous element which *did* have an id.
  if host and pathname
    key = mkKey host, pathname
    if key of localStorage
      id = localStorage[key]
      console.log "#{id} -> #{key}"
      return { id: id }
  null

# ####################################################################
# Open URL in a new tab.
# Create tab to the left of the current tab.  That way we end up back on the current tab when the new tab is
# closed.
#
open = (url) ->
  if url
    console.log url
    chrome.tabs.getSelected null, (tab) ->
      chrome.tabs.create { url: url, index: tab.index, selected: true }

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  switch request?.request
    when "config" then callback config  request?.host, request?.pathname
    when "saveID" then callback saveID  request?.host, request?.pathname, request?.id
    when "lastID" then callback lastID  request?.host, request?.pathname
    when "open"   then callback open    request?.url
    else callback null

