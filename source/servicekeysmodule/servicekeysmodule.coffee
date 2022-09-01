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
    return

############################################################
export getPublicKeyHex = -> serviceState.publicKeyHex

############################################################
export sign = (content) ->
    keyHex = serviceState.secretKeyHex
    signatureHex = await secUtl.createSignatureHex(content, keyHex)
    return signatureHex

############################################################
export verify = (sigHex, content) ->
    pubHex = serviceState.publicKeyHex
    result = await secUtl.verifyHex(sigHex, pubHex, content)
    return result

export getSignedNodeId = ->
    result = {}
    result.serverNodeId = serviceState.publicKeyHex
    result.timestamp = validatableStamp.create()
    content = JSON.stringify(result)
    result.signature = await sign(content)
    return result