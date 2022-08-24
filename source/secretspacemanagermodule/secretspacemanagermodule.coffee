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
            
            @meta.serverPub = serviceCrypto.getPublicKeyHex()
            @meta.logTo = ""
            @meta.communication = ""
            if owner? then @meta.ownedBy = owner
            else @meta.ownedBy = ""
            
            @valid = true
            @save()


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
            @meta.noise = await getNoiseString()
            spaceString = JSON.stringify(@data)
            log spaceString
            @meta.serverSig = await serviceCrypto.sign(spaceString)
            dataCache.save(@id)
        catch err then log("SecretSpace could not save: "+err.message)
        return
        
############################################################
getNoiseString = -> nodeCrypto.randomBytes(32).toString("hex")

############################################################
export createSpaceFor = (nodeId, closureDate) ->
    log "createSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = new SecretSpace(nodeId)
    isValid = await secretSpace.valid
    log isValid
    if !isValid then throw new Error("SecretSpace got corrupted!")
    return

export removeSpaceFor = (nodeId) ->
    log "removeSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    dataCache.remove(nodeId)
    return
