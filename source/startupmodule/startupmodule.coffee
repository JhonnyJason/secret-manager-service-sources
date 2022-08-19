############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("startupmodule")
#endregion


############################################################
import * as state from "cached-persistentstate"

############################################################
import *  as sci from "./scimodule.js"
import * as defaultState from "./defaultstate.js"
import { persistentStateOptions } from "./configmodule.js"

############################################################
persistentStateOptions.defaultState = defaultState
state.initialize(persistentStateOptions)

############################################################
export serviceStartup = ->
    sci.prepareAndExpose()
    log "startup complete - service is ready!"
    return

