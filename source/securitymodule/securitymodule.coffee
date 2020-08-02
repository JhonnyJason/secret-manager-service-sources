securitymodule = {name: "securitymodule"}
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
crypto = require("crypto")

############################################################
securitymodule.initialize = () ->
    log "securitymodule.initialize"
    return

############################################################
formatKey = (pubKey) ->
    return """
    -----BEGIN PUBLIC KEY-----
    #{pubKey}
    -----END PUBLIC KEY-----
    """

createSignature = (message) ->
    log "securitymodule.createSignature"
    
    signingKey1 = """-----BEGIN PRIVATE KEY-----
        MC4CAQAwBQYDK2VwBCIEIF/l8dkC1rQuVbbk5AHph8PyvH+V0zGIhj3pF2C31YSS
        -----END PRIVATE KEY-----"""

    signingKey2 = """-----BEGIN PRIVATE KEY-----
        MC4CAQAwBQYDK2VwBCIEIABaG2DGL4WE9niHPbdZtbmPOufhkqEJIibW1mlYsfXT
        -----END PRIVATE KEY-----"""

    messageBuffer = Buffer.from(message, 'utf8')
    signature1 = crypto.sign(null, messageBuffer, signingKey1)
    signature2 = crypto.sign(null, messageBuffer, signingKey2)

    log "signature 1: " + signature1.toString("base64")
    log "signature 2: " + signature2.toString("base64")
    return

############################################################
securitymodule.authenticate = (data) ->
    log "securitymodule.authenticate"

    verfificationKey = formatKey(data.publicKey)    

    signature = data.signature

    delete data.signature
    message = JSON.stringify(data)

    createSignature(message)

    signatureBuffer = Buffer.from(signature, "base64")
    messageBuffer  = Buffer.from(message, 'utf8')

    verified = crypto.verify(null, messageBuffer, verfificationKey, signatureBuffer)
    log "verified is: " + verified
    
    if !verified then throw new Error("Invalid Signature!")
    return

# ############################################################
# authmodule.authenticate = (message, signature) ->
#     log "authmodule.authenticate"
#     signatureBuffer = Buffer.from(signature, "base64")
#     messageBuffer  = Buffer.from(message, 'utf8')

#     verified = crypto.verify(null, messageBuffer, verfificationKey, signatureBuffer)
#     log "verified is: " + verified
    
#     if !verified then throw new Error("Invalid Signature!")
#     return


module.exports = securitymodule