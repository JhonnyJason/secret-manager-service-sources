############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretencryptionmodule")
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
    secretSpace = await spaceManager.getSpaceFor(keyHex)
    secretSpaceString = JSON.stringify(secretSpace)
    return await security.encrypt(secretSpaceString, keyHex) 

export getEncryptedSubSpace = (keyHex, fromId) ->
    log "getEncryptedSubSpace"
    subSpace = await spaceManager.getSubSpaceFor(keyHex, fromId)
    subSpaceString = JSON.stringify(subSpace)
    return await security.encrypt(subSpaceString, keyHex) 

############################################################
export setEncryptedSecret = (nodeId, secretId, secretPlain) ->
    log "setEncryptedSecret"
    ourSecret = await security.encrypt(secretPlain, nodeId)
    await spaceManager.setSecret(nodeId, secretId, ourSecret)
    return

export shareEncryptedSecretTo = (fromId, shareToId, secretId, secretPlain, isOneTime) ->
    log "shareEncryptedSecretTo"
    theirSecret = await security.encrypt(secretPlain, shareToId)
    await spaceManager.setSharedSecret(shareToId, fromId, secretId, theirSecret, isOneTime)
    return

#endregion
