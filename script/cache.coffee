
justJK   = window.justJK ?= {}
Util     = justJK.Util
echo     = Util.echo
jjkCache = "_justJK_EleCache__"

Cache = justJK.Cache =
  # DOM cache.
  #
  domCache: {}

  clearDomCache: ->
    @domCache = {}

  callDomCache: (id, func) ->
    if id of @domCache then @domCache[id] else @domCache[id] = func()

  listener: do ->
    clearer = (mutation) -> Cache.clearDomCache()
    #
    for event in [ "DOMSubtreeModified" ]
      do (event) -> document.addEventListener event, clearer, true

  # Element cache.
  #
  eleCacheStart: (func) ->
    return func() if @eleId
    @eleId = _.uniqueId "eleCache"
    Util.result func(), => @eleId = null

  eleCacheUse: (id,element,func) ->
    return func() unless element and @eleId
    #
    cache = element[jjkCache]
    unless cache and cache.eleId and cache.eleId is @eleId
      cache = element[jjkCache] = { eleId: @eleId }
    #
    return if id of cache then cache[id] else cache[id] = func()

