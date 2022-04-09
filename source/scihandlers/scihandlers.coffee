scihandlers = {}

############################################################
#region 
import * as security from "./securitymodule.js"
import * as secretStore from "./secretstoremodule"
import * as secretHandler from "./secrethandlermodule"

############################################################
scihandlers.authenticate = security.authenticateRequest

#endregion

############################################################
#region secretmanagementhandlers.coffee
############################################################
scihandlers.addNodeId = (publicKey, timestamp, signature) ->
    secretStore.addNodeId(publicKey)
    return {ok:true}



############################################################
scihandlers.getSecretSpace = (publicKey, timestamp, signature) ->
    encryptedSpace = await secretHandler.getEncryptedSecretSpace(publicKey)
    return encryptedSpace


############################################################
scihandlers.getSecret = (publicKey, secretId, timestamp, signature) ->
    secret = secretStore.getSecret(publicKey, secretId)
    return secret


############################################################
scihandlers.setSecret = (publicKey, secretId, secret, timestamp, signature) ->
    await secretHandler.setSecret(publicKey, secretId, secret)
    return {ok:true}


############################################################
scihandlers.deleteSecret = (publicKey, secretId, timestamp, signature) ->
    secretStore.deleteSecret(publicKey, secretId)
    return {ok:true}


############################################################
scihandlers.startAcceptingSecretsFrom = (publicKey, fromId, timestamp, signature) ->
    await secretStore.addSubSpaceFor(publicKey, fromId)
    return {ok:true}


############################################################
scihandlers.stopAcceptingSecretsFrom = (publicKey, fromId, timestamp, signature) ->
    await secretStore.removeSubSpaceFor(publicKey, fromId)
    return {ok:true}


############################################################
scihandlers.shareSecretTo = (publicKey, shareToId, secretId, secret, timestamp, signature) ->
    await secretHandler.shareSecretTo(publicKey, shareToId, secretId, secret)
    return {ok:true}


############################################################
scihandlers.deleteSharedSecret = (publicKey, sharedToId, secretId, timestamp, signature) ->
    secretStore.deleteSharedSecret(sharedToId, publicKey, secretId)
    return {ok:true}


############################################################
scihandlers.addSyncHook = (publicKey, secretId, serverURL, timestamp, signature) ->
    result = {}
    ###
    
{
    "ok": true
}


    ###
    return result


############################################################
scihandlers.addNotificationHook = (publicKey, type, specific, timestamp, signature) ->
    result = {}
    ###
    
{
    "ok": true
}


    ###
    return result


############################################################
scihandlers.getAuthCode = (publicKey, timestamp, signature) ->
    result = {}
    ###
    
{
    "ok": true
}

    ###
    return result


############################################################
scihandlers.addFriendServer = (authCode, serverURL, serverNodeId) ->
    result = {}
    ###
    
{
    "ok": true
}


    ###
    return result


############################################################
scihandlers.getNodeId = (authCode) ->
    result = {}
    ###
    
{
    "publicKey": "...",
    "timestamp": "...",
    "signature": "..."
}

    ###
    return result



#endregion



export default scihandlers
