securitymodule = {}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["securitymodule"]?  then console.log "[securitymodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
secUtl = require("secret-manager-crypto-utils")
timestampVerifier = require("./validatabletimestampmodule")


############################################################
#region exposedFunctions
securitymodule.authenticateRequest = (req, res, next) ->
    log "securitymodule.authenticate"
    
    data = req.body
    idHex = data.publicKey
    sigHex = data.signature
    timestamp = data.timestamp

    if !timestamp then throw new Error("No Timestamp!") 
    if !sigHex then throw new Error("No Signature!")
    if !idHex then throw new Error("No Public key!")

    # will throw if timestamp is not valid 
    timestampVerifier.assertValidity(timestamp) 
    
    delete data.signature
    content = req.path+JSON.stringify(data)

    try
        verified = await secUtl.verify(sigHex, idHex, content)
        if !verified then throw new Error("Invalid Signature!")
        else next()
    catch err then throw new Error("Error on Verify! " + err)
    return


securitymodule.encrypt = (content, keyHex) ->
    log "securitymodule.encrypt"
    salt = secUtl.createRandomLengthSalt()
    content = salt + content
    # log "prepended salt: " + content
    # log "separation code: " + content.charCodeAt(salt.length - 1)  
    secrets = await secUtl.asymetricEncrypt(content, keyHex)

    log "- - - secrets: "
    olog secrets
    return secrets
    
#endregion

module.exports = securitymodule