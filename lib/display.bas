'==============================================================================
'
'  Display library
'  display.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include Once "win32api.inc"
#Include "modeline.inc"
#Include "display.inc"
#Include "log_console.inc"
#Include "util.inc"

Declare Function DirectDrawEnumerateEx Lib "DDRAW.DLL" Alias "DirectDrawEnumerateExA" (ByVal Dword, ByVal Dword, ByVal Dword) As Long
Declare Function GetDisplayConfigBufferSizes_(ByVal flags As Dword, numPathArrayElements As Dword, numModeInfoArrayElements As Dword) As Long
Declare Function SetDisplayConfig_(ByVal numPathArrayElements As Dword, ByVal pathArray As DISPLAYCONFIG_PATH_INFO Ptr, ByVal numModeInfoArrayElements As Dword, _
                                   ByVal modeInfoArray As DISPLAYCONFIG_MODE_INFO Ptr, ByVal flags As Dword) As Long
Declare Function QueryDisplayConfig_(ByVal flags As Dword, numPathArrayElements As Dword, ByVal PathArray As DISPLAYCONFIG_PATH_INFO Ptr, numModeInfoArrayElements As Dword, _
                                    ByVal modeInfoArray As DISPLAYCONFIG_MODE_INFO Ptr, currentTopologyId As Dword) As Long
Declare Function DisplayConfigGetDeviceInfo_(requestPacket As DISPLAYCONFIG_DEVICE_INFO_HEADER) As Long

'============================================================
'  constants
'============================================================

%DEVICE_MAX = 16
%EDD_GET_DEVICE_INTERFACE_NAME = 1
$DISPLAY_DEFAULT = "\\.\DISPLAY1"

' DirectDraw
%DD_OK                                  = &h0
%DD_FALSE                               = %S_False
%DDENUM_ATTACHEDSECONDARYDEVICES        = &h00000001
%DDENUM_DETACHEDSECONDARYDEVICES        = &h00000002

' WDDM display enumeration
%DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME             = 1
%DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME             = 2
%DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_PREFERRED_MODE   = 3
%DISPLAYCONFIG_DEVICE_INFO_GET_ADAPTER_NAME            = 4
%DISPLAYCONFIG_DEVICE_INFO_SET_TARGET_PERSISTENCE      = 5
%DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_BASE_TYPE        = 6
%DISPLAYCONFIG_DEVICE_INFO_FORCE_UINT32                = &h0FFFFFFFF

'============================================================
'  types
'============================================================

Type DISPLAY_INFO
  DISPLAY_DEVICE
  RECT
  MonitorName As AsciiZ * 128
  device_guid As Guid
  h_monitor As Long
  desktop_devmode As DEVMODE
End Type

'============================================================
'  globals
'============================================================

Global device_list() As DISPLAY_INFO
Global device_num As Long
Global display_current As String

'============================================================
'  display_get_device_num
'============================================================

Function display_get_device_num Common As Long
  Function = device_num - 1
End Function

'============================================================
'  display_get_device_by_index
'============================================================

Function display_get_device_by_index(i As Long) Common As String
  If i < device_num Then Function = device_list(i).DeviceName
End Function

'============================================================
'  display_get_device_key_by_index
'============================================================

Function display_get_device_key_by_index(i As Long) Common As String
  If i < device_num Then Function = device_list(i).DeviceKey
End Function

'============================================================
'  display_get_device_long_name_by_index
'============================================================

Function display_get_device_long_name_by_index(i As Long) Common As String
  If i < device_num Then Function = Using$("& - & - & - &", device_list(i).DeviceName, device_list(i).DeviceString, device_list(i).MonitorName, display_get_device_state(device_list(i).DeviceName))
End Function

'============================================================
'  display_get_device_name_from_key
'============================================================

Function display_get_device_name_from_key(device_key As AsciiZ) Common As String

  Local i As Long
  For i = 0 To device_num - 1
    If device_list(i).DeviceKey = device_key Then Function = device_list(i).DeviceName : Exit Function
  Next
