############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authcodemodule")
#endregion

############################################################
import {randomBytes} from "crypto"
import * as dataCache from "cached-persistentstate"
import * as serviceCrypto from "./servicekeysmodule.js"
import { initialGetNodeIdAuthCode, initialOpenSecretSpaceAuthCode } from "./configmodule.js"

############################################################
authCodeStore = null

############################################################
export initialize = ->
    log "initialize"
    authCodeStore = dataCache.load("authCodeStore")
    if authCodeStore.meta? then await validateAuthCodeStore()
    else 
        authCodeStore.meta = {}
        authCodeStore.authCodes = {}
        authCodeStore.publicAuthCodeActions = {}
        setPublicAuthCode("getNodeId", initialGetNodeIdAuthCode)
        setPublicAuthCode("openSecretSpace", initialOpenSecretSpaceAuthCode)
    return

############################################################
#region internalFunctions

setPublicAuthCode = (action, authCode) ->
    return unless action and authCode
    return unless authCode.length and authCode.length == 64

    if authCodeStore.publicAuthCodeActions[action]? 
        oldCode = authCodeStore.publicAuthCodeActions[action]
        delete authCodeStore.authCodes[oldCode]

    authCodeStore.authCodes[authCode] = { action }
    authCodeStore.publicAuthCodeActions[action] = authCode
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

signAndSaveAuthCodeStore = ->
    log "validateAuthCodeStore"
    authCodeStore.meta.serverSig = ""
    authCodeStore.meta.serverPub = serviceCrypto.getPublicKeyHex()
    jsonString = JSON.stringify(authCodeStore)
    signature = await serviceCrypto.sign(jsonString)
    authCodeStore.meta.serverSig = signature
    dataCache.save("authCodeStore")
    return

############################################################
createNewAuthCode = ->
    newAuthCode = randomBytes(32).toString("hex")
    while authCodeStore.authCodes[newAuthCode]? 
        newAuthCode = randomBytes(32).toString("hex")
    return newAuthCode

#endregion

############################################################
export generateAuthCode = (action, creator) ->
    authCode = createNewAuthCode()    
    authCodeStore.authCodes[authCode] = { action, creator }
    await signAndSaveAuthCodeStore()
    return authCode

export processRequest = (req) ->
    log "processRequest"
    action = req.path.slice(1)
    authCode = req.body.authCode
    log authCode
    authObj = authCodeStore.authCodes[authCode]
    if !authObj? then throw new Error("Invalid AuthCode!")
    log action
    olog authObj
    if authObj.action != action then throw new Error("Invalid AuthCode!")
    
    #when there is a creator then it is not a public authCode
    if authObj.creator?
        # if the key is not the GodKey then it is a Master Key and thus owner of the action
        # if the key is a GodKey it the action does not have a specific owner
        if serviceCrypto.isNotGod(authObj.creator) then req.body.owner = authObj.creator
        #when it is not a public authCode then we only use it once - thus delete it here
        delete authCodeStore.authCodes[authCode]
        signAndSaveAuthCodeStore()
    return

