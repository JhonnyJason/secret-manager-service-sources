import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = 
    unbreaker: true
    # configmodule: true
    # persistentstatemodule: true
    scimodule: true
    # secrethandlermodule: true
    # secretstoremodule: true
    # securitymodule: true
    startupmodule: true
    
addModulesToDebug(modulesToDebug)