End Function

'============================================================
'  display_get_default_options
'============================================================

Function display_get_default_options(options As DISPLAY_OPTIONS) Common As Long
  options.device_key = ""
  options.auto_extend_desktop = 1
End Function

'============================================================
'  display_init
'============================================================

Function display_init(device_key As AsciiZ) Common As Long

  If IsFalse display_get_devices() Then clog "Error enumerating displays." : Exit Function

  display_current = display_get_device_name_from_key(device_key)
  If display_current = "" Then
    display_current = device_list(0).DeviceName
    clog "Device key not found. Defaulting to " + display_current
  End If
End Function

'============================================================
'  display_get_current
'============================================================

Function display_get_current() Common As String
  Function = display_current
End Function

'============================================================
'  display_restart
'============================================================

Function display_restart(ByVal device_name As String, hwnd As Long, win_version As Long, options As DISPLAY_OPTIONS) Common As Long

  'If win_version > 5 And MsgBox("Do you wish to force a device restart?", %MB_YesNo) = %IdYes Then
  If win_version > 5 Then
    clog "Restarting device " + device_name

    ' Save current device key
    Local device_key As AsciiZ * 256
    device_key = display_get_device_key(device_name)

    ' Save current display topology
    Local d1_flags, d2_flags As Long
    d1_flags = device_list(display_get_device_index(device_name)).StateFlags
    d2_flags = device_list(display_get_device_index(device_name) + 1).StateFlags

    ' Restart device
    clog Exe.Path$ + Using$("devutil&.exe", IIf$(is_64(), "64", "32")) + " reset " + $Dq + device_list(display_get_device_index(device_name)).DeviceID + $Dq
    launch_command_elevated(Exe.Path$ + Using$("devutil&.exe", IIf$(is_64(), "64", "32")), "reset " + $Dq + device_list(display_get_device_index(device_name)).DeviceID + $Dq, hwnd)
'    launch_command_elevated(Exe.Path$ + "devcon.exe", "restart " + $Dq + device_list(display_get_device_index(device_name)).DeviceID + $Dq, hwnd)
    display_wait_hardware_change(hwnd)

    display_init(device_key)
    device_name = display_get_current()
    display_enable_outputs(device_name, d1_flags, d2_flags, options)

  Else
    clog "You must restart the system for changes to take effect."
  End If
End Function

'============================================================
'  display_enable_outputs
'============================================================

Function display_enable_outputs(ByVal display_1 As AsciiZ * 32, d1_flags As Long, d2_flags As Long, options As DISPLAY_OPTIONS) As Long

  Local result As Long

  If ((d1_flags And %DISPLAY_DEVICE_ACTIVE) And (d2_flags And %DISPLAY_DEVICE_ACTIVE)) Or (options.auto_extend_desktop) Then
    Local h_dll As Long
    h_dll = LoadLibrary("user32.dll")

    Local pfn_SetDisplayConfig As Long
    pfn_SetDisplayConfig = GetProcAddress(h_dll, "SetDisplayConfig")
    If pfn_SetDisplayConfig Then
      Call Dword pfn_SetDisplayConfig Using SetDisplayConfig_(0, %NULL, 0, %NULL, %SDC_TOPOLOGY_EXTEND Or %SDC_APPLY) To result
      clog Using$("extending desktop: &", IIf$(result = %ERROR_SUCCESS, "success", Using$("failed &", Hex$(result))))
    End If
    FreeLibrary(h_dll)
  End If

  If (d1_flags And %DISPLAY_DEVICE_ACTIVE) Or (options.auto_extend_desktop) Then
    result = ChangeDisplaySettingsEx(display_1, device_list(display_get_device_index(display_1)).desktop_devmode, %NULL, %CDS_UPDATEREGISTRY Or IIf((d1_flags And %DISPLAY_DEVICE_PRIMARY_DEVICE), %CDS_SET_PRIMARY, 0), ByVal %NULL)
    clog Using$("enabling & : &", display_1, IIf$(result = %DISP_CHANGE_SUCCESSFUL, "success", Using$("failed &", Hex$(result))))
  End If

  If (d2_flags And %DISPLAY_DEVICE_ACTIVE) Or (options.auto_extend_desktop) Then
    Local display_2 As AsciiZ * 32
    display_2 = display_get_device_by_index(display_get_device_index(display_1) + 1)

    Local d As DEVMODE Ptr
    d = VarPtr(device_list(display_get_device_index(display_2)).desktop_devmode)
    Reset @d
    @d.dmSize = SizeOf(DEVMODE)
    @d.dmPelsWidth = 640
    @d.dmPelsHeight = 480
    @d.dmFields = %DM_PELSWIDTH Or %DM_PELSHEIGHT
    result = ChangeDisplaySettingsEx(display_2, @d, %NULL, %CDS_UPDATEREGISTRY Or IIf((d2_flags And %DISPLAY_DEVICE_PRIMARY_DEVICE), %CDS_SET_PRIMARY, 0), ByVal %NULL)
    clog Using$("enabling & : &", display_2, IIf$(result = %DISP_CHANGE_SUCCESSFUL, "success", Using$("failed &", Hex$(result))))
  End If

