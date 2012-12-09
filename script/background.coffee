
debug = false

# ####################################################################
# Customisation for sites.

siteList = """
  www.facebook.com .*                           //div[@id='contentArea']//li[contains(@class,'uiUnifiedStory')]
  www.boards.ie    ^/vbulletin/forumdisplay.php //tbody/tr/td[contains(@id,'td_threadtitle')]
  """

# ####################################################################
# Build sites.

siteBuild = siteList.split "\n"
siteBuild = siteBuild.map (s) -> s.trim()
siteBuild = siteBuild.map (s) -> s.split /\s+/
siteBuild = siteBuild.filter (s) -> s.length == 3

sites = {}

for site in siteBuild
  [ host, pathname, xPath ] = site
  sites[host] ||= []
  sites[host].push
    pathname: pathname
    xPath:    xPath

# ####################################################################
# Prebuild RegExps.

for site of sites
  for page in sites[site]
    page.regexp = new RegExp page.pathname if page.pathname

# ####################################################################
# Search.

lookupSite = (host,pathname) ->
  if host? and pathname?
    if host of sites
      for page in sites[host]
        if page.regexp and page.regexp.test pathname
          console.log "#{host} #{pathname} #{page.xPath}" if debug
          return page.xPath
  return null

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  response =
    xPath: lookupSite request?.host, request?.pathname
  callback response

