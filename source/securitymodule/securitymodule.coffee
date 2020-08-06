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
crypto = require("crypto")
elliptic = require("elliptic")

############################################################
securitymodule.initialize = () ->
    log "securitymodule.initialize"
    return

############################################################
#region internalFunctions
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

#endregion

############################################################
#region exposedFunctions
securitymodule.test = ->
    log "securitymodule.test"
    EC = elliptic.ec
    ed25519 = new EC('ed25519')
    
    # privoneBase64 = "MC4CAQAwBQYDK2VwBCIEIF/l8dkC1rQuVbbk5AHph8PyvH+V0zGIhj3pF2C31YSS"
    # privtwoBase64 = "MC4CAQAwBQYDK2VwBCIEIABaG2DGL4WE9niHPbdZtbmPOufhkqEJIibW1mlYsfXT"

    # buffer = Buffer.from(privoneBase64, 'base64');
    # privoneHex = buffer.toString('hex');
    # buffer = Buffer.from(privtwoBase64, 'base64');
    # privtwoHex = buffer.toString("hex")

    # log privoneHex
    # log privtwoHex
    
    # process.exit(0)
    serverKey = ed25519.keyFromPrivate(serverPriv)
    log serverKey.getPrivate().toString(16)

    key1 = ed25519.genKeyPair()
    key2 = ed25519.genKeyPair()
    key3 = ed25519.genKeyPair()

    #Diffie-Hellman
    
    # p = private key
    # mod = modulus
    # k = public key
    # msg = message

    # (msg * p) % mod = secret
    # msg = (secret * k) % mod  

    # sig = (hash(msg) * p ) % mod
    # -> (sig * k) % mod == hash(msg)

    log "- - -"
    # shared = p * k % mod 
    shared1 = key1.derive(key2.getPublic());
    shared2 = key2.derive(key1.getPublic());

    shared3 = key1.derive(serverKey.getPublic());
    shared4 = serverKey.derive(key1.getPublic())

    log key1.getPrivate().toString(16)
    log key2.getPrivate().toString(16)
    
    log "- - -"
    log(shared1.toString(16))
    log(shared2.toString(16))

    log(shared3.toString(16))
    log(shared4.toString(16))

    process.exit(0)

    log "- - -"
    shared13 = key1.getPublic().mul(key3.getPrivate())
    shared21 = key2.getPublic().mul(key1.getPrivate())
    shared32 = key3.getPublic().mul(key2.getPrivate())

    log(shared13.getX().toString(16))
    log(shared21.getX().toString(16))
    log(shared32.getX().toString(16))
    
    log "- - -"
    shared132 = shared13.mul(key2.getPrivate())
    shared213 = shared21.mul(key3.getPrivate())
    shared321 = shared32.mul(key1.getPrivate())

    log(shared132.getX().toString(16))
    log(shared213.getX().toString(16))
    log(shared321.getX().toString(16))

    return

authenticateTest = (data) ->
    log "authenticateTest"
    return

securitymodule.authenticate = (data) ->
    log "securitymodule.authenticate"

    verfificationKey = formatKey(data.publicKey)    

    signature = data.signature

    delete data.signature
    message = JSON.stringify(data)

    # createSignature(message)

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

securitymodule.encrypt = (message, key) ->
    log "securitymodule.encrypt"
    
    return

#endregion

module.exports = securitymodule