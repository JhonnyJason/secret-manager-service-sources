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
    constructor: (@id, closureDate, owner) ->
        @data = dataCache.load(@id)

        if @data.meta?
            @meta = @data.meta
            @secrets = @data.secrets
            @subSpaces = @data.subSpaces
            if closureDate? then throw new Error("Updating the closureDate is not allowed!")
            @valid = @validate()

        else # new space has been created
            @data.meta = {}
            @data.secrets = {}
            @data.subSpaces = {}

            @meta = @data.meta
            @secrets = @data.secrets
            @subSpaces = @data.subSpaces
            
            if closureDate? then @meta.closureDate = closureDate
            else @meta.closureDate = 0
            
            @meta.id = @id
            @meta.serverPub = serviceCrypto.getPublicKeyHex()
            @meta.logTo = ""
            @meta.communication = ""
            if owner? then @meta.ownedBy = owner
            else @meta.ownedBy = ""
            
            @valid = true
            @save()

    ########################################################
    validate: ->
        log "SecretSpace.validate"
        signature = @meta.serverSig
        @meta.serverSig = ""
        spaceString = JSON.stringify(@data)
        @meta.serverSig = signature
        return await serviceCrypto.verify(signature, spaceString)

    save: ->
        log "SecretSpace.sign"
        try
            @meta.serverSig = ""
            spaceString = JSON.stringify(@data)
            log spaceString
            @meta.serverSig = await serviceCrypto.sign(spaceString)
            dataCache.save(@id)
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
assertValidity = (secretSpace) ->
    isValid = await secretSpace.valid
    if !isValid then throw new Error("SecretSpace got corrupted!")
    return

############################################################
export createSpaceFor = (nodeId, closureDate) ->
    log "createSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = new SecretSpace(nodeId)
    await assertValidity(secretSpace)
    return

export removeSpaceFor = (nodeId) ->
    log "removeSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    dataCache.remove(nodeId)
    return

############################################################
export getSpaceFor = (nodeId) -> 
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = new SecretSpace(nodeId)
    return secretSpace.data

############################################################
export setSecret = (nodeId, secretId, secret) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No secretId provided!") unless secretId?
    # throw new Error("cannot set shared secret here!") if isShared(secretId)
    secretSpace = new SecretSpace(nodeId)
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