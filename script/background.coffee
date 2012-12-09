
debug = false
debug = true

# ####################################################################
# Customisation for sites.
# Fields may not contain whitespace characters.

# DOMAIN           PATH                         XPath
# #                #                            #
siteList = """
  www.facebook.com ^/$                          //div[@id='contentArea']//li[contains(@class,'uiUnifiedStory')]
  plus.google.com  ^/$                          //div[starts-with(@id,'update-')]
  www.boards.ie    ^/vbulletin/forumdisplay.php //tbody/tr/td[starts-with(@id,'td_threadtitle')]
  www.boards.ie    ^/vbulletin/showthread.php   //div[@id='posts']//table[starts-with(@id,'post')]/tbody/tr/td[starts-with(@id,'td_post')]
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

lookupXPath = (host,pathname) ->
  if host? and pathname?
    if host of sites
      for page in sites[host]
        if page.regexp.test pathname
          console.log "hit #{host} #{pathname} #{page.xPath}" if debug
          response =
            xPath: page.xPath
          return response
  console.log "miss #{host} #{pathname}" if debug
  return null

# ####################################################################
# Save most recent @id.

saveID = (id, host, pathname) ->
  key = "#{host}#{pathname}"
  localStorage[key] = id
  console.log "#{id} <- #{key}" if debug
  null

lastID = (host,pathname) ->
  key = "#{host}#{pathname}"
  console.log "lastID: #{key}" if debug
  if key of localStorage
    console.log "lastID: #{key} hit #{localStorage[key]}" if debug
    response =
      id: localStorage[key]
  else
    null

# ####################################################################
# Listener.

chrome.extension.onMessage.addListener (request, sender, callback) ->
  switch request.request
    when "start" then  callback lookupXPath request?.host, request?.pathname
    when "saveID" then callback saveID request?.id, request?.host, request?.pathname
    when "lastID" then callback lastID request?.host, request?.pathname
    else
      callback null

