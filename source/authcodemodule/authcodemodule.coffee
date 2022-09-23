############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authcodemodule")
#endregion

############################################################
import * as dataCache from "cached-persistentstate"
import * as serviceCrypto from "./servicekeysmodule.js"

############################################################
authCodeStore = null

############################################################
export initialize = ->
    log "initialize"
    authCodeStore = dataCache.load("authCodeStore")
    if authCodeStore.meta? then  validateAuthCodeStore()
    else 
        authCodeStore.meta = {}
        authCodeStore.authCodes = {}
    return

############################################################
validateAuthCodeStore = ->
    log "validateAuthCodeStore"
    meta = authCodeStore.meta
    signature = meta.serverSig
    if !signature then throw new Error("No signature in authCodeStore.meta !")
    meta.serverSig = ""
    authCodeStoreString = JSON.stringify(authCodeStore)
    meta.serverSig = signature
    if(await serviceCrypto.verify(signature, authCodeStoreString)) then return
    else throw new Error("Invalid Signature in authCodestore.meta !")


############################################################
export assertActionIsLegal = (action, authCode) ->
    log "assertActionIsLegal"
    log "Not implemented yet!"
    ## TODO implement
    return 


############################################################
export getOwner = (owner) ->
    log "getOwner"
    log "Not implemented yet!"
    ## TOOD implement
    return ""

export processRequest = (req) ->
    action = req.path.slice(1)
    authCode = req.body.authCode
    ##TODO implement
    return

