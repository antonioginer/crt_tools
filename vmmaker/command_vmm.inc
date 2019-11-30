'============================================================
'  Constants
'============================================================

%RESULT_FAIL         =  0
%RESULT_SUCCESS      =  1
%RESULT_EXIT         = -1
%RESULT_SYNTAX_ERROR = -2

$CMD_HELP             = "help"

$CMD_EXIT             = "exit"

$CMD_DISPLAY          = "display"
  $DI_INIT            = "init"
  $DI_RESTART         = "restart"

$CMD_EDID             = "edid"
  $ED_CREATE          = "create"
  $ED_START           = "start"
  $ED_STOP            = "stop"
  $ED_READ            = "read"

$CMD_MODE             = "mode"
  $MD_ADD             = "add"
  $MD_DEL             = "del"
  $MD_CALC            = "calc"

$CMD_MODELIST         = "modelist"
  $ML_BUILD           = "build"
  $ML_RESET           = "reset"
  $ML_INSTALL         = "install"
  $ML_UNINSTALL       = "uninstall"
  $ML_IMPORT          = "import"
  $ML_EXPORT          = "export"
  $ML_LIST            = "list"
  $ML_ENUM            = "enum"

$CMD_CONFIG           = "config"

$CMD_CSYNC            = "csync"
  $CS_ENABLE          = "enable"
  $CS_DISABLE         = "disable"
