'==============================================================================
'
'  Console output box
'  log_console.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

%EDIT_BOX_SIZE = &H100000
%EDITLINE_SIZE = 256
%WM_CONSOLE = %WM_User + 2000

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function log_console_create() Common As String
Declare Function log_console_destroy() Common As Long
Declare Function log_console_gui_init(h_dialog As Long, idc As Long, x As Long, y As Long, c_width As Long, c_height As Long) Common As Long
Declare Function log_console_gui_resize(c_width As Long, c_height As Long) Common As Long
Declare Function log_console_update() Common As Long
Declare Function log_console_get() Common As String
Declare Function clog(t As String) Common As Long
#EndIf
