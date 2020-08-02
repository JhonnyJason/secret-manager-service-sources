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
cfg = null
secretStore = null
security = null

############################################################
app = null
#endregion

############################################################
scimodule.initialize = () ->
    log "scimodule.initialize"
    cfg = allModules.configmodule
    secretStore = allModules.secretstoremodule
    security = allModules.securitymodule

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
    
    app.post "/startSharingSecretTo", onStartSharingSecretTo
    app.post "/stopSharingSecretTo", onStopSharingSecretTo
    app.post "/startSharingSecretSpaceTo", onStartSharingSecretSpaceTo
    app.post "/stopSharingSecretSpaceTo", onStopSharingSecretSpaceTo

    return

############################################################
#region communicationHandlers
onAddNodeId = (req, res) ->
    log "onAddNodeId"
    response = {}
    try
        data = req.body
        olog data
        
        ## TODO security.authenticate(data)
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

        ## TODO security.authenticate(data)
        space = secretStore.getSecretSpace(data.publicKey)

        ## space = security.encrypt(JSON.stringify(space), data.publicKey) 
        response.secretSpace = space
        res.send(response)
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
        ##TODO implement
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
        ##TODO implement
        res.send(response)
    catch err
        log "Error in onSetSecret!"
        log err
        res.send(err)
    return

onStartSharingSecretTo = (req, res) ->
    log "onStartSharingSecretTo"
    response = {}
    try
        data = req.body
        olog data
        ##TODO implement
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
        ##TODO implement
        res.send(response)
    catch err
        log "Error in onStopSharingSecretTo!"
        log err
        res.send(err)
    return

onStartSharingSecretSpaceTo = (req, res) ->
    log "onStartSharingSecretSpaceTo"
    response = {}
    try
        data = req.body
        olog data
        ##TODO implement
        res.send(response)
    catch err
        log "Error in onStartSharingSecretSpaceTo!"
        log err
        res.send(err)
    return

onStopSharingSecretSpaceTo = (req, res) ->
    log "onStopSharingSecretSpaceTo"
    response = {}
    try
        data = req.body
        olog data
        ##TODO implement
        res.send(response)
    catch err
        log "Error in onStopSharingSecretSpaceTo!"
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