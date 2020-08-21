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

addBanners = (pubKey) ->
    return """
    -----BEGIN PUBLIC KEY-----
    #{pubKey}
    -----END PUBLIC KEY-----
    """

############################################################
base64Key = (fullPEMKey) -> rawKey(fullPEMKey).toString("base64")
hexKey = (fullPEMKey) -> rawKey(fullPEMKey).toString("hex")

############################################################
rawKey = (fullPEMKey) ->
    keyObject = sshpk.parseKey(fullPEMKey, "pem")
    return keyObject.source.part.k.data

#endregion

############################################################
#region exposedFunctions
keyutilmodule.stripKeyBanners = stripBanners
keyutilmodule.addKeyBanners = addBanners
keyutilmodule.formatKey = addBanners

keyutilmodule.extractRawKeyBuffer = rawKey
keyutilmodule.extractRawKeyBase64 = base64Key
keyutilmodule.extractRawKeyHex = hexKey

#endregion

module.exports = keyutilmodule