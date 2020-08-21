bufferutilmodule = {name: "bufferutilmodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["bufferutilmodule"]?  then console.log "[bufferutilmodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
bufferutilmodule.initialize = () ->
    log "bufferutilmodule.initialize"
    return
    
############################################################
#region exposedFunctions
bufferutilmodule.bytesToHex = (bytes) -> Buffer.from(bytes).toString("hex")
bufferutilmodule.hexToBytes = (hex) -> Uint8Array.from(Buffer.from(hex, 'hex'))

bufferutilmodule.bytesToBigInt = (bytes) ->
    value = 0n
    for byte,i in bytes
        value += BigInt(byte) << (8n * BigInt(i))
    return value

bufferutilmodule.hexToBigInt = (hex) ->
    bytes = bufferutilmodule.hexToBytes(hex)
    bigInt = bufferutilmodule.bytesToBigInt(bytes)
    return bigInt

#endregion

module.exports = bufferutilmodule