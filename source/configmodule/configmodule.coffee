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
configmodule.telegramToken = "1386909865:AAEt52CzdgbfExKyO1XXGPNPTeCso2ohCPY"
configmodule.persistentStateRelativeBasePath = "../state"

export default configmodule