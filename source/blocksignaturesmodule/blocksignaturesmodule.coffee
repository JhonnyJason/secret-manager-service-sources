############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("blocksignaturesmodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"

############################################################
timestampTimeFrameMS = 2400000
signatureBlockingTimeMS = 7200000

############################################################
blocked = {}

############################################################
export initialize = ->
    log "initialize"
    if cfg.validationTimeFrameMS? then timestampTimeFrameMS = cfg.validationTimeFrameMS
    signatureBlockingTimeMS = 3 * timestampTimeFrameMS
    return

############################################################
export assertAndBlock = (sig) ->
    log "assertAndBlock: "+sig
    if blocked[sig] then throw new Error("Multiple use of signature detected!")
    
    # do block!
    blocked[sig] = true
    
    unblock = -> 
        log "unblocking: "+sig
        delete blocked[sig] 
        return

    setTimeout(unblock, signatureBlockingTimeMS)
    olog blocked
    return

