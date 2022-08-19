############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretstoremodule")
#endregion

############################################################
import * as state from "cached-persistentstate"

############################################################
#region internalFunctions
isShared = (id) ->
    if id.length < 65 then return false
    if id.charAt(64) != "." then return false
    return true

getSharedSecret = (secretSpace, secretId) ->
    fromKey = secretId.slice(0,64)
    throw new Error("no secret from fromId!") unless secretSpace[fromKey]?
    subSpace = secretSpace[fromKey]
    restKey = secretId.slice(65)
    throw new Error("secret does not exist!") unless subSpace[restKey]?
    return subSpace[restKey]

deleteSharedSecret = (secretSpace, secretId) ->
    fromKey = secretId.slice(0,64)
    throw new Error("no secret from fromId!") unless secretSpace[fromKey]?
    subSpace = secretSpace[fromKey]
    restKey = secretId.slice(65)
    delete subSpace[restKey]
    return 


#endregion

############################################################
#region exposedFunctions
export addNodeId = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    secretSpace = state.load(nodeId)
    ## TODO setup basicSecretSpace
    return

export removeNodeId = (nodeId) ->
    throw new Error("No nodeId provided!") unless nodeId
    state.remove(nodeId)
    return


############################################################
export getSecretSpace = (nodeId) -> 
    throw new Error("No nodeId provided!") unless nodeId
    return state.load(nodeId)

export getSecret = (nodeId, secretId) ->
    throw new Error("No secretId provided!") unless secretId?
    secretSpace = state.load(nodeId)
    if isShared(secretId) then return getSharedSecret(secretSpace, secretId)
    else
        throw new Error("Secret with secretId does not exist!") unless secretSpace[secretId]?
        container = secretSpace[secretId]
        return container.secret

############################################################
export setSecret = (nodeId, secretId, secret) ->
    throw new Error("No secretId provided!") unless secretId?
    throw new Error("cannot set shared secret here!") if isShared(secretId)
    secretSpace = state.load(nodeId)
    ##TODO check if space is legit
    if !secretSpace[secretId]? then secretSpace[secretId] = {}
    container = secretSpace[secretId]
    container.secret = secret
    state.save(nodeId)
    return

export deleteSecret = (nodeId, secretId) ->
    throw new Error("No secretId provided!") unless secretId?
    secretSpace = state.load(nodeId)
    if isShared(secretId) then return deleteSharedSecret(secretSpace, secretId)
    else delete secretSpace[secretId] if secretSpace[secretId]?
    state.save(nodeId)
    return

############################################################
export addSubSpaceFor = (nodeId, fromId) ->
    throw new Error("No fromId provided!") unless fromId?

    secretSpace = state.load(nodeId)
    return if secretSpace[fromId]?
    secretSpace[fromId] = {}
    state.save(nodeId)
    return

export removeSubSpaceFor = (nodeId, fromId) ->
    throw new Error("No fromId provided!") unless fromId?

    secretSpace = state.load(nodeId)
    return unless secretSpace[fromId]?
    delete secretSpace[fromId]
    state.save(nodeId)
    return

############################################################
export setSharedSecret = (nodeId, fromId, secretId, secret) ->
    secretSpace = state.load(nodeId)
    throw new Error("No secrets accepted!") unless secretSpace[fromId]?
    subSpace = secretSpace[fromId]
    subSpace[secretId] = secret
    state.save(nodeId)
    return

export deleteSharedSecret = (nodeId, fromId, secretId) ->
    secretSpace = state.load(nodeId)
    throw new Error("no secrets accepted from fromId!") unless secretSpace[fromId]?
    subSpace = secretSpace[fromId]
    delete subSpace[secretId]
    state.save(nodeId)
    return

#endregion

