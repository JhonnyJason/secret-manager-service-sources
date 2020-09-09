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
test = ->
    return

############################################################
startupmodule.serviceStartup = ->
    log "startupmodule.serviceStartup"
    # test()
    sci.prepareAndExpose()
    return

export default startupmodule