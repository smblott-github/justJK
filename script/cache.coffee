
justJK = window.justJK ?= {}
#
Util   = justJK.Util
#
echo   = Util.echo

Cache = justJK.Cache =
  cache: {}
  count: 0

  clearCache: ->
    if 0 < @count
      @cache = {}
      @count = 0

  callCache: (id, func) ->
    if id of @cache
      echo "cache hit: #{id}"
      @cache[id]
    else
      echo "cache miss: #{id}"
      @cache[id] = func()
      @count += 1

watcher = (name) -> (mutation) -> Cache.clearCache()

for event in [ "DOMSubtreeModified", "DOMNodeInserted", "DOMNodeRemoved", "DOMNodeRemovedFromDocument", "DOMNodeInsertedIntoDocument", "DOMAttrModified" ]
  document.addEventListener event, watcher(event), true

