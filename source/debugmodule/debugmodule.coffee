debugmodule = {name: "debugmodule"}

############################################################
debugmodule.initialize = () ->
    #console.log "debugmodule.initialize - nothing to do"
    return

############################################################
debugmodule.modulesToDebug = 
    unbreaker: true
    # configmodule: true
    keyutilmodule: true
    # persistentstatemodule: true
    scimodule: true
    secretstoremodule: true
    securitymodule: true
    securityprimitives: true
    # securityprimitives: true
    # startupmodule: true


export default debugmodule