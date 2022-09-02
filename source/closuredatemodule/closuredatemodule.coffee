############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("closuredatemodule")
#endregion

############################################################
import  * as cfg from "./configmodule.js"

############################################################
intervalMS = 30000

# waiting

############################################################
export initialize = ->
    log "initialize"
    if cfg.closureHeartbeatIntervalMS? then intervalMS = cfg.closureHeartbeatIntervalMS 
    setInterval(closureHeartbeat, intervalMS)
    return

############################################################
closureHeartbeat = ->
    log "closureHeartbeat"
    now = Date.now()
    log "@"+now



export check = (spaceMeta) ->
    return true if !spaceMeta.closureDate?
    date = spaceMeta.closureDate
    now = Date.now()
    if date <= now then return false
    
    id = spaceMeta.id
    ## TODO save in the timers
    return true