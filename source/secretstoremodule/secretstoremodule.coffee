secretstoremodule = {name: "secretstoremodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["secretstoremodule"]?  then console.log "[secretstoremodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
bot = null
state = null

############################################################
idToSpaceMap = {}
cachedIds = []
maxCacheSize = 0

############################################################
secretstoremodule.initialize = () ->
    log "secretstoremodule.initialize"
    bot = allModules.telegrambotmodule
    state = allModules.persistentstatemodule
    c = allModules.configmodule
    maxCacheSize = c.numberOfCachedEntries

    idToSpaceMap = state.load("idToSpaceMap")
    log "maxCacheSize: "+maxCacheSize
    log "cachedIds.length: "+cachedIds.length
    assertCleanCachedState()
    olog idToSpaceMap
    olog cachedIds
    return

############################################################
#region internalFunctions
processUnexpected = (err) ->
    # bot.send err
    throw err

############################################################
#region caching helpers
assertCleanCachedState = ->
    log "assertCleanCachedState"
    allIds = Object.keys(idToSpaceMap)
    olog allIds
    log " - - - "
    if cachedIds.length == 0
        for id in allIds
            log "checking id: " + id
            if cachedIds.length == maxCacheSize
                log "we have reached maxCacheSize already - should be removed from cache!"
                if idToSpaceMap[id] != 1 then removeFromCache(id)
            else if idToSpaceMap[id] != 1
                log "did not reach maxCacheSize yet..."
                cachedIds.push(id)
                state.save(id, idToSpaceMap[id])
            log " - - - "
    ## else TODO or maybe not relevant if it is only used on initialize        
    return

assertIdIsAvailable = (id) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[id]?
    if idToSpaceMap[id] == 1 then loadIntoCache(id)
    return

addNewEntry = (id) ->
    log "addNewEntry"
    idToSpaceMap[id] = {}
    state.save(id, idToSpaceMap[id])
    cachedIds.push(id)
    cacheRemoveExcess()
    return

loadIntoCache = (id) ->
    log "loadIntoCache"
    return unless !idToSpaceMap[id]?
    index = cachedIds.indexOf(id)
    if index > 0 then cachedIds.splice(index, 1)
    idToSpaceMap[id] = state.load(id)
    cachedIds.push(id)
    cacheRemoveExcess()
    return

removeFromCache = (id) ->
    log "removeFromCache"
    if !idToSpaceMap[id]? then throw new Error("Id to removeFromCache does not exist!")
    state.save(id, idToSpaceMap[id])
    state.uncache(id)
    idToSpaceMap[id] = 1
    return

cacheRemoveExcess = ->
    excess = cachedIds.length - maxCacheSize
    return if excess <= 0
    while excess--
        id = cachedIds.shift()
        removeFromCache(id)
    return

saveState = ->
    try state.save("idToSpaceMap", idToSpaceMap)
    catch err then processUnexpected err
    return

#endregion

############################################################
#region secret sharing helpers
isShared = (id) ->
    if id.length < 65 then return false
    if id.charAt(64) != "." then return false
    return true

getSharedSecret = (node, secretId) ->
    fromKey = secretId.slice(0,64)
    throw new Error("no secret from fromId!") unless node[fromKey]?
    node = node[fromKey]
    restKey = secretId.slice(65)
    return node[restKey]

deleteSharedSecret = (node, secretId) ->
    fromKey = secretId.slice(0,64)
    throw new Error("no secret from fromId!") unless node[fromKey]?
    node = node[fromKey]
    restKey = secretId.slice(65)
    delete node[restKey]
    return 

addToArray = (array, element) ->
    for el in array when el == element then return
    array.push element
    return

removeFromArray = (array, element) ->
    for el,i in array when el == element 
        array[i] = array[array.length - 1]
        array.pop()
        return
    return

#endregion

#endregion

############################################################
#region exposedFunctions
secretstoremodule.addNodeId = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    return unless !idToSpaceMap[nodeId]?
    addNewEntry(nodeId)
    saveState()
    return

secretstoremodule.getSecretSpace = (nodeId) -> 
    if idToSpaceMap[nodeId] == 1 then loadIntoCache(nodeId)
    return idToSpaceMap[nodeId]

secretstoremodule.getSecret = (nodeId, secretId) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return getSharedSecret(node, secretId)
    else 
        throw new Error("secret does not exist!") unless node[secretId]?
        node = node[secretId]
        return node.secret

secretstoremodule.deleteSecret = (nodeId, secretId) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return deleteSharedSecret(node, secretId)
    else delete node[secretId] if node[secretId]?
    saveState()
    return

secretstoremodule.getSharedTo = (nodeId, secretId) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return []
    else
        throw new Error("secret does not exist!") unless node[secretId]?
        node = node[secretId]
        return node.sharedTo

secretstoremodule.setSecret = (nodeId, secretId, secret) ->
    assertIdIsAvailable(nodeId)
    throw new Error("cannot set shared secret here!") if isShared(secretId)
    node = idToSpaceMap[nodeId]
    if !node[secretId]? then node[secretId] = {}
    node = node[secretId]
    if !node.sharedTo? then node.sharedTo = []
    node.secret = secret
    saveState()
    return

secretstoremodule.setSharedSecret = (nodeId, fromId, secretId, secret) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    throw new Error("no secrets accepted from fromId!") unless node[fromId]?
    node = node[fromId]
    node[secretId] = secret
    saveState()
    return

secretstoremodule.startAcceptingSecretsFrom = (nodeId, fromId) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    return unless !node[fromId]?
    node[fromId] = {}
    saveState()
    return

secretstoremodule.stopAcceptingSecretsFrom = (nodeId, fromId) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    return unless node[fromId]?
    delete node[fromId]
    saveState()
    return

secretstoremodule.startSharingSecretTo = (nodeId, shareToId, secretId) ->
    assertIdIsAvailable(nodeId)
    throw new Error("cannot start sharing shared secret here!") if isShared(secretId)
    node = idToSpaceMap[nodeId]
    if !node[secretId]? then node[secretId] = {}
    node = node[secretId]
    if !node.sharedTo? then node.sharedTo = []
    if !node.secret? then node.secret = ""
    addToArray(node.sharedTo, shareToId)
    saveState()
    return

secretstoremodule.stopSharingSecretTo = (nodeId, sharedToId, secretId) ->
    assertIdIsAvailable(nodeId)
    throw new Error("cannot stop sharing a shared secret here!") if isShared(secretId)
    node = idToSpaceMap[nodeId]
    if !node[secretId]? then return
    node = node[secretId]
    if node.sharedTo? and node.sharedTo.length 
        removeFromArray(node.sharedTo, sharedToId)
        saveState()
    return

#endregion

module.exports = secretstoremodule