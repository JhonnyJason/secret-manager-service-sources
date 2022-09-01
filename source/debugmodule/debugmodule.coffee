import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = 
    unbreaker: true
    # blocksignaturesmodule: true
    # configmodule: true
    notificationhooksmodule: true
    # persistentstatemodule: true
    scimodule: true
    # secretencryptionmodule: true
    # secretstoremodule: true
    secretspacemanagermodule: true
    securitymodule: true
    # servicekeysmodule: true
    startupmodule: true
    
addModulesToDebug(modulesToDebug)