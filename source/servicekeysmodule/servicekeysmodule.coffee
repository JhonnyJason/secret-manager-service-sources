############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("servicekeysmodule")
#endregion

############################################################
import * as cachedData from "cached-persistentstate"
import * as secUtl from "secret-manager-crypto-utils"

import * as validatableStamp from "./validatabletimestampmodule.js"

############################################################
serviceState = null
godKeyHex = null

############################################################
setReady = null
ready = new Promise (resolve) -> setReady = resolve 

############################################################
export initialize = ->
    log "initialize"
    serviceState = cachedData.load("serviceState")
    # olog serviceState
    
    if !serviceState.secretKeyHex
        kp = await secUtl.createKeyPairHex()
        serviceState.secretKeyHex = kp.secretKeyHex
        serviceState.publicKeyHex = kp.publicKeyHex
        cachedData.save("serviceState")
    
    # olog serviceState
    setReady(true)
    return

############################################################
export isNotGod = (keyHex) -> return keyHex != godKeyHex

############################################################
export getPublicKeyHex = -> serviceState.publicKeyHex

############################################################
export sign = (content) ->
    await ready
    keyHex = serviceState.secretKeyHex
    signatureHex = await secUtl.createSignatureHex(content, keyHex)
    return signatureHex

############################################################
export verify = (sigHex, content) ->
    await ready
    pubHex = serviceState.publicKeyHex
    result = await secUtl.verifyHex(sigHex, pubHex, content)
    return result

############################################################
export getSignedNodeId = ->
    await ready
    result = {}
    result.serverNodeId = serviceState.publicKeyHex
    result.timestamp = validatableStamp.create()
    content = JSON.stringify(result)
    result.signature = await sign(content)
    return result