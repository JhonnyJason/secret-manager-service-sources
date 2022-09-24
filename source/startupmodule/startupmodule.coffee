############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("startupmodule")
#endregion


############################################################
import * as cachedData from "cached-persistentstate"

############################################################
import * as sci from "./scimodule.js"
import * as cfg from "./configmodule.js"
import * as defaultstate from "./defaultstate.js"

############################################################
cfg.readConfig()
cfg.persistentStateOptions.defaultstate = defaultstate

############################################################
cachedData.initialize(cfg.persistentStateOptions)

############################################################
export serviceStartup = ->
    sci.prepareAndExpose()
    log "startup complete - service is ready!"
    return

