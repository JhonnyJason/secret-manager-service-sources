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

secrethandlermodule.setSecret = (secretId, secretPlain, nodeId) ->
        log "secrethandlermodule.setSecret"
        ourSecret = await security.encrypt(secretPlain, nodeId)
        secretStore.setSecret(nodeId, secretId, ourSecret)
        sharedTo = secretStore.getSharedTo(nodeId, secretId)
        olog sharedTo
        for sharedToId in sharedTo when typeof sharedToId == "string"
            theirSecret = await security.encrypt(secretPlain, sharedToId)
            secretStore.setSharedSecret(sharedToId, nodeId, secretId, theirSecret)
        return

#endregion

module.exports = secrethandlermodule