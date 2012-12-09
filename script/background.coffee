
debug = false

# ####################################################################
# Customisation for sites.
# Fields may not contain whitespace characters.

# DOMAIN           PATH                         XPath
# #                #                            #
siteList = """
  www.facebook.com .*                           //div[@id='contentArea']//li[contains(@class,'uiUnifiedStory')]
  www.boards.ie    ^/vbulletin/forumdisplay.php //tbody/tr/td[contains(@id,'td_threadtitle')]
  """
# #                #                            #
# DOMAIN           PATH                         XPath

# ####################################################################
# Build sites.

siteBuild = siteList.split "\n"                    # split lines
siteBuild = siteBuild.map (s) -> s.trim()          # trim whitespace
siteBuild = siteBuild.map (s) -> s.split /\s+/     # parse
siteBuild = siteBuild.filter (s) -> s.length == 3  # filter out bogus-looking lines

sites = {}

for site in siteBuild
  [ host, pathname, xPath ] = site
  sites[host] ||= []
  sites[host].push
    pathname: pathname
    regexp:   new RegExp pathname
    xPath:    xPath

# ####################################################################
# Search.

lookupSite = (host,pathname) ->
  if host? and pathname?
    if host of sites
      for page in sites[host]
        if page.regexp.test pathname
          console.log "#{host} #{pathname} #{page.xPath}" if debug
          return page.xPath
  return null

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  response =
    xPath: lookupSite request?.host, request?.pathname
  callback response

