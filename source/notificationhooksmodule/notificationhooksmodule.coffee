############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("notificationhooksmodule")
#endregion

############################################################
import {randomBytes} from "crypto"
import * as cachedData from "cached-persistentstate"
import * as spaceManager from "./secretspacemanagermodule.js"

############################################################
notificationHooks = {}

############################################################
export initialize = ->
    log "initialize"
    #Implement or Remove :-)
    return

############################################################
createNewId = ->
    newId = randomBytes(16).toString("hex")
    while notificationHooks[newId]? 
        newId = randomBytes(16).toString("hex")
    return newId


############################################################
export createNew = (nodeId, type, targetId, notifyURL) ->
    log "createNew"
    id = createNewId()
    notificationHookObject = {id, nodeId, type, targetId, notifyURL}
    notificationHooks[id] = notificationHookObject
    ## TODO save somewhere
    return id


export addDetailsToIds = (ids) ->
    result = []
    for id in ids
        obj = notificationHooks[id]
        throw new Error('notificationHookId of "'+id+'" did not exist!') unless obj?
        type = obj.type
        url = obj.notifyURL
        error = obj.error
        result.push({id, type, url, error})
    return result

export remove = (id) ->
    log "remove"    
    obj = notificationHooks[id]
    throw new Error('notificationHookId of "'+id+'" did not exist!') unless obj?
    delete notificationHooks[id]
    ## TODO save somewhere
    return obj

############################################################
export notify = (ids, action) ->
    ##TODO implement
    # for id in ids
    return

############################################################
export notifyForRequest = (req) ->
    log "notifyForRequest"
    log req.path
    return

export initialCheck = (id) ->
    return