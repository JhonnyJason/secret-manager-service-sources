############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authcodemodule")
#endregion

############################################################
export initialize = ->
    log "initialize"
    #Implement or Remove :-)
    return

############################################################
export assertActionIsLegal = (action, authCode) ->
    log "assertActionIsLegal"
    log "Not implemented yet!"
    ## TODO implement
    return 

############################################################
export getOwner = (owner) ->
    log "getOwner"
    log "Not implemented yet!"
    ## TOOD implement
    return ""
