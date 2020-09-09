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

#region internalProperties
algorithm = 'aes-256-cbc'
#endregion

############################################################
securityprimitives.initialize = () ->
    log "securityprimitives.initialize"
    utl = allModules.bufferutilmodule
    return

############################################################
#region internalFunctions
#region hashFunctions
sha512 = (content) ->
    hasher = crypto.createHash("sha512")
    hasher.update(content)
    hash = hasher.digest()
    return hash

sha256 = (content) ->
    hasher = crypto.createHash("sha256")
    hasher.update(content)
    hash = hasher.digest()
    return hash

#endregion

############################################################
hashToScalar = (hash) ->
    relevant = hash.slice(0, 32)
    relevant[0] &= 248
    relevant[31] &= 127
    relevant[31] |= 64
    return utl.bytesToBigInt(relevant)

############################################################
#region nativeVersions
hexRawToBase64ASN1 = -> throw new Error("hexRawToBase64ASN1 - Not implemented!")

verifyNative = (sigHex, keyHex) ->
    signatureBuffer = Buffer.from(sigBase64, "hex")
    contentBuffer  = Buffer.from(content, 'utf8')
    keyBase64 = hexRawTobase64ASN1(keyHex)
    return crypto.verify(null, contentBuffer, publicKey, signatureBuffer)

############################################################
createSignatureNative = (content, signingKey) ->
    contentBuffer = Buffer.from(content, 'utf8')
    return crypto.sign(null, contentBuffer, signingKey) 

#endregion

############################################################
verifyNoble = (sigHex, keyHex, content) ->
    log "verifyNoble"
    hashBuffer = sha256(content)
    hashHex = utl.bytesToHex(hashBuffer) 
    log hashHex
    verified = await noble.verify(sigHex, hashHex, keyHex)
    return verified

#endregion

############################################################
#region exposedFunctions
securityprimitives.createSignature = createSignatureNative 
securityprimitives.verify = verifyNoble

############################################################
#region asymetricEncryption
securityprimitives.asymetricEncrypt = (content, publicKeyHex) ->
    # a = Private Key
    # k = sha512(a) -> hashToScalar
    # G = basePoint
    # B = kG = Public Key
    B = noble.Point.fromHex(publicKeyHex)
    BHex = publicKeyHex
    # log "BHex: " + BHex

    # n = new one-time secret (generated on sever and forgotten about)
    # l = sha512(n) -> hashToScalar
    # lB = lkG = shared secret
    # key = sha512(lBHex)
    # X = symetricEncrypt(content, key)
    # A = lG = one time public reference point
    # {A,X} = data to be stored for B

    # n = one-time secret
    nBytes = noble.utils.randomPrivateKey()
    nHex = utl.bytesToHex(nBytes)

    lBigInt = hashToScalar(sha512(nBytes))
    # log lBigInt
    
    #A one time public key = reference Point
    AHex = await securityprimitives.getPublic(nHex)
    
    lB = await B.multiply(lBigInt)
    
    ## TODO generate AES key
    hash = sha512(lB.toHex())
    log "- - - "
    symkey = hash.toString("hex")
    log symkey
    
    gibbrish = securityprimitives.symetricEncryptHex(content, symkey)
    
    referencePoint = AHex
    encryptedContent = gibbrish

    return {referencePoint, encryptedContent}

securityprimitives.asymetricDecrypt = (secrets, privateKeyHex) ->
    # a = Private Key
    # k = sha512(a) -> hashToScalar
    # G = basePoint
    # B = kG = Public Key

    aBytes = utl.hexToBytes(privateKeyHex)
    kBigInt = hashToScalar(sha512(aBytes))
    
    # {A,X} = secrets
    # A = lG = one time public reference point 
    # klG = lB = kA = shared secret
    # key = sha512(kAHex)
    # content = symetricDecrypt(X, key)
    AHex = secrets.referencePoint
    A = noble.Point.fromHex(AHex)
    kA = await A.multiply(kBigInt)
    hash = sha512(kA.toHex())
    symkey = hash.toString("hex")

    gibbrishHex = secrets.encryptedContent
    content = securityprimitives.symetricDecryptHex(gibbrishHex,symkey)
    return content

securityprimitives.asymetricEncryptElligator = (contentHex, publicKeyHex) ->
    # a = Private Key
    # G = basePoint
    # B = aG = Public Key
    B = noble.Point.fromHex(publicKeyHex)
    BHex = publicKeyHex
    # log "BHex: " + BHex

    # M = content to encrypt (must be a point -> requires Point Matching function) = content point
    # n = new one-time secret (generated on sever and forgotten about)
    # A = nG = one time public key
    # nB = encryption key
    # X = M  + nB = encrypted content point
    # {A,X} = data to be stored for B

    # n = one-time secret
    nBytes = noble.utils.randomPrivateKey()
    nHex = utl.bytesToHex(nBytes)
    nBigInt = utl.bytesToBigInt(nBytes)
    # log nBigInt
    
    #A one time public key
    AHex = await securityprimitives.getPublic(nHex)
    
    nB = await B.multiply(nBigInt)
    
    M = noble.Point.fromHex(contentHex)
    log "M: " + M.toHex()

    X = M.add(nB)
    XHex = X.toHex()
    
    referencePoint = AHex
    encryptedContentPoint = XHex

    return {referencePoint, encryptedContentPoint}

