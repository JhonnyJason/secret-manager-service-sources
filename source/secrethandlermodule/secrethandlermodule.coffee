############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secrethandlermodule")
#endregion

############################################################
#region localModules
secretStore = null
security = null

#endregion

############################################################
export initialize = ->
    log "initialize"
    secretStore = allModules.secretstoremodule
    security = allModules.securitymodule
    return

############################################################
#region exposedFunctions
export getEncryptedSecretSpace = (keyHex) ->
    log "getEncryptedSecretSpace"
    bare = secretStore.getSecretSpace(keyHex)
    bareString = JSON.stringify(bare)
    return await security.encrypt(bareString, keyHex) 

export setSecret = (nodeId, secretId, secretPlain) ->
    log "setSecret"
    ourSecret = await security.encrypt(secretPlain, nodeId)
    secretStore.setSecret(nodeId, secretId, ourSecret)
    return

export shareSecretTo = (fromId, shareToId, secretId, secretPlain) ->
    log "shareSecretTo"
    theirSecret = await security.encrypt(secretPlain, shareToId)
    secretStore.setSharedSecret(shareToId, fromId, secretId, theirSecret)
    return

#endregion
