'==============================================================================
'
'  Video Mode Maker
'  VMMaker.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

%IS_HOST_APP = 1
#Include Once "win32api.inc"
#Include "vmmaker.inc"

#Resource Manifest, 1, "vmmaker.xml"
#Resource Icon, 100, "icons\monitor.ico"
#Resource Icon, 101, "icons\control_panel.ico"
#Resource Icon, 102, "icons\calculator.ico"
#Resource Icon, 200, "icons\monitor_dis.ico"
#Resource Icon, 201, "icons\control_panel_dis.ico"
#Resource Icon, 202, "icons\calculator_dis.ico"
#Resource RcData, 512, "mode_table_methods.txt"

#Resource VersionInfo
#Resource StringInfo "0809", "0000"
#Resource Version$ "FileDescription", "Advanced video mode generator"
#Resource Version$ "LegalCopyright", "Antonio Giner"
#Resource Version$ "ProductName", "Video Mode Maker"
#Resource Version$ "ProductVersion", $app_version

#Link "..\lib\custom_video.sll"
#Link "..\lib\adl_lib.sll"
#Link "..\lib\ati_reg.sll"
#Link "..\lib\command_line.sll"
#Link "..\lib\display.sll"
#Link "..\lib\log_console.sll"
#Link "..\lib\monitor.sll"
#Link "..\lib\modeline.sll"
#Link "..\lib\edid.sll"
#Link "..\lib\pstrip.sll"
#Link "..\lib\util.sll"

#Link "ati_inf.sll"
#Link "command_vmm.sll"
#Link "gui.sll"
#Link "gui_settings.sll"
#Link "mode_db.sll"
#Link "user.sll"
#Link "mame.sll"
#Link "options.sll"
#Link "timing_chart.sll"

'============================================================
'  WinMain
'============================================================

Function WinMain(ByVal hInstance As Dword, ByVal hPrevInst As Dword, ByVal lpszCmdLine As AsciiZ Ptr, ByVal nCmdShow As Long) As Long

  Local error_message As String
  If is_already_running($APP_NAME) Then error_message = "The program is already running." : GoTo exit_error

  ' Start logging
  Local commands_from_stdi As String
  commands_from_stdi = log_console_create()
  clog $APP_LOGO + $Spc + $APP_VERSION + $Spc + $APP_COPYRIGHT + $CrLf

  ' Start app data
  Local vmm As app_data
  Local p_vmm As app_data Ptr
  p_vmm = VarPtr(vmm)

  Local mdb As imode_db
  mdb = Class "mode_db"
  vmm.mdb = ObjPtr(mdb)

  vmm.win_version = os_version()

  ' Process configuration
  options_init_default_data(vmm.options)
  options_get_from_ini("vmm.ini", vmm.options)
  cmd_config(vmm)

  ' Init display and custom video
  command_execute(vmm, $CMD_DISPLAY, $DI_INIT, vmm.options.display.device_key)

  ' Process commands and start GUI
  vmm.command = Trim$(Command$)
  If vmm.command = "" And commands_from_stdi = "" Then
    gui_init(ByVal p_vmm)
  Else
    If vmm.command <> "" Then vmm_launch_command(vmm)
    If commands_from_stdi <> "" Then vmm_parse_commands(vmm, commands_from_stdi)
  End If

  'Save options on exit
  options_write_to_ini("vmm.ini", vmm.options)

  log_console_destroy()
  Exit Function

exit_error:
  MsgBox error_message, %MB_Ok Or %MB_IconError Or %MB_SystemModal, $APP_NAME

End Function

'============================================================
'  vmm_launch_command
'============================================================

Function vmm_launch_command(vmm As APP_DATA) As Long

  Dim params(16) As AsciiZ * 128

  command_parse(vmm.command, params())
  If vmm.command <> "" Then Function = command_execute(vmm, params( 1), params( 2), params( 3), params( 4), params( 5), params( 6), params( 7), params( 8), _
                                                            params( 9), params(10), params(11), params(12), params(13), params(14), params(15), params(16))

End Function

'============================================================
'  vmm_parse_commands
'============================================================

Function vmm_parse_commands(vmm As APP_DATA, commands As String) As Long

  Local i, num_lines As Long
  num_lines = ParseCount(commands, $CrLf)

  For i = 1 To num_lines
    Local new_command As String
    new_command = Parse$(commands, $CrLf, i)
    If new_command <> "" Then
      vmm.command = new_command
      vmm_launch_command(vmm)
    End If
  Next

  Function = i
End Function
