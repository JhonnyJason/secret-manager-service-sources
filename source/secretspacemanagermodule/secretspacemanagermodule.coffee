############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretspacemanagermodule")
#endregion

############################################################
#region imports
import * as dataCache from "cached-persistentstate"
import * as closureManager from "./closuredatemodule.js"
import * as serviceCrypto from "./servicekeysmodule.js"

############################################################
import { CustomError } from "./customerrormodule.js"

############################################################
import nodeCrypto from "crypto"

#endregion

############################################################
#region ErrorObjects
class SpecialError extends CustomError 

#endregion

############################################################
class SecretSpace
    constructor: (@data) ->
        @meta = @data.meta
        @secrets = @data.secrets
        @subSpaces = @data.subSpaces
        @id = @meta.id


    ########################################################
    validate: ->
        log "SecretSpace.validate"
        signature = @meta.serverSig
        @meta.serverSig = ""
        spaceString = JSON.stringify(@data)
        @meta.serverSig = signature
        return await serviceCrypto.verify(signature, spaceString)

    save: ->
        log "SecretSpace.save"
        try
            @meta.serverSig = ""
            spaceString = JSON.stringify(@data)
            log spaceString
            @meta.serverSig = await serviceCrypto.sign(spaceString)
            dataCache.save(@id, @data)
        catch err then log("SecretSpace could not be saved: "+err.message)
        return


    ########################################################
    setSecret: (secretId, secret) ->
        if !@secrets[secretId]? then @secrets[secretId] = {}
        container = @secrets[secretId]
        container.secret = secret
        await @save()
        return

    getSecret: (secretId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        return container.secret

    deleteSecret: (secretId) ->
        delete @secrets[secretId]
        await @save()
        return


    ########################################################
    createSubSpace: (fromId, closureDate) ->
        log "SecretSpace.createSubSpace"
        if @subSpaces[fromId]? then return
        subSpace = createNewSubSpace(fromId, closureDate, this)
        stillExists = closureManager.checkIfOpen(subSpace.meta)
        if stillExists
            @subSpaces[fromId] = subSpace.data
            await @save()
        else throw new Error("ClosureDate has already passed!")
        
    getSubSpace: (fromId) ->
        if !@subSpaces[fromId]? then throw new Error('There is no SubSpace for "'+fromId+'"')
        stillExists = closureManager.checkIfOpen(@subSpaces[fromId].meta)
        if !stillExists then throw new Error('There is no SubSpace for "'+fromId+'"')
        return @subSpaces[fromId]

    removeSubSpace: (fromId) ->
        ## For now we donot throw an error on removal of nonexisting Spaces
        # if !@subSpaces[fromId]? then throw new Error('There is no SubSpace for "'+fromId+'"')
        delete @subSpaces[fromId]
        await @save()
        return


    ########################################################
    addNotificationHook: (notificationHookId) ->
        if !@meta.notificationHooks? then @meta.notificationHooks = []
        @meta.notificationHooks.push(notificationHookId)
        await @save()
        return notificationHookId
    
    addNotificationHookToSecret: (secretId, notificationHookId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then container.notificationHooks = []
        container.notificationHooks.push(notificationHookId)
        await @save()
        return notificationHookId


    ########################################################
    getNotificationHooks: ->
        if !@meta.notificationHooks? then return []
        return @meta.notificationHooks

    getNotificationHooksFromSecret: (secretId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then return []
        return container.notificationHooks

    getAllNotificationHooks: ->
        result = []
        result.push(...@getNotificationHooks())
        for secretId of @data.secrets
            result.push(...@getNotificationHooksFromSecret(secretId))
        for subSpaceId,d of @data.subSpaces
            subSpace = new SubSpace(d, this)
            result.push(...subSpace.getAllNotificationHooks())
        return result

    ########################################################
    deleteNotificationHook: (notificationHookId) ->
        if !@meta.notificationHooks? then return
        arr = @meta.notificationHooks
        arr.splice(i, 1) for el,i in arr when el == notificationHookId  
        await @save()
        return

    deleteNotificationHookOfSecret: (secretId, notificationHookId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then return
        arr = container.notificationHooks
        arr.splice(i, 1) for el,i in arr when el == notificationHookId  
        await @save()
        return
            
class SubSpace
    constructor: (@data, @parentSpace) ->
        @meta = @data.meta
        @secrets = @data.secrets
        @id = @meta.id


    ########################################################
    setSecret: (secretId, secret, isOneTime) ->
        if !@secrets[secretId]? then @secrets[secretId] = {}
        container = @secrets[secretId]
        container.secret = secret
        if isOneTime then container.isOneTime = true
        await @parentSpace.save()

    getSecret: (secretId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if container.isOneTime then await @deleteSecret(secretId)
        return container.secret

    deleteSecret: (secretId) ->
        delete @secrets[secretId]
        await @parentSpace.save()


    ########################################################
    addNotificationHook: (notificationHookId) ->
        if !@meta.notificationHooks? then @meta.notificationHooks = []
        @meta.notificationHooks.push(notificationHookId)
        await @parentSpace.save()
        return notificationHookId

    addNotificationHookToSecret: (secretId, notificationHookId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then container.notificationHooks = []
        container.notificationHooks.push(notificationHookId)
        await @parentSpace.save()
        return notificationHookId


    ########################################################
    getNotificationHooks: ->
        if !@meta.notificationHooks? then return []
        return @meta.notificationHooks

    getNotificationHooksFromSecret: (secretId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then return []
        return container.notificationHooks

    getAllNotificationHooks: ->
        result = []
        result.push(...@getNotificationHooks())
        for secretId of @data.secrets
            result.push(...@getNotificationHooksFromSecret(secretId))
        return result

    ########################################################
    deleteNotificationHook: (notificationHookId) ->
        if !@meta.notificationHooks? then return
        arr = @meta.notificationHooks
        arr.splice(i, 1) for el,i in arr when el == notificationHookId
        @parentSpace.save()
        return

    deleteNotificationHookOfSecret: (secretId, notificationHookId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then return
        arr = container.notificationHooks
        arr.splice(i, 1) for el,i in arr when el == notificationHookId  
        @parentSpace.save()
        return

############################################################
loadSpace = (id) ->
    data = dataCache.load(id)
    # olog data
    if !data.meta? or !data.secrets? or !data.subSpaces? then throw new Error('SecretSpace for "'+id+'" did not exist!')
    stillExists = closureManager.checkIfOpen(data.meta)
    if !stillExists then throw new Error('SecretSpace for "'+id+'" did not exist!')
    return new SecretSpace(data)

loadValidSpace = (id) ->
    secretSpace = loadSpace(id)
    await assertValidity(secretSpace)
    return secretSpace

createNewSpace = (id, closureDate, owner) ->
    # if !closureDate? then closureDate = null
    data = {}
    serverPub = serviceCrypto.getPublicKeyHex()
    communication = ""
    data.meta = {id, closureDate, owner, communication, serverPub}
    data.secrets = {}
    data.subSpaces = {}
    return new SecretSpace(data)

createNewSubSpace = (fromId, closureDate, parentSpace) ->
    # if !closureDate? then closureDate = null
    data = {}
    id = parentSpace.id+"."+fromId
    data.meta = {id, closureDate}
    data.secrets = {}
    return new SubSpace(data, parentSpace)

############################################################
assertValidity = (secretSpace) ->
    isValid = await secretSpace.validate()
    if !isValid then throw new Error("SecretSpace got corrupted!")
    return

############################################################
#region exposed functions
export createSpaceFor = (nodeId, closureDate, owner) ->
    throw new Error("No nodeId provided!") unless nodeId
    
    try loadedSpace = loadSpace(nodeId)
    catch error then log error
    
    if loadedSpace?
        await assertValidity(loadedSpace)
        if closureDate? and closureDate != loadedSpace.meta.closureDate then throw new Error("Updating the closureDate is not allowed!")
        if owner?
            loadedSpace.meta.owner = owner
            await loadedSpace.save()
    else
        newSpace = createNewSpace(nodeId, closureDate, owner)
        stillExists = closureManager.checkIfOpen(newSpace.meta)
        if stillExists then await newSpace.save()
        else throw new Error("ClosureDate has already passed!")        
    return

export getSpaceFor = (nodeId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    return secretSpace.data

export deleteSpaceFor = (nodeId, enIds, dnIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    ## For now we donot throw an error on removal of nonexisting Spaces
    try
        data = dataCache.load(nodeId)
        if !data.meta? or !data.secrets? or !data.subSpaces? then throw new Error('SecretSpace for "'+nodeId+'" did not exist!')
        secretSpace = new SecretSpace(data)
        enIds.push(...secretSpace.getNotificationHooks())
        dnIds.push(...secretSpace.getAllNotificationHooks())
        # olog {enIds, dnIds}
    catch err then log err
    dataCache.remove(nodeId)
    return

############################################################
export setSecret = (nodeId, secretId, secret, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    await secretSpace.setSecret(secretId, secret)
    enIds.push(...secretSpace.getNotificationHooksFromSecret(secretId))
    return

export getSecret = (nodeId, secretId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    enIds.push(...secretSpace.getNotificationHooksFromSecret(secretId))
    return await secretSpace.getSecret(secretId)

export deleteSecret = (nodeId, secretId, enIds, dnIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    enIds.push(...secretSpace.getNotificationHooksFromSecret(secretId))
    dnIds.push(...secretSpace.getNotificationHooksFromSecret(secretId))
    await secretSpace.deleteSecret(secretId)
    return

############################################################
export createSubSpaceFor = (nodeId, fromId, closureDate, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    olog {nodeId, fromId, closureDate}
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    await secretSpace.createSubSpace(fromId, closureDate)
    return

export getSubSpaceFor = (nodeId, fromId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    enIds.push(...subSpace.getNotificationHooks())
    return await secretSpace.getSubSpace(fromId)

export deleteSubSpaceFor = (nodeId, fromId, enIds, dnIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    enIds.push(...subSpace.getNotificationHooks())
    dnIds.push(...subSpace.getAllNotificationHooks())
    # olog {enIds, dnIds}
    await secretSpace.removeSubSpace(fromId)
    return

############################################################
export setSharedSecret = (nodeId, fromId, secretId, secret, isOneTime, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    enIds.push(...subSpace.getNotificationHooks())
    await subSpace.setSecret(secretId, secret, isOneTime)
    enIds.push(...subSpace.getNotificationHooksFromSecret(secretId))
    return

export getSharedSecret = (nodeId, fromId, secretId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    enIds.push(...subSpace.getNotificationHooks())
    enIds.push(...subSpace.getNotificationHooksFromSecret(secretId))
    return subSpace.getSecret(secretId)

export deleteSharedSecret = (nodeId, fromId, secretId, enIds, dnIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    enIds.push(...subSpace.getNotificationHooks())
    enIds.push(...subSpace.getNotificationHooksFromSecret(secretId))
    dnIds.puhs(...subSpace.getNotificationHooksFromSecret(secretId))
    await subSpace.deleteSecret(secretId)
    return

############################################################
export addNotificationHook = (nodeId, targetId, notificationHookId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    # simple case of "this"
    if targetId == "this" then return await secretSpace.addNotificationHook(notificationHookId)
    #complex cases are tokens separated with .
    targetTokens = targetId.split(".")
    # case secret
    if targetTokens[0] == "secrets"
        throw new Error("targetId is corrupted!") unless targetTokens.length == 2
        enIds.push(...secretSpace.getNotificationHooksFromSecret(targetTokens[1]))
        return await secretSpace.addNotificationHookToSecret(targetTokens[1], notificationHookId)
    # other cases must be in subSpaces
    throw new Error("targetId is corrupted!") unless targetTokens[0] == "subSpaces"
    subSpaceData = await secretSpace.getSubSpace(targetTokens[1])
    subSpace = new SubSpace(subSpaceData, secretSpace)
    enIds.push(...subSpace.getNotificationHooks())
    # on 2 tokens the case must be the subSpace itself
    if targetTokens.length ==  2 then return await subSpace.addNotificationHook(notificationHookId)
    # otherwise it must be a secret in a subSpace (sharedSecret)
    throw new Error("targetId is corrupted!") unless targetTokens.length == 3
    enIds.push(...subSpace.getNotificationHooksFromSecret(targetTokens[2]))
    return await subSpace.addNotificationHookToSecret(targetTokens[2], notificationHookId)

export getNotificationHooks = (nodeId, targetId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    # simple case of "this"
    if targetId == "this" then return await secretSpace.getNotificationHooks()
    #complex cases are tokens separated with .
    targetTokens = targetId.split(".")
    # case secret
    if targetTokens[0] == "secrets"
        throw new Error("targetId is corrupted!") unless targetTokens.length == 2
        enIds.push(...secretSpace.getNotificationHooksFromSecret(targetTokens[1]))
        return await secretSpace.getNotificationHooksFromSecret(targetTokens[1])
    # other cases must be in subSpaces
    throw new Error("targetId is corrupted!") unless targetTokens[0] == "subSpaces"
    subSpaceData = await secretSpace.getSubSpace(targetTokens[1])
    subSpace = new SubSpace(subSpaceData, secretSpace)
    # on 2 tokens the case must be the subSpace itself
    if targetTokens.length ==  2 then return await subSpace.getNotificationHooks()
    # otherwise it must be a secret in a subSpace (sharedSecret)
    throw new Error("targetId is corrupted!") unless targetTokens.length == 3
    enIds.push(...subSpace.getNotificationHooksFromSecret(targetTokens[2]))
    return await subSpace.getNotificationHooksFromSecret(targetTokens[2])

export deleteNotificationHook = (nodeId, targetId, notificationHookId, enIds) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = await loadValidSpace(nodeId)
    enIds.push(...secretSpace.getNotificationHooks())
    # simple case of "this"
    if targetId == "this" then return await secretSpace.deleteNotificationHook(notificationHookId)
    #complex cases are tokens separated with .
    targetTokens = targetId.split(".")
    # case secret
    if targetTokens[0] == "secrets"
        throw new Error("targetId is corrupted!") unless targetTokens.length == 2
        enIds.push(...secretSpace.getNotificationHooksFromSecret(targetTokens[1]))
        return await secretSpace.deleteNotificationHookOfSecret(targetTokens[1], notificationHookId)
    # other cases must be in subSpaces
    throw new Error("targetId is corrupted!") unless targetTokens[0] == "subSpaces"
    subSpaceData = await secretSpace.getSubSpace(targetTokens[1])
    subSpace = new SubSpace(subSpaceData, secretSpace)
    # on 2 tokens the case must be the subSpace itself
    if targetTokens.length ==  2 then return await subSpace.deleteNotificationHook(notificationHookId)
    # otherwise it must be a secret in a subSpace (sharedSecret)
    throw new Error("targetId is corrupted!") unless targetTokens.length == 3
    enIds.push(...subSpace.getNotificationHooksFromSecret(targetTokens[2]))
    return await subSpace.deleteNotificationHookOfSecret(targetTokens[2], notificationHookId)

#endregion