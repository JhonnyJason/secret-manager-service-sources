startupmodule = {name: "startupmodule"}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["startupmodule"]?  then console.log "[startupmodule]: " + arg
    return

############################################################
sci = null
bot = null

############################################################
startupmodule.initialize = () ->
    log "startupmodule.initialize"
    sci = allModules.scimodule
    bot = allModules.telegrambotmodule
    return


############################################################
startupmodule.serviceStartup = ->
    log "startupmodule.serviceStartup"
    sci.prepareAndExpose()
    return

export default startupmodule