End Function

'============================================================
'  display_wait_hardware_change
'============================================================

Function display_wait_hardware_change(h_parent As Long) Common As Long

  Local h_dummy As Long
  Dialog New Pixels, h_parent, "Restarting device",,, 160, 48, %WS_Overlapped, To h_dummy
  Control Add Label, h_dummy, 0, "Please wait...", 8, 16, 144, 16
  Dialog Show Modal h_dummy, Call wait_hardware_change_proc

End Function

CallBack Function wait_hardware_change_proc() As Long

  Select Case As Long CbMsg
    Case %WM_InitDialog
      ' Set a timeout for security
      SetTimer(Cb.Hndl, 1, 10000, 0)

    Case %WM_Timer
      Dialog End Cb.Hndl, 0

    Case %WM_DEVICECHANGE
      ' Wait 10 seconds after WM_DEVICECHANGE
      clog "Device has changed."

    Case Else
      Exit Function
  End Select

  Function = 1
End Function

'============================================================
'  display_get_devices
'============================================================

Function display_get_devices() Common As Long

  Local i As Long
  Local lpDisplayDevice As DISPLAY_DEVICE

  Dim device_list(%DEVICE_MAX) As Global DISPLAY_INFO
  device_num = 0

  clog "Listing display devices..."
  lpDisplayDevice.cb = SizeOf (DISPLAY_DEVICE)
  While EnumDisplayDevices(ByVal %NULL, i, lpDisplayDevice, %NULL) <> 0 And i <= %DEVICE_MAX
    If IsFalse (lpDisplayDevice.StateFlags And %DISPLAY_DEVICE_MIRRORING_DRIVER) Then

      ' Get video card info
      device_list(i).DeviceName   = lpDisplayDevice.DeviceName
      device_list(i).DeviceString = Trim$(lpDisplayDevice.DeviceString)
      device_list(i).StateFlags   = lpDisplayDevice.StateFlags
      device_list(i).DeviceID     = lpDisplayDevice.DeviceID
      device_list(i).DeviceKey    = Remove$(lpDisplayDevice.DeviceKey, "\Registry\Machine")

      ' Get monitor name
      EnumDisplayDevices(device_list(i).DeviceName, 0, lpDisplayDevice, %EDD_GET_DEVICE_INTERFACE_NAME)
      Local monitor_name, monitor_friendly_name As String
      monitor_name = Trim$(lpDisplayDevice.DeviceString)
      If InStr(monitor_name, "PnP") And os_version() > 5 Then
        monitor_friendly_name = display_get_monitor_friendly_name(device_list(i).DeviceName)
        If monitor_friendly_name <> "" Then monitor_name = monitor_friendly_name
      End If
      device_list(i).MonitorName = IIf$(monitor_name <> "", monitor_name, "No monitor")

      clog  Using$("& - & - & - & - HKLM&", device_list(i).DeviceName, device_list(i).DeviceString, device_list(i).MonitorName, display_get_device_state(device_list(i).DeviceName), device_list(i).DeviceKey)
      Incr device_num
    End If
    Incr i
  Wend

  ' Associate devices with desktop coordinates
  If IsFalse EnumDisplayMonitors(%NULL, ByVal %NULL, CodePtr(monitor_enum_proc), 0) Then Function = 0 : Exit Function

  'We need to use DirecDraw's enumeration functionality to associate displays with GUIDs
  If IsFalse enumerate_screens_ddraw() Then Function = 0 : Exit Function

  Function = 1
