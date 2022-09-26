############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("secretencryptionmodule")
#endregion

############################################################
import * as spaceManager from "./secretspacemanagermodule.js"
import * as secUtl from "secret-manager-crypto-utils"

############################################################
encrypt = (content, keyHex) ->
    log "encrypt"
    salt = secUtl.createRandomLengthSalt()
    content = salt + content
    # log "prepended salt: " + content
    # log "separation code: " + content.charCodeAt(salt.length - 1)  
    secrets = await secUtl.asymmetricEncrypt(content, keyHex)

    log "- - - secrets: "
    olog secrets
    return secrets
    
############################################################
#region exposedFunctions
export getEncryptedSecretSpace = (keyHex, enIds) ->
    log "getEncryptedSecretSpace"
    secretSpace = await spaceManager.getSpaceFor(keyHex, enIds)
    secretSpaceString = JSON.stringify(secretSpace)
    return await encrypt(secretSpaceString, keyHex) 

export getEncryptedSubSpace = (keyHex, fromId, enIds) ->
    log "getEncryptedSubSpace"
    subSpace = await spaceManager.getSubSpaceFor(keyHex, fromId, enIds)
    subSpaceString = JSON.stringify(subSpace)
    return await encrypt(subSpaceString, keyHex) 

############################################################
export setEncryptedSecret = (nodeId, secretId, secretPlain, enIds) ->
    log "setEncryptedSecret"
    ourSecret = await encrypt(secretPlain, nodeId)
    await spaceManager.setSecret(nodeId, secretId, ourSecret, enIds)
    return

export shareEncryptedSecretTo = (fromId, shareToId, secretId, secretPlain, isOneTime, enIds) ->
    log "shareEncryptedSecretTo"
    theirSecret = await encrypt(secretPlain, shareToId)
    await spaceManager.setSharedSecret(shareToId, fromId, secretId, theirSecret, isOneTime, enIds)
    return

#endregion
