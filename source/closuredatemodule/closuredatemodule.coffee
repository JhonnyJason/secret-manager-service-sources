############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("closuredatemodule")
#endregion


############################################################
import * as spaceManager from "./secretspacemanagermodule.js"
import * as cfg from "./configmodule.js"

############################################################
intervalMS = 30000

############################################################
closures = []
idHasClosure = {}

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
    while closures.length > 0 and closures[0].date < now
        toBeClosed = closures.shift()
        close(toBeClosed) 
    return

close = (toBeClosed) ->
    log "close"
    return unless idHasClosure[toBeClosed.id]
    idTokens = toBeClosed.id.split(".")
    if idTokens.length == 1 then return spaceManager.deleteSpaceFor(idTokens[0])
    if idTokens.length == 2 then return spaceManager.deleteSubSpaceFor(idTokens[0], idTokens[1])
    throw new Error("id of toBeClosed space was of unexpectedFormat!")
    return

addClosure = (toBeClosed) ->
    log "addClosure"
    idHasClosure[toBeClosed.id] = true
    if closures.length == 0 then closures.push(toBeClosed)
    else
        closures = []
        notYetPositioned = true
        for c in closures
            if notYetPositioned && c.date > toBeClosed.date
                closures.push(toBeClosed)
                notYetPositioned = false
            closures.push(c)
    return

# closureCompare = (el1, el2) -> el1.date - el2.date


############################################################
export check = (spaceMeta) ->
    return true if !spaceMeta.closureDate?
    date = spaceMeta.closureDate
    now = Date.now()
    if date <= now then return false    
    id = spaceMeta.id
    addClosure({date, id}) unless idHasClosure[id]
    return true