debugmodule = {name: "debugmodule"}

############################################################
debugmodule.initialize = () ->
    #console.log "debugmodule.initialize - nothing to do"
    return

############################################################
debugmodule.modulesToDebug = 
    unbreaker: true
    # configmodule: true
    # keyutilmodule: true
    # persistentstatemodule: true
    # scimodule: true
    # secrethandlermodule: true
    # secretstoremodule: true
    # securitymodule: true
    # securityprimitives: true
    # startupmodule: true
    # telegrambotmodule: true


export default debugmodule