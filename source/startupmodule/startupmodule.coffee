import * as state from "cached-persistentstate"
import * as defaultState from "./defaultstate"
import { persistentStateOptions } from "./configmodule"
persistentStateOptions.defaultState = defaultState
state.initialize(persistentStateOptions)

############################################################
sci = null


############################################################
export initialize = ->
    sci = allModules.scimodule
    return


############################################################
export serviceStartup = ->
    sci.prepareAndExpose()
    return

