
# ####################################################################
# Customisation for sites.

siteList = ""
siteListURL = chrome.extension.getURL "sites.txt"

# From: `https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest/Using_XMLHttpRequest`.
siteRequest = new XMLHttpRequest()
siteRequest.open 'GET', siteListURL, false
siteRequest.send()
if siteRequest.status is 200
  siteList =  siteRequest.responseText

# ####################################################################
# Build sites.

siteBuild = siteList.split   "\n"                         # split lines
siteBuild = siteBuild.map    (s) -> s.trim()              # trim whitespace
siteBuild = siteBuild.filter (s) -> 0 isnt s.indexOf("#") # strip comments
siteBuild = siteBuild.map    (s) -> s.split /\s+/         # parse
siteBuild = siteBuild.filter (s) -> s.length == 3         # filter out bogus-looking lines

sites = {}

for site in siteBuild
  [ host, pathname, xPath ] = site
  sites[host] ||= []
  sites[host].push
    pathname: pathname
    xPath:    xPath
    regexp:   new RegExp pathname

# ####################################################################
# Search.

lookupXPath = (host,pathname) ->
  if host? and pathname?
    if host of sites
      for page in sites[host]
        if page.regexp.test pathname
          return { xPath: page.xPath }
  return null

# ####################################################################
# Save and look up most recent @id for a page.

mkKey = (host,pathname) -> "#{host}#{pathname}"

saveID = (host, pathname, id) ->
  if host? and pathname? and id?
    localStorage[mkKey host, pathname] = id

lastID = (host,pathname) ->
  if host? and pathname?
    key = mkKey host, pathname
    if key of localStorage
      return { id: localStorage[key] }
  null

# ####################################################################
# Open URL in a new tab.
# Create tab to the left of the current tab.  That way we end up back on the current tab when the new tab is
# closed.
#
openURL = (url) ->
  if url? and 0 < url.length
    chrome.tabs.getSelected null, (tab) ->
      chrome.tabs.create { url: url, index: tab.index, selected: true }

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  switch request?.request
    when "lookup" then callback lookupXPath request?.host, request?.pathname
    when "saveID" then callback saveID      request?.host, request?.pathname, request?.id
    when "lastID" then callback lastID      request?.host, request?.pathname
    when "open"   then callback openURL     request?.url
    else callback null

