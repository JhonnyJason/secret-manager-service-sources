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
crypto = require("crypto")
elliptic = require("elliptic")
Ber = require('asn1').Ber
sshpk = require("sshpk")

############################################################
securitymodule.initialize = () ->
    log "securitymodule.initialize"
    return

############################################################
#region internalFunctions
printTag = (reader) -> log "0x"+reader.peek().toString(16)


stripKeyBanners = (fullKey) ->
    fullKey = fullKey.replace(/\s+/g,"")
    # log fullOpenSSLKey
    tokens = fullKey.split("-")
    
    maxToken = ""
    maxTokenSize = 0
    for token in tokens
        if maxTokenSize < token.length
            maxTokenSize = token.length
            maxToken = token
    
    # log maxToken
    return maxToken

readOpenSSHEd25519Key = (fullOpenSSHKey) ->

    key = sshpk.parseKey(opensshpriv, "pem")
    log " - - - - - "
    log "openssh:"
    log key.type
    log key.size
    log key.curve
    log key.toString("pem")
    log " - "
    log key.source.part.A.data.toString("hex")
    log key.source.part.k.data.toString("hex")

    log " - - - - - "
    log "openssl:" 
    key = sshpk.parseKey(privone, "pem")
    log key.type
    log key.size
    log key.curve
    log key.toString("pem")
    log " - " 
    log key.source.part.A.data.toString("hex")
    log key.source.part.k.data.toString("hex")

    log " - - - - - "
    log "selfparsed privone:"
    actualKey = readOpenSSLEd25519Key(privone)
    log actualKey
    # olog key.source
    process.exit(0)
    # base64Key = stripKeyBanners(fullOpenSSHKey)
    # buffer = Buffer.from(base64Key, "base64")

    # log buffer.toString("hex")
    
    # reader = new Ber.Reader(buffer)
    # printTag reader

    return "asd"

readOpenSSLEd25519Key = (fullOpenSSLKey) ->
    base64Key = stripKeyBanners(fullOpenSSLKey)
    buffer = Buffer.from(base64Key, "base64")

    # log buffer.toString("hex")
    
    reader = new Ber.Reader(buffer);

    if reader.peek() != 0x30 then throw new Error("Key does not Start with Sequence!")
    reader.readSequence()
    if reader.peek() != 0x2 then throw new Error("First data is not an Integer")
    reader.readInt()
    if reader.peek() != 0x30 then throw new Error("Second data is not a Sequence!")
    reader.readSequence()    
    if reader.peek() != 0x6 then throw new Error("Third data is not an Object Identifier!")
    reader.readOID()
    if reader.peek() != 0x4 then throw new Error("Fourth data is not an Octed String!")
    buffer = Buffer.alloc(64)
    buffer = reader.readString(Ber.OctedString, buffer)

    readString = buffer.toString("hex")
    # log readString
    if readString.length == 68 then return readString.slice(4)
    if readString.length == 64 then return readString
    throw new Error("Read Private Key has invalid length of: " + readString.length)
    return



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
    # try privateKey = readOpenSSLEd25519Key(privone)
    # catch err then log err

    try otherPrivateKey = readOpenSSHEd25519Key(opensshpriv)
    catch err then log err

    log privateKey
    process.exit(0)

    # EC = elliptic.ec
    # ed25519 = new EC('ed25519')

    # nativeKey = crypto.generateKeyPair("ed25519")
    # olog nativeKey

    # process.exit(0)

    # promisedKey = await new Promise (resovle, reject) ->
    #     crypto.createPrivateKey("ed25519", null, (err, pub, priv) -> resolve({pub, priv}))
    #     return
    
    # olog promisedKey  

    # process.exit(0)

    # if (reader.peek() == Ber.)
    #     log(reader.readInt());

    #|Type(1byte)|Length(1byte)|Value(xbyte)|
    #Type: |class(2bit)|form(1bit)|tag(5bit)|
    # Type: 00 1 10000
    # Type: 00 0 00001
    
    # reader = new Ber.Reader(Buffer.from([0x30, 0x03, 0x01, 0x01, 0x00]));
    # reader.readSequence();

    # log('Sequence len: ' + reader.length);
    # if (reader.peek() == Ber.Boolean)
    #     log(reader.readBoolean());

    process.exit(0)

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