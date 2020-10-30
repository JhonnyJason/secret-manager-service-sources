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
#region sampleKeyPairs
serverPriv = "5FE5F1D902D6B42E55B6E4E401E987C3F2BC7F95D33188863DE91760B7D58492"

opensshpriv = """
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACC2miVG9g2q/dN1JpTV+N5mFhL2OGrf8HBvMBvNUbmtGgAAAJB5LjWzeS41
    swAAAAtzc2gtZWQyNTUxOQAAACC2miVG9g2q/dN1JpTV+N5mFhL2OGrf8HBvMBvNUbmtGg
    AAAEC9MC44MnM5nYOrrqrsIAW/GhXJ9/dZ06Q9Pzvl+k1duraaJUb2Dar903UmlNX43mYW
    EvY4at/wcG8wG81Rua0aAAAACmxlbm55QG5vdmEBAgM=
    -----END OPENSSH PRIVATE KEY-----
    """
opensshpub = """
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaaJUb2Dar903UmlNX43mYWEvY4at/wcG8wG81Rua0a lenny@nova
    """

privone = """
    -----BEGIN PRIVATE KEY-----
    MC4CAQAwBQYDK2VwBCIEIF/l8dkC1rQuVbbk5AHph8PyvH+V0zGIhj3pF2C31YSS
    -----END PRIVATE KEY-----    
    """
privtwo = """
    -----BEGIN PRIVATE KEY-----
    MC4CAQAwBQYDK2VwBCIEIABaG2DGL4WE9niHPbdZtbmPOufhkqEJIibW1mlYsfXT
    -----END PRIVATE KEY-----
    """
pubone = """
    -----BEGIN PUBLIC KEY-----
    MCowBQYDK2VwAyEAxyJH+dZqAh5Fib0ZiLdfqn6FQnxZFEwdLSUlLUWM+fs=
    -----END PUBLIC KEY-----
    """    
pubtwo = """
    -----BEGIN PUBLIC KEY-----
    MCowBQYDK2VwAyEAPR4EQTQm/r/iLYNYEux8ixfAXMwpqtG6Z4HWoj4W+0w=
    -----END PUBLIC KEY-----    
    """
#endregion

############################################################
primitives = require("./securityprimitives")

############################################################
utl = null
bufUtl = null

############################################################
securitymodule.initialize = () ->
    log "securitymodule.initialize"
    utl = allModules.keyutilmodule
    bufUtl = allModules.bufferutilmodule
    primitives.initialize()
    return

############################################################
#region internalFunctions
createSignature = (content) ->
    log "securitymodule.createSignature"
    
    signingKey1 = """-----BEGIN PRIVATE KEY-----
        MC4CAQAwBQYDK2VwBCIEIF/l8dkC1rQuVbbk5AHph8PyvH+V0zGIhj3pF2C31YSS
        -----END PRIVATE KEY-----"""

    signingKey2 = """-----BEGIN PRIVATE KEY-----
        MC4CAQAwBQYDK2VwBCIEIABaG2DGL4WE9niHPbdZtbmPOufhkqEJIibW1mlYsfXT
        -----END PRIVATE KEY-----"""

    signature2 = crypto.sign(null, contentBuffer, signingKey2)

    log "signature 1: " + signature1.toString("base64")
    log "signature 2: " + signature2.toString("base64")
    return

#endregion

############################################################
#region exposedFunctions
securitymodule.assertValidTimestamp = (timestamp) ->
    return

securitymodule.authenticate = (data) ->
    log "securitymodule.authenticate"
    idHex = data.publicKey
    sigHex = data.signature
    if !sigHex then throw new Error("No Signature!")
    if !idHex then throw new Error("No Public key!")

    delete data.signature
    content = JSON.stringify(data)

    try
        verified = await primitives.verify(sigHex, idHex, content)
        if !verified then throw new Error("Invalid Signature!")
    catch err then throw new Error("Error on Verify! " + err)
    return

securitymodule.encrypt = (content, keyHex) ->
    log "securitymodule.encrypt"
    salt = primitives.createRandomLengthSalt()
    content = salt + content
    # log "prepended salt: " + content
    # log "separation code: " + content.charCodeAt(salt.length - 1)  
    secrets = await primitives.asymetricEncrypt(content, keyHex)

    log "- - - secrets: "
    olog secrets
    return secrets
    
#endregion

module.exports = securitymodule