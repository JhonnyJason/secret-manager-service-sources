############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretspacemanagermodule")
#endregion

############################################################
#region imports
import * as dataCache from "cached-persistentstate"
import * as serviceCrypto from "./servicekeysmodule.js"
import * as notificationHooks from "./notificationhooksmodule.js"

############################################################
import nodeCrypto from "crypto"

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
        await assertValidity(this)
        if !@secrets[secretId]? then @secrets[secretId] = {}
        container = @secrets[secretId]
        container.secret = secret
        await @save()
        return

    getSecret: (secretId) ->
        await assertValidity(this)
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        return container.secret

    deleteSecret: (secretId) ->
        await assertValidity(this)
        delete @secrets[secretId]
        await @save()
        return


    ########################################################
    createSubSpace: (fromId, closureDate) ->
        await assertValidity(this)
        if @subSpaces[fromId]? then return
        subSpace = createNewSubSpace(fromId, closureDate, this)
        @subSpaces[fromId] = subSpace.data
        await @save()

    getSubSpace: (fromId) ->
        await assertValidity(this)
        if !@subSpaces[fromId]? then throw new Error('There is no SubSpace for "'+fromId+'"')
        return @subSpaces[fromId]

    removeSubSpace: (fromId) ->
        await assertValidity(this)
        ## For now we donot throw an error on removal of nonexisting Spaces
        # if !@subSpaces[fromId]? then throw new Error('There is no SubSpace for "'+fromId+'"')
        delete @subSpaces[fromId]
        await @save()
        return


    ########################################################
    addNotificationHook: (notificationHookId) ->
        await assertValidity(this)
        if !@meta.notificationHooks? then @meta.notificationHooks = []
        @meta.notificationHooks.push(notificationHookId)
        await @save()
        return notificationHookId
    
    addNotificationHookToSecret: (secretId, notificationHookId) ->
        await assertValidity(this)
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then container.notificationHooks = []
        container.notificationHooks.push(notificationHookId)
        await @save()
        return notificationHookId


    ########################################################
    getNotificationHooks: ->
        await assertValidity(this)
        if !@meta.notificationHooks? then return []
        return @meta.notificationHooks

    getNotificationHooksFromSecret: (secretId) ->
        await assertValidity(this)
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        if !container.notificationHooks? then return []
        return container.notificationHooks


    ########################################################
    deleteNotificationHook: (notificationHookId) ->
        await assertValidity(this)
        if !@meta.notificationHooks? then return
        arr = @meta.notificationHooks
        arr.splice(i, 1) for el,i in arr when el == notificationHookId  
        await @save()
        return

    deleteNotificationHookOfSecret: (secretId, notificationHookId) ->
        await assertValidity(this)
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
    olog data
    if !data.meta? or !data.secrets? or !data.subSpaces? then throw new Error('SecretSpace for "'+id+'" did not exist!')
    return new SecretSpace(data)

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
        await newSpace.save()        
    return

export getSpaceFor = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = loadSpace(nodeId)
    await assertValidity(secretSpace)
    notificationHooks.notify(secretSpace.meta.notificationHooks, "getSecretSpace")
    return secretSpace.data

export removeSpaceFor = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    ## For now we donot throw an error on removal of nonexisting Spaces
    # loadSpace(nodeId) # throws an error if it does not exist
    notificationHooks.notify(secretSpace.meta.notificationHooks, "deleteSecretSpace")
    dataCache.remove(nodeId)
    return

############################################################
export setSecret = (nodeId, secretId, secret) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    await secretSpace.setSecret(secretId, secret)
    ## maybe we can skip await here
    return

export getSecret = (nodeId, secretId) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    return await secretSpace.getSecret(secretId)

export deleteSecret = (nodeId, secretId) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    await secretSpace.deleteSecret(secretId)
    return

############################################################
export createSubSpaceFor = (nodeId, fromId, closureDate) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    olog {nodeId, fromId, closureDate}
    secretSpace = loadSpace(nodeId)
    await secretSpace.createSubSpace(fromId, closureDate)
    return

export getSubSpaceFor = (nodeId, fromId) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    secretSpace = loadSpace(nodeId)
    return await secretSpace.getSubSpace(fromId)

