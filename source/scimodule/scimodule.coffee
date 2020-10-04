scimodule = {name: "scimodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["scimodule"]?  then console.log "[scimodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
#region node_modules
require('systemd')
express = require('express')
bodyParser = require('body-parser')
#endregion

############################################################
#region internalProperties
bot = null
cfg = null
security = null
secretStore = null
secretHandler = null

############################################################
app = null
#endregion

############################################################
scimodule.initialize = () ->
    log "scimodule.initialize"
    bot = allModules.telegrambotmodule
    cfg = allModules.configmodule
    security = allModules.securitymodule
    secretStore = allModules.secretstoremodule
    secretHandler = allModules.secrethandlermodule

    app = express()
    app.use bodyParser.urlencoded(extended: false)
    app.use bodyParser.json()
    return

############################################################
#region internalFunctions
attachSCIFunctions = ->
    log "attachSCIFunctions"

    app.post "/addNodeId", onAddNodeId 
    
    app.post "/getSecretSpace", onGetSecretSpace
    app.post "/getSecret", onGetSecret
    app.post "/setSecret", onSetSecret
    app.post "/deleteSecret", onDeleteSecret

    app.post "/startAcceptingSecretsFrom", onStartAcceptingSecretsFrom
    app.post "/stopAcceptingSecretsFrom", onStopAcceptingSecretsFrom

    app.post "/startSharingSecretTo", onStartSharingSecretTo
    app.post "/stopSharingSecretTo", onStopSharingSecretTo
    
    return

############################################################
#region communicationHandlers
onAddNodeId = (req, res) ->
    log "onAddNodeId"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        secretStore.addNodeId(data.publicKey)

        response.ok = true
        res.send(response)
    catch err
        log "Error in onAddNodeId!"
        log err
        res.send(err)
    return

onGetSecretSpace = (req, res) ->
    log "onGetSecretSpace"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        space = await secretHandler.getEncryptedSecretSpace(data.publicKey)
        res.send(space)
    catch err
        log "Error in onGetSecretSpace!"
        log err
        res.send(err)
    return

onGetSecret = (req, res) ->
    log "onGetSecret"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        response = secretStore.getSecret(data.publicKey, data.secretId)

        res.send(response)
    catch err
        log "Error in onGetSecret!"
        log err
        res.send(err)
    return

onSetSecret = (req, res) ->
    log "onSetSecret"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        await secretHandler.setSecret(data.secretId, data.secret, data.publicKey)
        
        response.ok = true
        res.send(response)
    catch err
        log "Error in onSetSecret!"
        log err
        res.send(err)
    return

onDeleteSecret = (req, res) ->
    log "onDeleteSecret"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        secretStore.deleteSecret(data.publicKey, data.secretId)

        response.ok = true
        res.send(response)
    catch err
        log "Error in onGetSecret!"
        log err
        res.send(err)
    return

onStartAcceptingSecretsFrom = (req, res) ->
    log "onStartAcceptingSecretsFrom"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        secretStore.startAcceptingSecretsFrom(data.publicKey, data.fromId)

        response.ok = true
        res.send(response)
    catch err
        log "Error in onStartAcceptingSecretsFrom!"
        log err
        res.send(err)
    return

onStopAcceptingSecretsFrom = (req, res) ->
    log "onStopAcceptingSecretsFrom"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        secretStore.stopAcceptingSecretsFrom(data.publicKey, data.fromId)

        response.ok = true
        res.send(response)
    catch err
        log "Error in onStopAcceptingSecretsFrom!"
        log err
        res.send(err)
    return

onStartSharingSecretTo = (req, res) ->
    log "onStartSharingSecretTo"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        secretStore.startSharingSecretTo(data.publicKey, data.shareToId, data.secretId)

        response.ok = true
        res.send(response)
    catch err
        log "Error in onStartSharingSecretTo!"
        log err
        res.send(err)
    return

onStopSharingSecretTo = (req, res) ->
    log "onStopSharingSecretTo"
    response = {}
    try
        data = req.body
        olog data

        await security.authenticate(data)
        secretStore.stopSharingSecretTo(data.publicKey, data.sharedToId, data.secretId)

        response.ok = true
        res.send(response)
    catch err
        log "Error in onStopSharingSecretTo!"
        log err
        res.send(err)
    return

#endregion

#################################################################
listenForRequests = ->
    log "listenForRequests"
    if process.env.SOCKETMODE
        app.listen "systemd"
        log "listening on systemd"
    else
        port = process.env.PORT || cfg.defaultPort
        app.listen port
        log "listening on port: " + port
    return

#endregion

############################################################
#region exposedFunctions
scimodule.prepareAndExpose = ->
    log "scimodule.prepareAndExpose"
    attachSCIFunctions()
    listenForRequests()
    return
    
#endregion exposed functions

export default scimodule