End Function

'============================================================
'  display_get_monitor_friendly_name
'============================================================

Function display_get_monitor_friendly_name(ByVal device_name As String) As String

  Local h_dll As Long
  h_dll = LoadLibrary("user32.dll")

  Local pfn_GetDisplayConfigBufferSizes As Long
  pfn_GetDisplayConfigBufferSizes = GetProcAddress(h_dll, "GetDisplayConfigBufferSizes")
  If IsFalse pfn_GetDisplayConfigBufferSizes Then exit_function

  Local pfn_QueryDisplayConfig As Long
  pfn_QueryDisplayConfig = GetProcAddress(h_dll, "QueryDisplayConfig")
  If IsFalse pfn_QueryDisplayConfig Then exit_function

  Local pfn_DisplayConfigGetDeviceInfo As Long
  pfn_DisplayConfigGetDeviceInfo = GetProcAddress(h_dll, "DisplayConfigGetDeviceInfo")
  If IsFalse pfn_DisplayConfigGetDeviceInfo Then exit_function

  Local num_of_paths As Dword
  Local num_of_modes As Dword
  Call Dword pfn_GetDisplayConfigBufferSizes Using GetDisplayConfigBufferSizes_(%QDC_ALL_PATHS, num_of_paths, num_of_modes)

  ' Allocate paths and modes dynamically
  Dim display_paths(num_of_paths) As Local DISPLAYCONFIG_PATH_INFO
  Dim display_modes(num_of_modes) As Local DISPLAYCONFIG_MODE_INFO

  ' Query for the information
  Call Dword pfn_QueryDisplayConfig Using QueryDisplayConfig_(%QDC_ALL_PATHS, num_of_paths, VarPtr(display_paths(0)), num_of_modes, VarPtr(display_modes(0)), ByVal 0)

  Local i As Long
  For i = 0 To num_of_paths - 1
    If IsFalse (display_paths(i).flags And %DISPLAYCONFIG_PATH_ACTIVE) Then Iterate For

    ' Get GDI device name from source (e.g. \\.\DISPLAY1)
    Local hds As DISPLAYCONFIG_DEVICE_INFO_HEADER
    Reset hds
    hds.dsize = SizeOf(DISPLAYCONFIG_SOURCE_DEVICE_NAME)
    hds.adapterId = display_paths(i).sourceInfo.adapterId
    hds.id = display_paths(i).sourceInfo.Id
    hds.dtype = %DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME

    Local source_device_name As DISPLAYCONFIG_SOURCE_DEVICE_NAME
    source_device_name.header = hds
    Call Dword pfn_DisplayConfigGetDeviceInfo Using DisplayConfigGetDeviceInfo_(ByVal VarPtr(source_device_name))

    If device_name <> source_device_name.viewGdiDeviceName Then Iterate For

    ' Get monitor friendly name for target
    Local hdt As DISPLAYCONFIG_DEVICE_INFO_HEADER
    Reset hdt
    hdt.dsize = SizeOf(DISPLAYCONFIG_TARGET_DEVICE_NAME)
    hdt.adapterId = display_paths(i).targetInfo.adapterId
    hdt.id = display_paths(i).targetInfo.Id
    hdt.dtype = %DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME

    Local target_device_name As DISPLAYCONFIG_TARGET_DEVICE_NAME
    target_device_name.header = hdt
    Call Dword pfn_DisplayConfigGetDeviceInfo Using DisplayConfigGetDeviceInfo_(ByVal VarPtr(target_device_name))

    Function = target_device_name.monitorFriendlyDeviceName
    GoTo exit_function
  Next

  exit_function:
    FreeLibrary(h_dll)