export removeSubSpaceFor = (nodeId, fromId) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    secretSpace = loadSpace(nodeId)
    await secretSpace.removeSubSpace(fromId)
    return

############################################################
export setSharedSecret = (nodeId, fromId, secretId, secret, isOneTime) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    await subSpace.setSecret(secretId, secret, isOneTime)
    return

export getSharedSecret = (nodeId, fromId, secretId) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    return subSpace.getSecret(secretId)

export deleteSharedSecret = (nodeId, fromId, secretId) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    await subSpace.deleteSecret(secretId)
    return

############################################################
export addNotificationHook = (nodeId, targetId, notificationHookId) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = loadSpace(nodeId)
    # simple case of "this"
    if targetId == "this" then return await secretSpace.addNotificationHook(notificationHookId)
    #complex cases are tokens separated with .
    targetTokens = targetId.split(".")
    # case secret
    if targetTokens[0] == "secrets"
        throw new Error("targetId is corrupted!") unless targetTokens.length == 2
        return await secretSpace.addNotificationHookToSecret(targetTokens[1], notificationHookId)
    # other cases must be in subSpaces
    throw new Error("targetId is corrupted!") unless targetTokens[0] == "subSpaces"
    subSpaceData = await secretSpace.getSubSpace(targetTokens[1])
    subSpace = new SubSpace(subSpaceData, secretSpace)
    # on 2 tokens the case must be the subSpace itself
    if targetTokens.length ==  2 then return await subSpace.addNotificationHook(notificationHookId)
    # otherwise it must be a secret in a subSpace (sharedSecret)
    throw new Error("targetId is corrupted!") unless targetTokens.length == 3
    return await subSpace.addNotificationHookToSecret(targetTokens[2], notificationHookId)

export getNotificationHooks = (nodeId, targetId) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = loadSpace(nodeId)
    # simple case of "this"
    if targetId == "this" then return await secretSpace.getNotificationHooks()
    #complex cases are tokens separated with .
    targetTokens = targetId.split(".")
    # case secret
    if targetTokens[0] == "secrets"
        throw new Error("targetId is corrupted!") unless targetTokens.length == 2
        return await secretSpace.getNotificationHooksFromSecret(targetTokens[1])
    # other cases must be in subSpaces
    throw new Error("targetId is corrupted!") unless targetTokens[0] == "subSpaces"
    subSpaceData = await secretSpace.getSubSpace(targetTokens[1])
    subSpace = new SubSpace(subSpaceData, secretSpace)
    # on 2 tokens the case must be the subSpace itself
    if targetTokens.length ==  2 then return await subSpace.getNotificationHooks()
    # otherwise it must be a secret in a subSpace (sharedSecret)
    throw new Error("targetId is corrupted!") unless targetTokens.length == 3
    return await subSpace.getNotificationHooksFromSecret(targetTokens[2])

export deleteNotificationHook = (nodeId, targetId, notificationHookId) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = loadSpace(nodeId)
    # simple case of "this"
    if targetId == "this" then return await secretSpace.deleteNotificationHook(notificationHookId)
    #complex cases are tokens separated with .
    targetTokens = targetId.split(".")
    # case secret
    if targetTokens[0] == "secrets"
        throw new Error("targetId is corrupted!") unless targetTokens.length == 2
        return await secretSpace.deleteNotificationHookOfSecret(targetTokens[1], notificationHookId)
    # other cases must be in subSpaces
    throw new Error("targetId is corrupted!") unless targetTokens[0] == "subSpaces"
    subSpaceData = await secretSpace.getSubSpace(targetTokens[1])
    subSpace = new SubSpace(subSpaceData, secretSpace)
    # on 2 tokens the case must be the subSpace itself
    if targetTokens.length ==  2 then return await subSpace.deleteNotificationHook(notificationHookId)
    # otherwise it must be a secret in a subSpace (sharedSecret)
    throw new Error("targetId is corrupted!") unless targetTokens.length == 3
    return await subSpace.deleteNotificationHookOfSecret(targetTokens[2], notificationHookId)

#endregion