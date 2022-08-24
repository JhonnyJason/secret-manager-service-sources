############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretspacemanagermodule")
#endregion

import * as dataCache from "cached-persistentstate"

############################################################
class SecretSpace
    constructor: (@id, closureDate) ->
        @data = dataCache.load(@id)

        if @data.meta?
            @validate()
            @meta = @data.meta
            @secrets = @data.secrets
            @subSpaces = @data.subSpaces
            if closureDate? then throw new Error("Updating the closureDate is not allowed!")

        else # new space has been created
            @data.meta = {}
            @data.secrets = {}
            @data.subSpaces = {}

            @meta = @data.meta
            @secrets = @data.secrets
            @subSpaces = @data.subSpaces
            
            if closureDate? then @meta.closureDate = closureDate
            else @meta.closureDate = 0
            
            # @meta.serverPub = #TODO get server publicKey
            @meta.logTo = ""
            @meta.communication = ""
            @meta.ownerBy = "" #TODO figure out potential owner from authCode
            
            @sign()
            dataCache.save(@id)



        validate: ->
            signature = @meta.serverSig
            @meta.serverSig = ""
            spaceString = JSON.stringify(@data)
            ##TODO verify signature
            return

        sign: ->
            log "SecretSpace.sign"
            @meta.serverSig = ""
            spaceString = JSON.stringify(@data)
            log spaceString
            #TODO get signature
            return

        

        



############################################################
export initialize = ->
    log "initialize"
    #Implement or Remove :-)
    return

############################################################
export createSpaceFor = (nodeId, closureDate) ->
    log "createSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    new SecretSpace(nodeId)
    return

export removeSpaceFor = (nodeId) ->
    log "removeSpaceFor"
    throw new Error("No nodeId provided!") unless nodeId
    dataCache.remove(nodeId)
    return