End Function

'============================================================
'  monitor_enum_proc
'============================================================

Function monitor_enum_proc(hMonitor As Long, hdcMonitor As Long, lprcMonitor As RECT, dwData As Long) As Long

  Local i As Long
  Local lpmi As MONITORINFOEX
  lpmi.cbSize = SizeOf(MONITORINFOEX)

  If GetMonitorInfo(ByRef hMonitor, lpmi) Then
    i = display_get_device_index(lpmi.szDevice)
    device_list(i).nTop    = lprcMonitor.nTop
    device_list(i).nLeft   = lprcMonitor.nLeft
    device_list(i).nRight  = lprcMonitor.nRight
    device_list(i).nBottom = lprcMonitor.nBottom
    'clog lpmi.szDevice + ""
    'clog device_list(i).DeviceString + ""
    'clog display_get_device_state (device_list(i).DeviceName) + ""
    'clog Using$ (" # x # - # x #", device_list(i).nLeft, device_list(i).nTop, device_list(i).nRight, device_list(i).nBottom)
    'clog device_list(i).DeviceKey + ""
    'clog device_list(i).DeviceID + ""
  Else
    clog "MonitorEnumProc: error " + Hex$(GetLastError)
  End If

  Function = 1
End Function

'============================================================
'  enumerate_screens_ddraw
'============================================================

Function enumerate_screens_ddraw As Long

  Local hresult As Long
  Local monitor_count As Long

  hresult = DirectDrawEnumerateEx(CodePtr(DD_enum_callback_ex), VarPtr(monitor_count), %DDENUM_ATTACHEDSECONDARYDEVICES)
  If hresult <> %DD_OK Then Function = 0 : Exit Function

  Function = monitor_count
End Function

'============================================================
'  DD_enum_callback_ex
'============================================================

Function DD_enum_callback_ex(ByVal lpGUID As Guid Ptr, ByVal lpDriverDescription As AsciiZ Ptr, ByVal lpDriverName As AsciiZ Ptr, monitor_count As Long, ByVal hm As Long) As Long

  Local i As Long

  If monitor_count > %DEVICE_MAX Then Function = 0 : Exit Function

  While device_list(i).DeviceName <> "" And i <= %DEVICE_MAX
    If device_list(i).DeviceName = @lpDriverName Then
      device_list(i).device_guid = @lpGUID
      device_list(i).h_monitor = hm
    End If
  Incr i
  Wend

  Incr monitor_count
  Function = 1
End Function

'============================================================
'  display_monitor_index_from_device
'============================================================

Function display_monitor_index_from_device(ByVal device_name As String) Common As Long
  '        input: \\.\DISPLAY1 -> output:  0

  Local lpDisplayDevice As DISPLAY_DEVICE

  'lpDisplayDevice.cb = SIZEOF (DISPLAY_DEVICE)
  'EnumDisplayDevices(device_name, 0, lpDisplayDevice, %NULL)
  'FUNCTION = VAL (RIGHT$ (TRIM$ (lpDisplayDevice.DeviceName), 1))

  Function = Val(Right$(device_name, 1)) - 1
End Function

'============================================================
'  display_rect_from_primary_monitor
'============================================================

