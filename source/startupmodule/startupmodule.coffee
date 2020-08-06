startupmodule = {name: "startupmodule"}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["startupmodule"]?  then console.log "[startupmodule]: " + arg
    return

############################################################
sci = null

############################################################
startupmodule.initialize = () ->
    log "startupmodule.initialize"
    sci = allModules.scimodule
    return

############################################################
startupmodule.serviceStartup = ->
    log "startupmodule.serviceStartup"
    await allModules.securitymodule.test()
    process.exit(0)

    sci.prepareAndExpose()
    
    return

export default startupmodule