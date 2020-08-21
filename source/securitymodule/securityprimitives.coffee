securityprimitives = {name: "securityprimitives"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["securityprimitives"]?  then console.log "[securityprimitives]: " + arg
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

signingKey = """-----BEGIN PRIVATE KEY-----
    MC4CAQAwBQYDK2VwBCIEIF/l8dkC1rQuVbbk5AHph8PyvH+V0zGIhj3pF2C31YSS
    -----END PRIVATE KEY-----"""
#endregion

############################################################
crypto = require("crypto")
noble = require("noble-ed25519")

############################################################
utl = null

############################################################
securityprimitives.initialize = () ->
    log "securityprimitives.initialize"
    utl = allModules.bufferutilmodule
    return

############################################################
#region internalFunctions
doHash = (message) ->
    hasher = crypto.createHash("sha512")
    hasher.update(message)
    hash = hasher.digest()
    return hash

doAsymetricEncrypt = (hashBuffer, privateKeyBuffer) ->
    
    ecKeyObject = ec.keyFromPrivate(privateKeyBuffer)
    edKeyObject = ed.keyFromSecret(privateKeyBuffer)
    ecKeyObject.inspect()
    edKeyObject.inspect()
    return "asd 1231"
    # log "- - - "
    # for label,content of ecKeyObject
    #     log label

    # log "- - - "
    # for label,content of edKeyObject
    #     log label
    # log "- - - "

    # log ecKeyObject.priv.toString(16)
    # log edKeyObject.priv().toString(16)

    # log keyObject.secret().toString("hex")

    ecSignature = ecKeyObject.sign(hashBuffer)
    for label,content of ecSignature
        log label
    log "- - - "
    derSignature = ecSignature.toDER()
    signature = Buffer.from(derSignature).toString("hex") 
    return signature
    # edSignature = edKeyObject.sign(hashBuffer).toHex()
    # return edSignature

    # log privateKeyBuffer.toString("hex")
    # olog keyObject.getPrivate().toString(16)

    # keyObject = ed25519.keyFromSecret(privateKeyBuffer.toString("hex"))
    # olog keyObject.getPrivate().toString(16)

    # return 

#endregion

############################################################
#region exposedFunctions
securityprimitives.createSignature = (message, signingKey) ->
    messageBuffer = Buffer.from(message, 'utf8')
    return crypto.sign(null, messageBuffer, signingKey) 

securityprimitives.verify = (signature, publicKey, message) ->
    signatureBuffer = Buffer.from(signature, "base64")
    messageBuffer  = Buffer.from(message, 'utf8')
    return crypto.verify(null, messageBuffer, verfificationKey, signatureBuffer)

securityprimitives.asymetricEncrypt = (messageHex, publicKeyHex) ->
    # a = Private Key
    # G = basePoint
    # B = aG = Public Key
    B = noble.Point.fromHex(publicKeyHex)
    BHex = publicKeyHex
    # log "BHex: " + BHex

    # M = message to encrypt (must be a point -> requires Point Matching function) = message point
    # n = new one-time secret (generated on sever and forgotten about)
    # A = nG = one time public key
    # nB = encryption key
    # X = M  + nB = encrypted message point
    # {A,X} = data to be stored for B

    # n = one-time secret
    nBytes = noble.utils.randomPrivateKey()
    nHex = utl.bytesToHex(nBytes)
    nBigInt = utl.bytesToBigInt(nBytes)
    # log nBigInt
    
    #A one time public key
    AHex = await securityprimitives.getPublic(nHex)
    
    nB = await B.multiply(nBigInt)
    
    M = noble.Point.fromHex(messageHex)
    log "M: " + M.toHex()

    X = M.add(nB)
    XHex = X.toHex()
    
    referencePoint = AHex
    encryptedMessagePoint = XHex

    return {referencePoint, encryptedMessagePoint}

securityprimitives.asymetricDecrypt = (secrets, privateKeyHex) ->
    # a = Private Key
    # G = basePoint
    # B = aG = Public Key

    # M = message to encrypt (must be a point -> requires Point Matching function) = message point
    # n = new one-time secret (generated on sever and forgotten about)
    # A = nG = one time public secret
    # nB = encryption key
    # X = M  + nB = encrypted message point
    # {A,X} = data to be stored for B

    # M = X - aA = M + nB - anG = M + naG - anG = M
    aBigInt = utl.hexToBigInt(privateKeyHex)

    AHex = secrets.referencePoint
    A = noble.Point.fromHex(AHex)
    XHex = secrets.encryptedMessagePoint
    X = noble.Point.fromHex(XHex)

    aA = await A.multiply(aBigInt)

    minusaA = new noble.Point(-aA.x, aA.y)
    M = X.add(minusaA)
    
    MHex = M.toHex()
    return MHex

securityprimitives.symetricEncrypt = (message, key) ->
    return gibbrish

securityprimitives.symetricDecrypt = (gibbrish, key) ->
    return message

securityprimitives.getPublic = (privateKey) ->
    # important! here it all is hex values
    # important! also the standard function uses a hash... 
    # if privateKey is a then the publicKey is not aG but a'G
    # return noble.getPublicKey(privateKey)
    a = utl.hexToBigInt(privateKey)
    G = noble.Point.BASE
    return G.multiply(a).toHex()

#endregion

module.exports = securityprimitives