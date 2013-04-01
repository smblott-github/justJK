
justJK = window.justJK ?= {}
#
Util   = justJK.Util
Const  = justJK.Const
Parse  = justJK.Parse
#
echo   = Util.echo
_      = window._

[ sites, paths ] = Parse.parse()

# ####################################################################
# Lookup configuration.
#
# www.google.co.uk ->
#   www.google.co.uk, google.co.uk, co.uk, uk
#
config = do ->
  prefixes = (host) ->
    parts = host.split "."
    parts[i..].join "." for i in [0...parts.length-1]

  (host,pathname) ->
    # Check host.
    if host and pathname
      for hst in prefixes host
        if hst of sites
          for conf in sites[hst]
            if conf.regexp.test pathname
              return conf
    # Check pathname.
    for conf in paths
      if conf.regexp.test pathname
        return conf
    return { xPath: Const.simpleBindings }

# ####################################################################
# Open URL in a new tab.
# Create tab to the left of the current tab.  That way we end up back on the current tab when the new tab is
# closed.
#
open = (url) ->
  if url
    chrome.tabs.getSelected null, (tab) ->
      chrome.tabs.create { url: url, index: tab.index, selected: true }

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  switch request?.request
    when "config" then callback config request?.host, request?.pathname
    when "open"   then callback open   request?.url
    else callback null

    # when "saveID" then callback saveID  request?.host, request?.pathname, request?.id
    # when "lastID" then callback lastID  request?.host, request?.pathname
