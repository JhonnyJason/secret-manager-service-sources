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

class SubSpace
    constructor: (@data, @parentSpace) ->
        @meta = @data.meta
        @secrets = @data.secrets
        @id = @meta.id

    ########################################################
    setSecret: (secretId, secret) ->
        if !@secrets[secretId]? then @secrets[secretId] = {}
        container = @secrets[secretId]
        container.secret = secret
        await @parentSpace.save()

    getSecret: (secretId) ->
        container = @secrets[secretId]
        throw new Error('Secret with secretId "'+secretId+ '" did not exist!') unless container?
        return container.secret        

    deleteSecret: (secretId) ->
        delete @secrets[secretId]
        await @parentSpace.save()



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
    logTo = ""
    communication = ""
    data.meta = {id, closureDate, owner, communication, logTo, serverPub}
    data.secrets = {}
    data.subSpaces = {}
    return new SecretSpace(data)

createNewSubSpace = (fromId, closureDate, parentSpace) ->
    # if !closureDate? then closureDate = null
    data = {}
    logTo = ""
    id = parentSpace.id+"."+fromId
    data.meta = {id, closureDate, logTo}
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
    return secretSpace.data

export removeSpaceFor = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    ## For now we donot throw an error on removal of nonexisting Spaces
    # loadSpace(nodeId) # throws an error if it does not exist
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
export setSharedSecret = (nodeId, fromId, secretId, secret) ->
    throw new Error("No nodeId provided!") unless nodeId
    throw new Error("No fromId provided!") unless fromId
    throw new Error("No secretId provided!") unless secretId
    secretSpace = loadSpace(nodeId)
    subSpaceData = await secretSpace.getSubSpace(fromId)
    subSpace = new SubSpace(subSpaceData, secretSpace)
    await subSpace.setSecret(secretId, secret)
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

#endregion