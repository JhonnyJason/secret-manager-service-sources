secrethandlermodule = {name: "secrethandlermodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["secrethandlermodule"]?  then console.log "[secrethandlermodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
#region localModules
secretStore = null
security = null

#endregion

############################################################
secrethandlermodule.initialize = () ->
    log "secrethandlermodule.initialize"
    secretStore = allModules.secretstoremodule
    security = allModules.securitymodule
    return

############################################################
#region exposedFunctions
secrethandlermodule.getEncryptedSecretSpace = (keyHex) ->
    log "secrethandlermodule.getEncryptedSecretSpace"
    bare = secretStore.getSecretSpace(keyHex)
    bareString = JSON.stringify(bare)
    return await security.encrypt(bareString, keyHex) 

secrethandlermodule.setSecret = (nodeId, secretId, secretPlain) ->
    log "secrethandlermodule.setSecret"
    ourSecret = await security.encrypt(secretPlain, nodeId)
    secretStore.setSecret(nodeId, secretId, ourSecret)
    return

secrethandlermodule.shareSecretTo = (fromId, shareToId, secretId, secretPlain) ->
    log "secrethandlermodule.shareSecretTo"
    theirSecret = await security.encrypt(secretPlain, shareToId)
    secretStore.setSharedSecret(shareToId, fromId, secretId, theirSecret)
    return

#endregion

module.exports = secrethandlermodule