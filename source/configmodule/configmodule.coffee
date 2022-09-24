############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("configmodule")
#endregion

############################################################
import fs from "fs"
import path from "path"

############################################################
c = {}

############################################################
export readConfig = ->
    configFileName = "config.json"
    configFilePath = path.resolve(process.cwd(), configFileName)
    try 
        configFile = fs.readFileSync(configFilePath, "utf8")
        c = JSON.parse(configFile)
        ## TODO find a better way than this...
        if c.persistentStateOptions? then persistentStateOptions = c.persistentStateOptions
        if c.validationTimeFrameMS? then validationTimeFrameMS = c.validationTimeFrameMS
        if c.closureHeartbeatIntervalMS? then closureHeartbeatIntervalMS = c.closureHeartbeatIntervalMS
    catch err then log("Error when reading config file: #{err.message}") 
    return


############################################################
export persistentStateOptions = {
    basePath: "../state"
    maxCacheSize: 128
}

export validationTimeFrameMS = 10000
export closureHeartbeatIntervalMS = 60000
export initialGetNodeIdAuthCode = "deadbeefcafebabedeadbeefcafebabedeadbeefcafebabedeadbeefcafebabe"
export initialOpenSecretSpaceAuthCode = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"