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

############################################################
notificationHooks = null
notificationStore = null

############################################################
export initialize = ->
    log "initialize"
    notificationStore = dataCache.load("notificationStore")
    if notificationStore.meta? then validateNotificationStore()
    else
        notificationStore.meta = {}
        notificationStore.notificationObjects = {}
        notificationHooks = notificationStore.notificationObjects
    return

############################################################
validateNotificationStore = ->
    log "validateNotificationStore"
    meta = notificationStore.meta
    signature = meta.serverSig
    if !signature then throw new Error("No signature in notificationStore.meta !")
    meta.serverSig = ""
    notificationStoreString = JSON.stringify(notificationStore)
    meta.serverSig = signature
    if(await serviceCrypto.verify(signature, notificationStoreString)) then return
    else throw new Error("Invalid Signature in notificationStore.meta !")

signAndSaveNotificationStore = ->
    log "validateAuthCodeStore"
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
        if !response.ok then return throw new Error("Notification Check on #{url} - Response was not OK!\n status: #{response.status}\n body: #{response.body}") 
    catch err then throw new Error("Notification Check on #{url} - caught Error: #{err.message}")
    return 

doNotificationRequest = (url, requestBody, result, meta) ->
    data = { meta, requestBody, result }
    try 
        response = await postData(url, data)
        if !response.ok then return throw new Error("Notification on #{url} - Response was not OK!\n status: #{response.status}\n body: #{response.body}") 
    catch err then throw new Error("Notification on #{url} - caught Error: #{err.message}")
    return 

getNotificationTypesForAction = (action) ->
    switch action
        when "getSecretSpace" then return ["log", "event onRead"]
        when "deleteSecretSpace" then return ["log", "event onDelete"]
        when "setSecret" then return ["log", "event onWrite"]
        when "getSecret" then return ["log", "event onRead"]
        when "deleteSecret" then return ["log", "event onDelete"]
        when "openSubSpace" then return ["log", "event onWrite"]
        when "getSubSpace" then return ["log", "event onRead"]
        when "deleteSubSpace" then return ["log", "event onDelete"]
        when "shareSecretTo" then return ["log", "event onWrite"]
        when "getSecretFrom" then return ["log", "event onRead"]
        when "deleteSharedSecret" then return ["log", "event onDelete"]
        when "createAuthCode" then return ["log", "event onWrite"]
        when "addNotificationHook" then return ["log"]
        when "getNotificationHooks" then return ["log"]
        when "deleteNotificationHook" then return ["log"]
        when "getNodeId" then return []
        else throw new Error("checking notification types for action: #{action}\n Unexpected action!")
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
        error = obj.error
        result.push({id, type, url, error})
    return result

export remove = (id) ->
    log "remove"    
    obj = notificationHooks[id]
    throw new Error('notificationHookId of "'+id+'" did not exist!') unless obj?
    delete notificationHooks[id]
    signAndSaveNotificationStore()
    return obj

############################################################
export notifyForRequestSuccess = (req, response, enIds) ->
    log "notifyForRequestSuccess"
    log req.path
    body = req.body
    { ip, ips, hostname, method, originalUrl } = req
    meta = { ip, ips, hostname, method, originalUrl }

    action  = req.path.slice(1)
    types = getNotificationTypesForAction(action)

    for id in enIds
        obj = notificationHooks[id]
        if types.includes(obj.type)
            try
                await doNotificationRequest(obj.url, body, response, meta)
                obj.error = null
            catch err then obj.error = err.message 
    return

export notifyForRequestFailure = (req, error, enIds) ->
    log "notifyForRequest"
    log req.path
    body = req.body
    { ip, ips, hostname, method, originalUrl } = req
    meta = { ip, ips, hostname, method, originalUrl }
    response = { error: error.message }

    action = req.path.slice(1)
    types = getNotificationTypesForAction(action)
    types.push("event onError")

    for id in enIds
        obj = notificationHooks[id]
        if types.includes(obj.type)
            try
                await doNotificationRequest(obj.url, body, response, meta)
                obj.error = null
            catch err then obj.error = err.message 
    return

############################################################
export initialCheck = (id) ->
    obj = notificationHooks[id]
    if !obj? then throw new Error("NotificationObject to check with id: #{id} did not exist!")
    try 
        await doCheckNotificationRequest(obj.notifyURL)
        obj.error = null
    catch err then obj.error = err.message
    return