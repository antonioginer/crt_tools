'==============================================================================
'
'  Display library
'  display.inc
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

#Include Once "win32api.inc"

'============================================================
'  Types
'============================================================

Type DISPLAY_OPTIONS
  device_key As AsciiZ * 128
  auto_extend_desktop As Long
End Type

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function display_init(device_key As AsciiZ) Common As Long
Declare Function display_get_current() Common As String
Declare Function display_restart(ByVal device_name As String, hwnd As Long, win_version As Long, options As DISPLAY_OPTIONS) Common As Long
Declare Function display_get_devices() Common As Long
Declare Function display_monitor_index_from_device(ByVal device_name As String) Common As Long
Declare Function display_rect_from_primary_monitor(primary_rect As RECT) Common As Long
Declare Function display_rect_from_window(hWnd As Long, display_rect As RECT) Common As String
Declare Function display_get_device_num Common As Long
Declare Function display_get_device_by_index(i As Long) Common As String
Declare Function display_get_device_key_by_index(i As Long) Common As String
Declare Function display_get_device_long_name_by_index(i As Long) Common As String
Declare Function display_get_device_name_from_key(device_key As AsciiZ) Common As String
Declare Function display_get_device_index(ByVal device_name As String) As Long
Declare Function display_get_device_string(ByVal device_name As String) Common As String
Declare Function display_get_device_monitor(ByVal device_name As String) Common As String
Declare Function display_get_device_state(ByVal device_name As String) Common As String
Declare Function display_get_device_key(ByVal device_name As String) Common As String
Declare Function display_get_master_device_key(ByVal device_name As String) Common As String
Declare Function display_get_next_display(ByVal device_name As String, device_rect As RECT) Common As String
Declare Function display_get_device_guid(ByVal device_name As String) Common As String
Declare Function display_get_device_handle(ByVal device_name As String) Common As Long
Declare Function display_reset_video_driver(ByVal device_name As AsciiZ * 32) Common As Long
Declare Function display_get_available_video_modes(ByVal device_name As AsciiZ * 32, video_mode() As MODELINE, dwflags As Long) Common As Long
Declare Function display_get_desktop_mode(ByVal device_name As AsciiZ * 32, devmode_out As DEVMODE) Common As Long
Declare Function display_set_desktop_mode(ByVal device_name As AsciiZ * 32, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long, dwflags As Long) Common As Long
Declare Function display_restore_desktop_mode(ByVal device_name As AsciiZ * 32, dwflags As Long) Common As Long
Declare Function display_wait_hardware_change(h_parent As Long) Common As Long
#EndIf
