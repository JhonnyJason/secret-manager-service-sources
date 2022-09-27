############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("closuredatemodule")
#endregion


############################################################
import * as notificationHandler from "./notificationhooksmodule.js"
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
    enIds = [] # execute notification Ids
    dnIds = [] # delete notification Ids
    event = "event onDelete"
    meta = {source: "closuredatemodule.close"}
    response = true

    idTokens = toBeClosed.id.split(".")
    try
        if idTokens.length == 1
            await spaceManager.deleteSpaceFor(idTokens[0], enIds, dnIds)
            p1 = notificationHandler.notifyForEvent(event, meta, enIds)
            p2 = notificationHandler.notifyForLogging(event, meta, enIds)
            await Promise.all([p1, p2])
            notificationHandler.remove(dnIds)
        else if idTokens.length == 2
            await spaceManager.deleteSubSpaceFor(idTokens[0], idTokens[1], enIds, dnIds)
            p1 = notificationHandler.notifyForEvent(event, meta, enIds)
            p2 = notificationHandler.notifyForLogging(event, meta, enIds)
            await Promise.all([p1, p2])
            notificationHandler.remove(dnIds)
        else throw new Error("id of toBeClosed space was of unexpectedFormat!")
    catch err then log "Error when trying to close #{toBeClosed.id} - #{err.message}"
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
export checkIfOpen = (spaceMeta) ->
    return true if !spaceMeta.closureDate?
    date = spaceMeta.closureDate
    now = Date.now()
    if date <= now then return false    
    id = spaceMeta.id
    addClosure({date, id}) unless idHasClosure[id]
    return true