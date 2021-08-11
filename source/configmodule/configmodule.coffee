configmodule = {name: "configmodule"}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["configmodule"]?  then console.log "[configmodule]: " + arg
    return

############################################################
configmodule.initialize = () ->
    log "configmodule.initialize"
    return

############################################################
configmodule.persistentStateRelativeBasePath = "../state"
configmodule.numberOfChachedEntries = 64
configmodule.timestampValidityFrameMS = 20000

export default configmodule

# // webpack                      ^5.36.0  →  ^5.50.0     
# // webpack-cli                   ^4.6.0  →   ^4.7.2     
# // noble-ed25519                 ^1.0.2  →   ^1.2.5     
# // secret-manager-crypto-utils    0.0.5  →    0.0.6