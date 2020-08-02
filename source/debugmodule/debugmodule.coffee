debugmodule = {name: "debugmodule"}

############################################################
debugmodule.initialize = () ->
    #console.log "debugmodule.initialize - nothing to do"
    return

############################################################
debugmodule.modulesToDebug = 
    unbreaker: true
    # configmodule: true
    # persistentstatemodule: true
    scimodule: true
    secretstoremodule: true
    securitymodule: true
    # startupmodule: true


export default debugmodule