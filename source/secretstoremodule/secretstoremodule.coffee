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
saveState = ->
    state.save("idToSpaceMap", idToSpaceMap)
    return

############################################################
#region exposedFunctions
secretstoremodule.addNodeId = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    return unless !idToSpaceMap[nodeId]?
    idToSpaceMap[nodeId] = {}
    saveState()
    return

secretstoremodule.getSecretSpace = (nodeId) -> idToSpaceMap[nodeId]

secretstoremodule.getSecret = (nodeId,secretId) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    return idToSpaceMap[nodeId][secretId]

secretstoremodule.setSecret = (nodeId,secretId,secret) ->
    throw new Error("unknown nodeId!") unless idToSpaceMap[nodeId]?
    idToSpaceMap[nodeId][secretId] = secret
    saveState()
    return

#endregion

module.exports = secretstoremodule