############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretspacemanagermodule")
#endregion

############################################################
import * as dataCache from "cached-persistentstate"
import * as serviceCrypto from "./servicekeysmodule.js"
import nodeCrypto from "crypto"

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

    getSecret: (secretId) ->


############################################################
loadSpace = (id) ->
    data = dataCache.load(id)
    olog data
    if !data.meta? or !data.secrets? or !data.subSpaces? then throw new Error("SecretSpace for "+id+" did not exist!")
    return new SecretSpace(data)

createNewSpace = (id, closureDate, owner) ->
    data = {}
    serverPub = serviceCrypto.getPublicKeyHex()
    logTo = ""
    communication = ""
    data.meta = {id, closureDate, owner, communication, logTo, serverPub}
    data.secrets = {}
    data.subSpaces = {}
    return new SecretSpace(data)


############################################################
assertValidity = (secretSpace) ->
    isValid = await secretSpace.validate()
    if !isValid then throw new Error("SecretSpace got corrupted!")
    return

############################################################
#region exposed functions
export createSpaceFor = (nodeId, closureDate, owner) ->
    log "createSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    
    try loadedSpace = loadSpace(nodeId)
    catch error then log error
    
    if loadedSpace?
        await assertValidity(loadedSpace)
        if closureDate? and closureDate != loadedSpace.meta.closureDate then throw new Error("Updating the closureDate is not allowed!")
        if owner?
            loadedSpace.meta.owner = owner
            loadedSpace.save()
    else 
        newSpace = createNewSpace(nodeId, closureDate, owner)    
        await newSpace.save()        
    return

export removeSpaceFor = (nodeId) ->
    log "removeSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    dataCache.remove(nodeId)
    return

############################################################
export getSpaceFor = (nodeId) ->
    log "getSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = loadSpace(nodeId)
    return secretSpace.data

############################################################
export setSecret = (nodeId, secretId, secret) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId?
    # throw new Error("cannot set shared secret here!") if isShared(secretId)
    secretSpace = loadSpace(nodeId)
    await assertValidity(secretSpace)
    await secretSpace.setSecret(secretId, secret)
    ## maybe we can skip await here
    return

export getSecret = (nodeId, secretId) ->
    throw new Error("No nodeId provided!") unless nodeId
    ## TODO
    # throw new Error("No secretId provided!") unless secretId?
    # secretSpace = new SecretSpace(nodeId)
    # if isShared(secretId) then return getSharedSecret(secretSpace, secretId)
    # else
    #     throw new Error("Secret with secretId does not exist!") unless secretSpace[secretId]?
    #     container = secretSpace[secretId]
    #     return container.secret

#endregion