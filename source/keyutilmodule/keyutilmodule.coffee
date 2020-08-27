keyutilmodule = {name: "keyutilmodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["keyutilmodule"]?  then console.log "[keyutilmodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
sshpk = require("sshpk")

############################################################
keyutilmodule.initialize = () ->
    log "keyutilmodule.initialize"
    return

############################################################
#region internalFunctions
stripBanners = (fullKey) ->
    ## we assume the key is the largest string between '-'s
    fullKey = fullKey.replace(/\s+/g,"")
    tokens = fullKey.split("-")
    
    maxToken = ""
    maxTokenSize = 0
    for token in tokens
        if maxTokenSize < token.length
            maxTokenSize = token.length
            maxToken = token
    
    return maxToken

addPublicBanners = (pubKey) ->
    return """
    -----BEGIN PUBLIC KEY-----
    #{pubKey}
    -----END PUBLIC KEY-----
    """

addPrivateBanners = (privKey) ->
    return """
    -----BEGIN PRIVATE KEY-----
    #{privKey}
    -----END PRIVATE KEY-----
    """

############################################################
base64PublicKey = (fullPEMKey) -> rawPublicKey(fullPEMKey).toString("base64")
hexPublicKey = (fullPEMKey) -> rawPublicKey(fullPEMKey).toString("hex")

base64PrivateKey = (fullPEMKey) -> rawPrivateKey(fullPEMKey).toString("base64")
hexPrivateKey = (fullPEMKey) -> rawPrivateKey(fullPEMKey).toString("hex")

############################################################
rawPrivateKey = (fullPEMKey) ->
    keyObject = sshpk.parseKey(fullPEMKey, "pem")
    return keyObject.source.part.k.data

rawPublicKey = (fullPEMKey) ->
    keyObject = sshpk.parseKey(fullPEMKey, "pem")
    return keyObject.part.A.data

#endregion

############################################################
#region exposedFunctions
keyutilmodule.stripKeyBanners = stripBanners

keyutilmodule.addPublicKeyBanners = addPublicBanners
keyutilmodule.formatPublicKey = addPublicBanners

keyutilmodule.addPrivateKeyBanners = addPrivateBanners
keyutilmodule.formatPrivateKey = addPrivateBanners

keyutilmodule.extractRawPublicKeyBuffer = rawPublicKey
keyutilmodule.extractRawPublicKeyBase64 = base64PublicKey
keyutilmodule.extractRawPublicKeyHex = hexPublicKey

keyutilmodule.extractRawPrivateKeyBuffer = rawPrivateKey
keyutilmodule.extractRawPrivateKeyBase64 = base64PrivateKey
keyutilmodule.extractRawPrivateKeyHex = hexPrivateKey

#endregion

module.exports = keyutilmodule