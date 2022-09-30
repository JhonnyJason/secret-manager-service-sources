############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("closuredatemodule")
#endregion


############################################################
import * as notificationHandler from "./notificationhooksmodule.js"
import * as serviceCrypto from "./servicekeysmodule.js"
import * as spaceManager from "./secretspacemanagermodule.js"
import * as dataCache from "cached-persistentstate"
import * as cfg from "./configmodule.js"

############################################################
intervalMS = 30000

############################################################
closureStore = null
closures = null
idHasClosure = null

############################################################
export initialize = ->
    log "initialize"
    closureStore = dataCache.load("closureStore")
    if closureStore.meta? then await validateClosureStore()
    else
        closureStore.meta = {}
        closureStore.closures = []
        closureStore.idHasClosure = {}
    closures = closureStore.closures
    idHasClosure = closureStore.idHasClosure

    if cfg.closureHeartbeatIntervalMS? then intervalMS = cfg.closureHeartbeatIntervalMS 
    setInterval(closureHeartbeat, intervalMS)
    return

############################################################
validateClosureStore = ->
    log "validateClosureStore"
    meta = closureStore.meta
    signature = meta.serverSig
    if !signature then throw new Error("No signature in closureStore.meta !")
    meta.serverSig = ""
    jsonString = JSON.stringify(closureStore)
    meta.serverSig = signature
    if(await serviceCrypto.verify(signature, jsonString)) then return
    else throw new Error("Invalid Signature in closureStore.meta !")

signAndSaveClosureStore = ->
    log "signAndSaveClosureStore"
    closureStore.meta.serverSig = ""
    closureStore.meta.serverPub = serviceCrypto.getPublicKeyHex()
    jsonString = JSON.stringify(closureStore)
    signature = await serviceCrypto.sign(jsonString)
    closureStore.meta.serverSig = signature
    dataCache.save("closureStore")
    return


############################################################
closureHeartbeat = ->
    log "closureHeartbeat"
    now = Date.now()
    log "@"+now
    olog closures
    lengthBefore = closures.length
    while closures.length > 0 and closures[0].date <= now
        toBeClosed = closures.shift()
        close(toBeClosed)
    lengthAfter = closures.length
    if lengthAfter != lengthBefore then signAndSaveClosureStore()
    return

close = (toBeClosed) ->
    log "close"
    return unless idHasClosure[toBeClosed.id]
    delete idHasClosure[toBeClosed.id] 
    enIds = [] # execute closure Ids
    dnIds = [] # delete closure Ids
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
    # olog closures
    idHasClosure[toBeClosed.id] = true
    if closures.length == 0 then closures.push(toBeClosed)
    else
        newClosures = []
        notYetPositioned = true
        for c in closures
            if notYetPositioned && c.date > toBeClosed.date
                newClosures.push(toBeClosed)
                notYetPositioned = false
            newClosures.push(c)
        if notYetPositioned then newClosures.push(toBeClosed)
        closures = newClosures
        closureStore.closures = closures
    # log "- - - -  after adding closure - - - - "
    # olog closures
    signAndSaveClosureStore()
    return

# closureCompare = (el1, el2) -> el1.date - el2.date


############################################################
export checkIfOpen = (spaceMeta) ->
    return true if !spaceMeta.closureDate?
    date = spaceMeta.closureDate
    now = Date.now()
    if date <= now
        closureHeartbeat()
        return false    
    id = spaceMeta.id
    addClosure({date, id}) unless idHasClosure[id]
    return true
    