securityprimitives.asymetricDecryptElligator = (secrets, privateKeyHex) ->
    # a = Private Key
    # G = basePoint
    # B = aG = Public Key

    ##TODO Elligator stdp
    # M = content to encrypt (must be a point -> requires Point Matching function) = content point
    # n = new one-time secret (generated on sever and forgotten about)
    # A = nG = one time public secret
    # nB = encryption key
    # X = M  + nB = encrypted content point
    # {A,X} = data to be stored for B

    # M = X - aA = M + nB - anG = M + naG - anG = M
    aBigInt = utl.hexToBigInt(privateKeyHex)

    AHex = secrets.referencePoint
    A = noble.Point.fromHex(AHex)
    XHex = secrets.encryptedContentPoint
    X = noble.Point.fromHex(XHex)

    aA = await A.multiply(aBigInt)

    minusaA = new noble.Point(-aA.x, aA.y)
    M = X.add(minusaA)
    
    MHex = M.toHex()
    return MHex

#endregion

############################################################
#region symetricEncryption
securityprimitives.symetricEncryptBase64 = (content, keyHex) ->
    ivHex = keyHex.substring(0, 32)
    ivBuffer = Buffer.from(ivHex, "hex")
    aesKeyHex = keyHex.substring(32,96)
    aesKeyBuffer = Buffer.from(aesKeyHex, "hex")
    # log "- - ivHex: "
    # log ivHex
    # log ivHex.length
    # log "- - aesKeyHex: "
    # log aesKeyHex
    # log aesKeyHex.length

    cipher = crypto.createCipheriv(algorithm, aesKeyBuffer, ivBuffer)
    gibbrish = cipher.update(content, 'utf8', 'base64')
    gibbrish += cipher.final('base64')
    return gibbrish

securityprimitives.symetricDecryptBase64 = (gibbrishBase64, keyHex) ->
    ivHex = keyHex.substring(0, 32)
    ivBuffer = Buffer.from(ivHex, "hex")
    aesKeyHex = keyHex.substring(32,96)
    aesKeyBuffer = Buffer.from(aesKeyHex, "hex")
    # log "- - ivHex: "
    # log ivHex
    # log ivHex.length
    # log "- - aesKeyHex: "
    # log aesKeyHex
    # log aesKeyHex.length

    decipher = crypto.createDecipheriv(algorithm, aesKeyBuffer, ivBuffer)
    content = decipher.update(gibbrishBase64, 'base64', 'utf8')
    content += decipher.final('utf8')
    return content

securityprimitives.symetricEncryptHex = (content, keyHex) ->
    ivHex = keyHex.substring(0, 32)
    ivBuffer = Buffer.from(ivHex, "hex")
    aesKeyHex = keyHex.substring(32,96)
    aesKeyBuffer = Buffer.from(aesKeyHex, "hex")
    # log "- - ivHex: "
    # log ivHex
    # log ivHex.length
    # log "- - aesKeyHex: "
    # log aesKeyHex
    # log aesKeyHex.length

    cipher = crypto.createCipheriv(algorithm, aesKeyBuffer, ivBuffer)
    gibbrish = cipher.update(content, 'utf8', 'hex')
    gibbrish += cipher.final('hex')
    return gibbrish

securityprimitives.symetricDecryptHex = (gibbrishHex, keyHex) ->
    ivHex = keyHex.substring(0, 32)
    ivBuffer = Buffer.from(ivHex, "hex")
    aesKeyHex = keyHex.substring(32,96)
    aesKeyBuffer = Buffer.from(aesKeyHex, "hex")
    # log "- - ivHex: "
    # log ivHex
    # log ivHex.length
    # log "- - aesKeyHex: "
    # log aesKeyHex
    # log aesKeyHex.length

    decipher = crypto.createDecipheriv(algorithm, aesKeyBuffer, ivBuffer)
    content = decipher.update(gibbrishHex, 'hex', 'utf8')
    content += decipher.final('utf8')
    return content

#endregion

############################################################
securityprimitives.createRandomLengthSalt = ->
    loop
        bytes = crypto.randomBytes(512)
        for byte,i in bytes when byte == 0
            return bytes.slice(0,i+1).toString("utf8")        

securityprimitives.removeSalt = (content) ->
    for char,i in content when char == "\0"
        return content.slice(i+1)
    throw new Error("No Salt termination found!")    

############################################################
securityprimitives.getPublic = (privateKey) ->
    # important! here it all is hex values
    # important! also the standard function uses a hash... 
    # if privateKey is a then the publicKey is not aG but a'G
    return await noble.getPublicKey(privateKey)
    # a = utl.hexToBigInt(privateKey)
    # G = noble.Point.BASE
    # return G.multiply(a).toHex()

#endregion

module.exports = securityprimitives