// Generated by CoffeeScript 1.4.0
(function() {
  var debug, lookupSite, sites, testRexExp;

  debug = false;

  sites = {
    "www.facebook.com": [
      {
        pathname: ".*",
        xPath: "//div[@id='contentArea']//li[contains(@class,'uiUnifiedStory')]"
      }
    ],
    "www.boards.ie": [
      {
        pathname: "^/vbulletin/forumdisplay.php\?",
        xPath: "//tbody/tr/td[contains(@id,'td_threadtitle')]"
      }
    ]
  };

  testRexExp = function(re, str) {
    return (new RegExp(re)).test(str);
  };

  lookupSite = function(host, pathname) {
    var page, _i, _len, _ref;
    if ((host != null) && (pathname != null)) {
      if (host in sites) {
        _ref = sites[host];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          page = _ref[_i];
          if (testRexExp(page.pathname, pathname)) {
            if (debug) {
              console.log("" + host + " " + pathname + " " + page.xPath);
            }
            return page.xPath;
          }
        }
      }
    }
    return null;
  };

  chrome.extension.onMessage.addListener(function(request, sender, callback) {
    var response;
    response = {
      xPath: lookupSite(request != null ? request.host : void 0, request != null ? request.pathname : void 0)
    };
    return callback(response);
  });

}).call(this);