Function display_rect_from_primary_monitor(primary_rect As RECT) Common As Long

  primary_rect.nTop = 0
  primary_rect.nLeft = 0
  primary_rect.nRight = GetSystemMetrics(%SM_CXSCREEN)
  primary_rect.nBottom = GetSystemMetrics(%SM_CYSCREEN)

End Function

'============================================================
'  display_rect_from_window
'============================================================

Function display_rect_from_window(hWnd As Long, display_rect As RECT) Common As String

  Local hMonitor As Long
  Local lpmi As MONITORINFOEX

  hMonitor = MonitorFromWindow(hWnd, %MONITOR_DEFAULTTONEAREST)

  lpmi.cbSize = SizeOf(MONITORINFOEX)
  GetMonitorInfo(hMonitor, lpmi)
  display_rect = lpmi.rcMonitor

  Function = lpmi.szDevice
End Function

'============================================================
'  display_display_get_device_index
'============================================================

Function display_get_device_index(ByVal device_name As String) As Long

  Local i As Long

  While device_list(i).DeviceName <> "" And i <= %DEVICE_MAX
    If device_list(i).DeviceName = device_name Then
      Function = i
      Exit Function
    End If
    Incr i
  Wend
End Function

'============================================================
'  display_get_device_string
'============================================================

Function display_get_device_string(ByVal device_name As String) Common As String
'        input: \\.\DISPLAY1 -> output:  NVIDIA GeForce Go 7400 #1

  Local i As Long
  i = display_get_device_index(device_name)
  Function = device_list(i).DeviceString + IIf$ ((device_list(i).StateFlags And %DISPLAY_DEVICE_PRIMARY_DEVICE), " #1", " #2")
End Function

'============================================================
'  display_get_device_monitor
'============================================================

Function display_get_device_monitor(ByVal device_name As String) Common As String
'        input: \\.\DISPLAY1 -> output: Generic PnP Monitor

  Local i As Long
  i = display_get_device_index(device_name)
  Function = device_list(i).MonitorName
End Function

'============================================================
'  display_get_device_state
'============================================================

Function display_get_device_state(ByVal device_name As String) Common As String
'        input: \\.\DISPLAY1 -> output: enabled / disabled

  Local i As Long
  i = display_get_device_index(device_name)
  Function = IIf$((device_list(i).StateFlags And %DISPLAY_DEVICE_ATTACHED_TO_DESKTOP), "enabled", "disabled")
End Function

'============================================================
'  display_get_device_key
'============================================================

Function display_get_device_key(ByVal device_name As String) Common As String
'        input: \\.\DISPLAY1 -> output: \Registry\Machine\System\CurrentControlSet\Control\Video\{DEB039CC-B704-4F53-B43E-9DD4432FA2E9}\0000

  Function = device_list(display_get_device_index(device_name)).DeviceKey
End Function

'============================================================
'  display_get_master_device_key
'============================================================

Function display_get_master_device_key(ByVal device_name As String) Common As String
'        input: \\.\DISPLAY2 -> (check DISPLAY1 is MASTER so get its key) -> output: \Registry\Machine\System\CurrentControlSet\Control\Video\{DEB039CC-B704-4F53-B43E-9DD4432FA2E9}\0000

 Local i As Long
 Local device_key, device_string As String

  i = display_get_device_index(device_name)

  device_key = device_list(i).DeviceKey
  device_string = device_list(i).DeviceString

  i = 0
  While device_list(i).DeviceName <> "" And i <= %DEVICE_MAX
    If device_list(i).DeviceName < device_name And IsTrue(InStr(device_string, device_list(i).DeviceString)) Then
        Function = device_list(i).DeviceKey
        Exit Function
    End If
    Incr i
  Wend

  Function = device_key
End Function

'============================================================
'  display_get_rect_from_display
'============================================================

