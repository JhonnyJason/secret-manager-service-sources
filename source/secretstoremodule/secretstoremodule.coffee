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

############################################################
secretstoremodule.initialize = () ->
    log "secretstoremodule.initialize"
    state = allModules.persistentstatemodule
    idToSpaceMap = state.load("idToSpaceMap")
    olog idToSpaceMap
    return

############################################################
#region internalFunctions
saveState = ->
    state.save("idToSpaceMap", idToSpaceMap)
    return

############################################################
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

############################################################
#region exposedFunctions
secretstoremodule.addNodeId = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    return unless !idToSpaceMap[nodeId]?
    idToSpaceMap[nodeId] = {}
    saveState()
    return

secretstoremodule.getSecretSpace = (nodeId) -> idToSpaceMap[nodeId]

secretstoremodule.getSecret = (nodeId, secretId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return getSharedSecret(node, secretId)
    else 
        throw new Error("secret does not exist!") unless node[secretId]?
        node = node[secretId]
        return node.secret

secretstoremodule.deleteSecret = (nodeId, secretId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return deleteSharedSecret(node, secretId)
    else delete node[secretId] if node[secretId]?
    saveState()
    return

secretstoremodule.getSharedTo = (nodeId, secretId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    node = idToSpaceMap[nodeId]
    if isShared(secretId) then return []
    else
        throw new Error("secret does not exist!") unless node[secretId]?
        node = node[secretId]
        return node.sharedTo

secretstoremodule.setSecret = (nodeId, secretId, secret) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    throw new Error("cannot set shared secret here!") if isShared(secretId)
    node = idToSpaceMap[nodeId]
    if !node[secretId]? then node[secretId] = {}
    node = node[secretId]
    if !node.sharedTo? then node.sharedTo = []
    node.secret = secret
    saveState()
    return

secretstoremodule.setSharedSecret = (nodeId, fromId, secretId, secret) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    node = idToSpaceMap[nodeId]
    throw new Error("no secrets accepted from fromId!") unless node[fromId]?
    node = node[fromId]
    node[secretId] = secret
    saveState()
    return

secretstoremodule.startAcceptingSecretsFrom = (nodeId, fromId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    node = idToSpaceMap[nodeId]
    return unless !node[fromId]?
    node[fromId] = {}
    saveState()
    return

secretstoremodule.stopAcceptingSecretsFrom = (nodeId, fromId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    node = idToSpaceMap[nodeId]
    return unless node[fromId]?
    delete node[fromId]
    saveState()
    return

secretstoremodule.startSharingSecretTo = (nodeId, shareToId, secretId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
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
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
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