'==============================================================================
'
'  PowerStrip library
'  pstrip.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#If Not %Def(%IS_HOST_APP)
Declare Function ps_init(monitor_index As Long) Common As Long
Declare Function ps_reset(monitor_index As Long) Common As Long
Declare Function ps_get_monitor_timing(monitor_index As Long) Common As String
Declare Function ps_set_monitor_timing(monitor_index As Long, monitor_timing As AsciiZ) Common As Long
Declare Function ps_set_refresh(monitor_index As Long, Refresh As Long) Common As Long
Declare Function ps_set_modeline_list(monitor_index As Long, m() As MODELINE) Common As Long
Declare Function ps_create_mode(monitor_index As Long, monitor_timing As AsciiZ) Common As Long
Declare Function ps_set_timing(m As MODELINE, monitor_index As Long) Common As Long
Declare Function ps_get_timing(m As MODELINE, monitor_index As Long) Common As Long
Declare Function ps_monitor_index(display_name As String) Common As Long
#EndIf
