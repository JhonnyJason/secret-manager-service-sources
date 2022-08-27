############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secrethandlermodule")
#endregion

############################################################
#region imports
import * as spaceManager from "./secretspacemanagermodule.js"
import * as security from "./securitymodule.js"

#endregion

############################################################
#region exposedFunctions
export getEncryptedSecretSpace = (keyHex) ->
    log "getEncryptedSecretSpace"
    secretSpace = spaceManager.getSpaceFor(keyHex)
    secretSpaceString = JSON.stringify(secretSpace)
    return await security.encrypt(secretSpaceString, keyHex) 

export setSecretEncryptedly = (nodeId, secretId, secretPlain) ->
    log "setSecretEncryptedly"
    ourSecret = await security.encrypt(secretPlain, nodeId)
    spaceManager.setSecret(nodeId, secretId, ourSecret)
    return

export shareSecretToEncryptedly = (fromId, shareToId, secretId, secretPlain) ->
    log "shareSecretToEncryptedly"
    theirSecret = await security.encrypt(secretPlain, shareToId)
    spaceManager.setSharedSecret(shareToId, fromId, secretId, theirSecret)
    return

#endregion
