configmodule = {name: "configmodule"}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["configmodule"]?  then console.log "[configmodule]: " + arg
    return

############################################################
configmodule.initialize = () ->
    log "configmodule.initialize"
    return

############################################################
configmodule.persistentStateRelativeBasePath = "../state"
configmodule.numberOfChachedEntries = 128

export default configmodule