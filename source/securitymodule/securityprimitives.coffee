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
crypto = require("crypto")
noble = require("noble-ed25519")

############################################################
utl = null

############################################################
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

############################################################
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

#endregion

############################################################
#region symetricEncryption
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