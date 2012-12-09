
debug = false

# ####################################################################
# Customisation for sites.

sites =
  "www.facebook.com":
    [
      {
        pathname: ".*"
        xPath: "//div[@id='contentArea']//li[contains(@class,'uiUnifiedStory')]"
      }
    ]

  "www.boards.ie":
    [
      {
        pathname: "^/vbulletin/forumdisplay.php\?"
        xPath:    "//tbody/tr/td[contains(@id,'td_threadtitle')]"
      }
    ]

# ####################################################################
# Search.

testRexExp = (re,str) ->
  (new RegExp(re)).test str

lookupSite = (host,pathname) ->
  if host? and pathname?
    if host of sites
      for page in sites[host]
        if testRexExp page.pathname, pathname
          console.log "#{host} #{pathname} #{page.xPath}" if debug
          return page.xPath
  return null

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  response =
    xPath: lookupSite request?.host, request?.pathname
  callback response