Function display_get_rect_from_display(ByVal device_name As String, device_rect As RECT) Common As Long
'        input: \\.\DISPLAY1 -> desktop RECT

  Local i As Long
  i = display_get_device_index(device_name)

  device_rect.nTop    = device_list(i).nTop
  device_rect.nLeft   = device_list(i).nLeft
  device_rect.nRight  = device_list(i).nRight
  device_rect.nBottom = device_list(i).nBottom

  Function = 1
End Function

'============================================================
'  display_get_next_display
'============================================================

Function display_get_next_display(ByVal device_name As String, device_rect As RECT) Common As String
'        input: \\.\DISPLAY1 -> output: \\.\DISPLAY2

  Local i, j As Long

  i = display_get_device_index(device_name)

  For j = 0 To %DEVICE_MAX
    Incr i
    If i > %DEVICE_MAX Then i = 0
    If (device_list(i).StateFlags And %DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) Then Exit
  Next

  device_rect.nTop    = device_list(i).nTop
  device_rect.nLeft   = device_list(i).nLeft
  device_rect.nRight  = device_list(i).nRight
  device_rect.nBottom = device_list(i).nBottom

  Function = device_list(i).DeviceName
End Function

'============================================================
'  display_get_device_guid
'============================================================

Function display_get_device_guid(ByVal device_name As String) Common As String

  Local i As Long

  i = display_get_device_index(device_name)
  Function = device_list(i).device_guid
End Function

'============================================================
'  display_get_device_handle
'============================================================

Function display_get_device_handle(ByVal device_name As String) Common As Long

  Local i As Long

  i = display_get_device_index(device_name)
  Function = device_list(i).h_monitor
End Function

'============================================================
'  display_reset_video_driver
'============================================================

Function display_reset_video_driver(ByVal device_name As AsciiZ * 32) Common As Long

  Local iModeNum As Long
  Local lpDevMode As DEVMODE

  Reset lpDevMode
  lpDevMode.dmSize = SizeOf(DEVMODE)

  While EnumDisplaySettingsEx(device_name, iModeNum, lpDevMode, 0) <> 0
    Incr iModeNum
  Wend

Function = iModeNum
End Function

'============================================================
'  display_get_available_video_modes
'============================================================

Function display_get_available_video_modes(ByVal device_name As AsciiZ * 32, video_mode() As MODELINE, dwflags As Long) Common As Long

  Local iModeNum, i, j, k As Long
  Local m, n As MODELINE Ptr

  Local d As DEVMODE
  display_get_desktop_mode(device_name, d)

  Local lpDevMode As DEVMODE
  Reset lpDevMode
  lpDevMode.dmSize = SizeOf(DEVMODE)

  While EnumDisplaySettingsEx(device_name, iModeNum, lpDevMode, dwflags) <> 0
    If (lpDevMode.dmBitsPerPel = 32 Or lpDevMode.dmBitsPerPel = 4) And lpDevMode.dmDisplayFixedOutput = %DMDFO_DEFAULT Then
      m = VarPtr(video_mode(k))
      Reset @m
      @m.interlace = IIf(lpDevMode.dmDisplayFlags And %DM_INTERLACED, 1, 0)
      @m.type Or= IIf(lpDevMode.dmDisplayOrientation = %DMDO_90 Or lpDevMode.dmDisplayOrientation = %DMDO_270, %MODE_ROTATED, %MODE_OK)
      @m.type Or= IIf(lpDevMode.dmPelsWidth = d.dmPelsWidth And lpDevMode.dmPelsHeight = d.dmPelsHeight And lpDevMode.dmDisplayFrequency = d.dmDisplayFrequency, %MODE_DESKTOP, %MODE_OK)
      @m.width = IIf((lpDevMode.dmDisplayOrientation = %DMDO_DEFAULT) Or (lpDevMode.dmDisplayOrientation = %DMDO_180), lpDevMode.dmPelsWidth, lpDevMode.dmPelsHeight)
      @m.height = IIf((lpDevMode.dmDisplayOrientation = %DMDO_DEFAULT) Or (lpDevMode.dmDisplayOrientation = %DMDO_180), lpDevMode.dmPelsHeight, lpDevMode.dmPelsWidth)
      @m.refresh = IIf(lpDevMode.dmDisplayFrequency = 1, 0, lpDevMode.dmDisplayFrequency)
      @m.bpp = lpDevMode.dmBitsPerPel
      Incr k
    End If
    Incr iModeNum
  Wend
  Decr k

  For i = 0 To k
    m = VarPtr(video_mode(i))
    For j = i To k
      n = VarPtr(video_mode(j))
      If @n.width < @m.width Or _
        (@n.width = @m.width And @n.height < @m.height) Or _
        (@n.width = @m.width And @n.height = @m.height And @n.refresh < @m.refresh) Then Swap @n, @m
    Next
  Next

  Function = k
