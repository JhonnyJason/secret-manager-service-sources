import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = {
    authcodemodule: true
    # authenticationmodule: true
    # blocksignaturesmodule: true
    closuredatemodule: true
    # configmodule: true
    notificationhooksmodule: true
    # persistentstatemodule: true
    # scimodule: true
    # secretencryptionmodule: true
    # secretstoremodule: true
    secretspacemanagermodule: true
    # securitymodule: true
    # servicekeysmodule: true
    # startupmodule: true
}
    
addModulesToDebug(modulesToDebug)