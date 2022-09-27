############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("notificationhooksmodule")
#endregion

############################################################
import { randomBytes } from "crypto"
import { postData } from "thingy-network-base"
############################################################
import * as dataCache from "cached-persistentstate"
import * as spaceManager from "./secretspacemanagermodule.js"
import * as serviceCrypto from "./servicekeysmodule.js"

############################################################
notificationHooks = null
notificationStore = null

############################################################
export initialize = ->
    log "initialize"
    notificationStore = dataCache.load("notificationStore")
    if notificationStore.meta? then await validateNotificationStore()
    else
        notificationStore.meta = {}
        notificationStore.notificationObjects = {}
    notificationHooks = notificationStore.notificationObjects
    return

############################################################
getEventForAction = (action) ->
    switch action
        when "openSecretSpace" then return "event onOpen"
        when "getSecretSpace" then return "event onRead"
        when "deleteSecretSpace" then return "event onDelete"
        when "setSecret" then return "event onWrite"
        when "getSecret" then return "event onRead"
        when "deleteSecret" then return "event onDelete"
        when "openSubSpace" then return "event onWrite"
        when "getSubSpace" then return "event onRead"
        when "deleteSubSpace" then return "event onDelete"
        when "shareSecretTo" then return "event onWrite"
        when "getSecretFrom" then return "event onRead"
        when "deleteSharedSecret" then return "event onDelete"
        when "createAuthCode" then return "event onWrite"
        when "addNotificationHook" then return "event onNotificationWrite"
        when "getNotificationHooks" then return "event onNotificationRead"
        when "deleteNotificationHook" then return "event onNotificationDelete"
        when "getNodeId" then return "event onNodeIdRead"
        else throw new Error("checking notification types for action: #{action}\n Unexpected action!")
    return

############################################################
validateNotificationStore = ->
    log "validateNotificationStore"
    meta = notificationStore.meta
    signature = meta.serverSig
    if !signature then throw new Error("No signature in notificationStore.meta !")
    meta.serverSig = ""
    jsonString = JSON.stringify(notificationStore)
    meta.serverSig = signature
    if(await serviceCrypto.verify(signature, jsonString)) then return
    else throw new Error("Invalid Signature in notificationStore.meta !")

signAndSaveNotificationStore = ->
    log "signAndSaveNotificationStore"
    notificationStore.meta.serverSig = ""
    notificationStore.meta.serverPub = serviceCrypto.getPublicKeyHex()
    jsonString = JSON.stringify(notificationStore)
    signature = await serviceCrypto.sign(jsonString)
    notificationStore.meta.serverSig = signature
    dataCache.save("notificationStore")
    return

############################################################
createNewId = ->
    newId = randomBytes(16).toString("hex")
    while notificationHooks[newId]? 
        newId = randomBytes(16).toString("hex")
    return newId

############################################################
doCheckNotificationRequest = (url) ->
    data = { check: true }
    try
        response = await postData(url, data)
        olog(response)
        # if !response.ok then return throw new Error("Notification Check on #{url} - Response was not OK!\n status: #{response.status}\n body: #{response.body}") 
    catch err then throw new Error("Notification Check on #{url} - caught Error: #{err.message}")
    return 

doNotificationRequest = (url, type, event, meta) ->
    data = { type, event, meta }
    try 
        response = await postData(url, data)
        olog(response)
        # if !response.ok then return throw new Error("Notification on #{url} - Response was not OK!\n status: #{response.status}\n body: #{response.body}") 
    catch err then throw new Error("Notification on #{url} - caught Error: #{err.message}")
    return 

############################################################
notify = (obj, event, meta) ->
    obj.lastNotification = {time: Date.now()}
    try
        await doNotificationRequest(obj.notifyURL, obj.type, event, meta)
        obj.lastNotification.error = null
    catch err then obj.lastNotification.error = err.message
    return

############################################################
export createNew = (nodeId, type, targetId, notifyURL) ->
    log "createNew"
    id = createNewId()
    notificationHookObject = {id, nodeId, type, targetId, notifyURL}
    notificationHooks[id] = notificationHookObject
    signAndSaveNotificationStore()
    return id

############################################################
export addDetailsToIds = (ids) ->
    result = []
    for id in ids
        obj = notificationHooks[id]
        throw new Error('notificationHookId of "'+id+'" did not exist!') unless obj?
        type = obj.type
        url = obj.notifyURL
        lastNotification = obj.lastNotification || null
        result.push({id, type, url, lastNotification})
    return result

export remove = (ids) ->
    log "remove"
    if typeof ids == "string" then ids = [ ids ]
    return unless ids.length > 0

    nonExisting = []
    for id in ids
        obj = notificationHooks[id]
        nonExisting.push(id) unless obj?
        delete notificationHooks[id]
    if nonExisting.length > 0 then throw new Error('notificationHookIds: "'+nonExisting+'" did not exist!')
    signAndSaveNotificationStore()
    return obj

############################################################
export notifyForRequestSuccess = (req, response, enIds) ->
    log "notifyForRequestSuccess"
    { ip, ips, hostname, method, originalUrl, body, path } = req
    log path
    action  = path.slice(1)
    source = "request #{action}"
    event = getEventForAction(action)
    
    meta = { source, ip, ips, hostname, method, originalUrl, body, response }
    
    p1 = notifyForEvent(event, meta, enIds)
    p2 = notifyForLogging(event, meta, enIds)
    await Promise.all([p1, p2])
    return

export notifyForRequestFailure = (req, error, enIds) ->
    log "notifyForRequest"
    { ip, ips, hostname, method, originalUrl, body, path } = req
    log path
    action  = path.slice(1)
    source = "request #{action}"
    event = "event onError"
    response = { error: error.message }

    meta = { source, ip, ips, hostname, method, originalUrl, body, response }
    
    ## TODO check if we also want to fire the regular events
    p1 = notifyForEvent(event, meta, enIds)
    p2 = notifyForLogging(event, meta, enIds)
    await Promise.all([p1, p2])
    return

############################################################
export notifyForEvent = (event, meta, enIds) ->
    promises = []
    for id in enIds
        obj = notificationHooks[id]
        if obj? and obj.type == event
            promises.push(notify(obj, event, meta)) 
    await Promise.all(promises)
    return

export notifyForLogging = (event, meta, enIds) ->
    promises = []
    for id in enIds 
        obj = notificationHooks[id]
        if obj? and obj.type == "log"
            promises.push(notify(obj, event, meta)) 
    await Promise.all(promises)
    return

############################################################
export initialCheck = (id) ->
    obj = notificationHooks[id]
    if !obj? then throw new Error("NotificationObject to check with id: #{id} did not exist!")
    obj.lastNotification = {time: Date.now()}
    try
        await doCheckNotificationRequest(obj.notifyURL)
        obj.lastNotification.error = null
    catch err then obj.lastNotification.error = err.message
    return