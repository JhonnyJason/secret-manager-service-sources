############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authenticationmodule")
#endregion

############################################################
import * as secUtl from "secret-manager-crypto-utils"
import * as timestampVerifier from "./validatabletimestampmodule.js"
import * as authCodeManager from "./authcodemodule.js"
import * as blocker from "./blocksignaturesmodule.js"

############################################################
export initialize = ->
    log "initialize"
    #Implement or Remove :-)
    return

############################################################
#region exposedFunctions
export authenticateRequest = (req) ->
    log "authenticateRequest"

    # log req.path
    # severe pfush :-(
    switch req.path
        when "/getNodeId" then return next()

    data = req.body
    idHex = data.publicKey
    sigHex = data.signature
    timestamp = data.timestamp

    try

        if !timestamp then throw new Error("No Timestamp!") 
        if !sigHex then throw new Error("No Signature!")
        if !idHex then throw new Error("No Public key!")

        olog data
        # olog idHex
        # olog sigHex
        # olog timestamp

        # assert that the signature has not been used yet
        blocker.assertAndBlock(sigHex)

        # will throw if timestamp is not valid 
        timestampVerifier.assertValidity(timestamp) 
        
        delete data.signature
        content = req.path+JSON.stringify(data)

        verified = await secUtl.verify(sigHex, idHex, content)
        if !verified then throw new Error("Invalid Signature!")
        else next()
    catch err then throw new Error("Error on authenticateRequest! #{err.message}")
    return
