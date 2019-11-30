'==============================================================================
'
'  VideoModeMaker
'  user.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

$USER_MODE_LIST = "user_modes.ini"

'============================================================
'  Types
'============================================================

Type USER_OPTIONS
  list_user_modes As Long
  mode_list As AsciiZ * 256
End Type

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function user_get_modes(mdb As IMODE_DB, options As USER_OPTIONS) Common As Long
Declare Function user_get_default_options(options As USER_OPTIONS) Common As Long
#EndIf
