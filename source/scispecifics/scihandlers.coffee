
scihandlers = {name: "scihandlers"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["scihandlers"]?  then console.log "[scihandlers]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
#region internalProperties
security = null
secretStore = null
secretHandler = null

#endregion

############################################################
scihandlers.initialize = ->
    log "scihandlers.initialize"
    security = allModules.securitymodule
    secretStore = allModules.secretstoremodule
    secretHandler = allModules.secrethandlermodule

    return

############################################################
scihandlers.authenticate = (req, res, next) ->
    try
        log req.path
        olog req.body
        security.assertValidTimestamp(req.body.timestamp)
        await security.authenticate(req.body, req.path)
        next()
    catch err then res.send({error: err.stack})
    return

############################################################
#region handlerFunctions
scihandlers.addNodeId = (publicKey, timestamp, signature) ->
    log "addNodeId"
    secretStore.addNodeId(publicKey)
    return {ok:true}

############################################################
scihandlers.getSecretSpace = (publicKey, timestamp, signature) ->
    log "getSecretSpace"
    encryptedSpace = await secretHandler.getEncryptedSecretSpace(publicKey)
    return encryptedSpace

scihandlers.getSecret = (publicKey, secretId, timestamp, signature) ->
    log "getSecret"
    secret = secretStore.getSecret(publicKey, secretId)
    return secret

############################################################
scihandlers.setSecret = (publicKey, secretId, secret, timestamp, signature) ->
    log "setSecret"
    await secretHandler.setSecret(publicKey, secretId, secret)
    return {ok:true}

scihandlers.deleteSecret = (publicKey, secretId, timestamp, signature) ->
    log "deleteSecret"
    secretStore.deleteSecret(publicKey, secretId)
    return {ok:true}

############################################################
scihandlers.startAcceptingSecretsFrom = (publicKey, fromId, timestamp, signature) ->
    log "startAcceptingSecretsFrom"
    await secretStore.addSubSpaceFor(publicKey, fromId)
    return {ok:true}

scihandlers.stopAcceptingSecretsFrom = (publicKey, fromId, timestamp, signature) ->
    log "stopAcceptingSecretsFrom"
    await secretStore.removeSubSpaceFor(publicKey, fromId)
    return {ok:true}

############################################################
scihandlers.shareSecretTo = (publicKey, shareToId, secretId, secret, timestamp, signature) ->
    log "shareSecretTo"
    await secretHandler.shareSecretTo(publicKey, shareToId, secretId, secret)
    return {ok:true}

scihandlers.deleteSharedSecret = (publicKey, sharedToId, secretId, timestamp, signature) ->
    log "deleteSharedSecret"
    secretStore.deleteSharedSecret(sharedToId, publicKey, secretId)
    return {ok:true}


#endregion exposed functions

export default scihandlers