End Function

'============================================================
'  display_get_desktop_mode
'============================================================

Function display_get_desktop_mode(ByVal device_name As AsciiZ * 32, devmode_out As DEVMODE) Common As Long

  Local i As Long
  i = display_get_device_index(device_name)

  Local lp_devmode As DEVMODE Ptr
  lp_devmode = IIf(VarPtr(devmode_out) = 0, VarPtr(device_list(i).desktop_devmode), VarPtr(devmode_out))

  Reset @lp_devmode
  @lp_devmode.dmSize = SizeOf(DEVMODE)
  Function = EnumDisplaySettingsEx(device_name, %ENUM_CURRENT_SETTINGS, ByVal lp_devmode, %NULL)
End Function

'============================================================
'  display_set_desktop_mode
'============================================================

Function display_set_desktop_mode(ByVal device_name As AsciiZ * 32, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long, dwflags As Long) Common As Long

  ' Backup desktop mode
  display_get_desktop_mode(device_name, ByVal %NULL)

  Local win_version As Long
  win_version = os_version()

  Local lpDevMode As DEVMODE
  lpDevMode.dmSize = SizeOf(DEVMODE)
  lpDevMode.dmBitsPerPel = m_bpp
  lpDevMode.dmPelsWidth = m_width
  lpDevMode.dmPelsHeight = m_height
  lpDevMode.dmDisplayFrequency = m_refresh
  lpDevMode.dmDisplayFlags = IIf(m_interlace, %DM_INTERLACED, 0)
  lpDevMode.dmFields = %DM_PELSWIDTH Or %DM_PELSHEIGHT Or %DM_BITSPERPEL Or %DM_DISPLAYFREQUENCY Or IIf(win_version > 5, %DM_DISPLAYFLAGS, 0)
  If ChangeDisplaySettingsEx (ByVal IIf(device_name <> "", VarPtr(device_name), %NULL), lpDevMode, %NULL, ByVal dwflags, ByVal %NULL) <> %DISP_CHANGE_SUCCESSFUL Then
    clog Using$("display_set_desktop_mode: ChangeDisplaySettingsEx # # # # error", lpDevMode.dmPelsWidth, lpDevMode.dmPelsHeight, lpDevMode.dmBitsPerPel, lpDevMode.dmDisplayFrequency)
    Function = 0 : Exit Function
  End If

  ' Update device topology
  If IsFalse (dwflags And %CDS_TEST) Then display_get_devices()

  Function = 1
End Function

'============================================================
'  display_restore_desktop_mode
'============================================================

Function display_restore_desktop_mode(ByVal device_name As AsciiZ * 32, dwflags As Long) Common As Long

  If ChangeDisplaySettingsEx(device_name, device_list(display_get_device_index(device_name)).desktop_devmode, %NULL, ByVal dwflags, ByVal %NULL)  <> %DISP_CHANGE_SUCCESSFUL Then
    clog "display_restore_desktop_mode: error"
    Function = 0 : Exit Function
  End If

  ' Update device topology
  If IsFalse (dwflags And %CDS_TEST) Then display_get_devices()

  Function = 1
End Function
