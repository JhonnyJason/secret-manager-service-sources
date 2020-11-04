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
state = null

############################################################
idToSpaceMap = {}
cachedIds = []
maxCacheSize = 0

############################################################
secretstoremodule.initialize = () ->
    log "secretstoremodule.initialize"
    state = allModules.persistentstatemodule
    c = allModules.configmodule
    maxCacheSize = c.numberOfChachedEntries

    idToSpaceMap = state.load("idToSpaceMap")
    assertCleanCachedState()
    printState()
    return

############################################################
#region internalFunctions
printState = ->
    log "printState"
    olog idToSpaceMap
    olog cachedIds
    log " - - - "
    return

processUnexpected = (err) -> throw err

############################################################
#region caching helpers
assertCleanCachedState = ->
    allIds = Object.keys(idToSpaceMap)
    if cachedIds.length == 0
        for id in allIds
            if cachedIds.length == maxCacheSize
                if idToSpaceMap[id] != 1 then removeFromCache(id)
            else if idToSpaceMap[id] != 1
                cachedIds.push(id)
                state.save(id, idToSpaceMap[id])
    ## else TODO or maybe not relevant if it is only used on initialize        
    saveState()
    return

assertIdIsAvailable = (id) ->
    throw new Error("No nodeId provided!") unless id
    throw new Error("unknown nodeId!") unless idToSpaceMap[id]?
    if idToSpaceMap[id] == 1 then loadIntoCache(id)
    return

addNewEntry = (id) ->
    log "addNewEntry: "+id
    idToSpaceMap[id] = {}
    state.save(id, idToSpaceMap[id])
    cachedIds.push(id)
    cacheRemoveExcess()
    printState()
    return

loadIntoCache = (id) ->
    log "loadIntoCache: "+id
    return unless idToSpaceMap[id]?
    index = cachedIds.indexOf(id)
    if index > 0 then cachedIds.splice(index, 1)
    idToSpaceMap[id] = state.load(id)
    cachedIds.push(id)
    cacheRemoveExcess()
    printState()
    return

removeFromCache = (id) ->
    log "removeFromCache: "+id
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
    throw new Error("secret does not exist!") unless node[restKey]?
    return node[restKey]

deleteSharedSecret = (node, secretId) ->
    fromKey = secretId.slice(0,64)
    throw new Error("no secret from fromId!") unless node[fromKey]?
    node = node[fromKey]
    restKey = secretId.slice(65)
    delete node[restKey]
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

############################################################
secretstoremodule.getSecretSpace = (nodeId) -> 
    throw new Error("No nodeId provided!") unless nodeId
    if idToSpaceMap[nodeId] == 1 then loadIntoCache(nodeId)
    return idToSpaceMap[nodeId]

secretstoremodule.getSecret = (nodeId, secretId) ->
    assertIdIsAvailable(nodeId)
    throw new Error("No secretId provided!") unless secretId?
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return getSharedSecret(node, secretId)
    else
        throw new Error("secret does not exist!") unless node[secretId]?
        node = node[secretId]
        return node.secret

############################################################
secretstoremodule.setSecret = (nodeId, secretId, secret) ->
    assertIdIsAvailable(nodeId)
    throw new Error("No secretId provided!") unless secretId?
    throw new Error("cannot set shared secret here!") if isShared(secretId)
    node = idToSpaceMap[nodeId]
    if !node[secretId]? then node[secretId] = {}
    node = node[secretId]
    node.secret = secret
    saveState()
    return

secretstoremodule.deleteSecret = (nodeId, secretId) ->
    assertIdIsAvailable(nodeId)
    throw new Error("No secretId provided!") unless secretId?
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return deleteSharedSecret(node, secretId)
    else delete node[secretId] if node[secretId]?
    saveState()
    return

############################################################
secretstoremodule.addSubSpaceFor = (nodeId, fromId) ->
    assertIdIsAvailable(nodeId)
    throw new Error("No fromId provided!") unless fromId?

    node = idToSpaceMap[nodeId]
    return unless !node[fromId]?
    node[fromId] = {}
    saveState()
    return

secretstoremodule.removeSubSpaceFor = (nodeId, fromId) ->
    assertIdIsAvailable(nodeId)
    throw new Error("No fromId provided!") unless fromId?

    node = idToSpaceMap[nodeId]
    return unless node[fromId]?
    delete node[fromId]
    saveState()
    return

############################################################
secretstoremodule.setSharedSecret = (nodeId, fromId, secretId, secret) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    throw new Error("no secrets accepted from fromId!") unless node[fromId]?
    node = node[fromId]
    node[secretId] = secret
    saveState()
    return

secretstoremodule.deleteSharedSecret = (nodeId, fromId, secretId) ->
    assertIdIsAvailable(nodeId)
    node = idToSpaceMap[nodeId]
    throw new Error("no secrets accepted from fromId!") unless node[fromId]?
    node = node[fromId]
    delete node[secretId]
    saveState()
    return

#endregion

module.exports = secretstoremodule