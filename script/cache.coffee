
justJK = window.justJK ?= {}
#
Util   = justJK.Util
#
echo   = Util.echo

jjkCache = "__someObscure-justJK-Nonsense_((=$$!_"

Cache = justJK.Cache =
  domCache: {}
  domCount: 0
  #
  eleCache: {}
  eleCount: 0
  eleStamp: null
  #
  eleHit:   0
  eleTot:   0
  eleHits:  {}
  #
  useDomCache: false
  useEleCache: true

  clearDomCache: ->
    if 0 < @domCount
      @domCache = {}
      @domCount = 0

  callCache: (id, func) ->
    #
    if not @useDomCache
      return func()
    #
    if id of @domCache
      @domCache[id]
    else
      @domCache[id] = func()
      @domCount += 1

  eleCacheStart: (func) ->
    if @eleCount++ == 0
      @eleStamp = Date.now()
    #
    func()
    #
    if --@eleCount == 0
      @eleStamp = null
      echo "*** #{@eleHit/@eleTot} #{@eleHit} of #{@eleTot}"
      for id of @eleHits
        echo "    #{@eleHits[id]} #{id}"
      @eleHit = @eleTot = 0
      @eleHits = {}

  eleCacheUse: (id,element,func) ->
    if element and @eleStamp
      @eleTot += 1
      element[jjkCache] = { stamp: "init" } unless element[jjkCache]
      #
      if element[jjkCache]?.stamp and element[jjkCache].stamp is @eleStamp
        # Cache valid.
        if element[jjkCache][id]?
          @eleHit += 1
          @eleHits[id] = 0 unless @eleHits[id]
          @eleHits[id] += 1
          return element[jjkCache][id]
      else
        # Cache invalid.
        element[jjkCache] = { stamp: @eleStamp }
      #
      return element[jjkCache][id] = func()
    #
    func()


# ################

if Cache.useDomCache
  watcher = (name) -> (mutation) -> Cache.clearDomCache()
  #
  for event in [ "DOMSubtreeModified", "DOMNodeInserted", "DOMNodeRemoved", "DOMNodeRemovedFromDocument", "DOMNodeInsertedIntoDocument", "DOMAttrModified" ]
    document.addEventListener event, watcher(event), true

