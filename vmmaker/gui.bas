'==============================================================================
'
'  VideoModeMaker
'  gui.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

%IS_SLL = 1
#Compile SLL
#Include "Win32API.inc"
#Include "CommCtrl.inc"
#Include "vmmaker.inc"

Declare Function settings_dlg_show(h_parent As Long) Common As Long

'============================================================
'  Constants
'============================================================

%GUI_WIDTH = 640
%GUI_HEIGHT = 400
%GUI_H_BORDER = 1
%GUI_V_BORDER = 0
%GUI_H_SIZE = %GUI_WIDTH - 2 * %GUI_H_BORDER
%GUI_V_SIZE = %GUI_HEIGHT - 2 * %GUI_V_BORDER
%COMMAND_LINE_HEIGHT = 16

%WM_GUI_READY = %WM_User + 1000
%WM_GUI_BUSY = %WM_User + 1001
%WM_CONSOLE = %WM_User + 2000
%WM_NEW_COMMAND = %WM_User + 3000

Enum main_dlg
  CONSOLE = 1000
  COMMAND_PROMPT
  COMMAND_LINE
End Enum

Enum tool_bar
  IDC = 2000
  SETTINGS
  GENERATE
  INSTALL
End Enum

'============================================================
'  gui_init
'============================================================

Function gui_init(vmm As APP_DATA) Common As Long

  Local h_gui, h_wt As Long

  Dialog New Pixels, 0, $APP_NAME,,, %GUI_WIDTH, %GUI_HEIGHT, %WS_OverlappedWindow To h_gui
  Dialog Set Icon h_gui, "#100"
  Dialog Set Color h_gui, -1, IIf(vmm.win_version > 5, RGB(128,128,128), RGB(192,192,192))
  Dialog Set User h_gui, 1, VarPtr(vmm)
  vmm.h_gui = h_gui

  ' Create event for worker thread
  vmm.h_wt_event = CreateEvent(ByVal 0, 0, 0, "vmmaker_gui_wt")

  ' Create worker thread
  h_wt = gui_wt_create(vmm)

  Local tb_height As Long
  tb_height = gui_create_toolbar(h_gui)
  log_console_gui_init(h_gui, %main_dlg.CONSOLE, %GUI_H_BORDER, tb_height, %GUI_H_SIZE, %GUI_V_SIZE - %COMMAND_LINE_HEIGHT - 1 - tb_height)
  command_line_init(h_gui, %main_dlg.COMMAND_PROMPT, %main_dlg.COMMAND_LINE, %GUI_H_BORDER, %GUI_HEIGHT - %GUI_V_BORDER - %COMMAND_LINE_HEIGHT, %GUI_H_SIZE, %COMMAND_LINE_HEIGHT, "vmmaker>")

  Dialog Show Modeless h_gui, Call gui_dlg_proc

  Do
    Dialog DoEvents To Count&
  Loop While Count&

End Function

'============================================================
'  gui_dlg_proc
'============================================================

CallBack Function gui_dlg_proc() As Long

  Local vmm As APP_DATA Ptr
  Dialog Get User Cb.Hndl, 1 To vmm

  Select Case As Long CbMsg
    Case %WM_InitDialog
      gui_set_state_ready(Cb.Hndl)

    Case %WM_Command
      Select Case As Long Cb.Ctl

        Case %tool_bar.SETTINGS
          gui_set_state_busy(Cb.Hndl)
          If settings_dlg_show(Cb.Hndl) Then gui_send_command(Cb.Hndl, $CMD_CONFIG)
          gui_set_state_ready(Cb.Hndl)

        Case %tool_bar.GENERATE
          gui_send_command(Cb.Hndl, $CMD_MODELIST + $Spc + $ML_BUILD)

        Case %tool_bar.INSTALL
          Local result As Long
          result = MsgBox ("You are about to install a new mode list in the driver. All existing custom modes will be deleted from the driver."_
                            + $CrLf + $CrLf + "Do you want to continue?" + $CrLf, %MB_OkCancel Or %MB_IconWarning, $APP_NAME)
          If result = %IdOk Then gui_send_command(Cb.Hndl, $CMD_MODELIST + $Spc + $ML_INSTALL)
      End Select

    Case %WM_Size
      gui_dialog_resize(Cb.Hndl)

    Case %WM_GUI_BUSY
      gui_set_state_busy(Cb.Hndl)

    Case %WM_GUI_READY
      gui_set_state_ready(Cb.Hndl)

    Case %WM_CONSOLE
      log_console_update()

    Case %WM_NEW_COMMAND
      Local new_command As AsciiZ Ptr
      new_command = Cb.LParam
      @vmm.command = @new_command
      SetEvent(@vmm.h_wt_event)

    Case %WM_Destroy
      'PostQuitMessage(0)

    Case Else
      Function = 0
      Exit Function

  End Select
  Function = 1
End Function

'============================================================
'  gui_send_command
'============================================================

Function gui_send_command(h_dialog As Long, cmd As AsciiZ) Common As Long
  SendMessage(h_dialog, %WM_NEW_COMMAND, 0, VarPtr(cmd))
End Function

'============================================================
'  gui_wt_create
'============================================================

Function gui_wt_create(vmm As APP_DATA) As Long

  Local h_thread, add_data As Long

  Thread Create gui_wt(VarPtr(vmm)) To h_thread
  Thread Set Priority h_thread, %Thread_Priority_Highest

  Function = h_thread
End Function

'============================================================
'  gui_wt
'============================================================

Thread Function gui_wt(ByVal vmm As APP_DATA Ptr) As Long

  Local result As Long

  Do
    WaitForSingleObject(@vmm.h_wt_event, %INFINITE)
    SendMessage(@vmm.h_gui, %WM_GUI_BUSY, 0, 0)
    result = vmm_launch_command(@vmm)
    SendMessage(@vmm.h_gui, %WM_GUI_READY, 0, 0)
  Loop While result <> %RESULT_EXIT

  PostMessage(@vmm.h_gui, %WM_Destroy, 0, 0)
  Function = -1
End Function

'============================================================
'  gui_dialog_resize
'============================================================

Function gui_dialog_resize(h_dialog As Long) As Long

  Local client_width, client_height As Long
  Dialog Get Client h_dialog To client_width, client_height

  Local tb_width, tb_height As Long
  Control Get Size h_dialog, %tool_bar.IDC To tb_width, tb_height

  log_console_gui_resize(client_width - 2 * %GUI_H_BORDER, client_height - 2 * %GUI_V_BORDER - %COMMAND_LINE_HEIGHT - 1 - tb_height)
  command_line_resize(%GUI_H_BORDER, client_height - %GUI_V_BORDER - %COMMAND_LINE_HEIGHT, client_width - 2 * %GUI_H_BORDER - GetSystemMetrics(%SM_CXHSCROLL), %COMMAND_LINE_HEIGHT)

  Function = 1
End Function

'============================================================
'  gui_create_toolbar
'============================================================

Function gui_create_toolbar(h_dialog As Long) As Long

  Local h_normal As Long
  Local h_hot As Long
  Local h_disabled As Long

  ' Create an imagelist for the normal toolbar buttons
  ImageList New Icon 48, 48, 32, 4 To h_normal
  ImageList Add Icon h_normal, "#101"
  ImageList Add Icon h_normal, "#102"
  ImageList Add Icon h_normal, "#100"

  ' Create an imagelist for the hot toolbar buttons
  ImageList New Icon 48, 48, 32, 4 To h_hot
  ImageList Add Icon h_hot, "#101"
  ImageList Add Icon h_hot, "#102"
  ImageList Add Icon h_hot, "#100"

  ' Create an imagelist for the disabled toolbar buttons
  ImageList New Icon 48, 48, 32, 4 To h_disabled
  ImageList Add Icon h_disabled, "#201"
  ImageList Add Icon h_disabled, "#202"
  ImageList Add Icon h_disabled, "#200"

  ' Add a toolbar to the dialog box
  Control Add Toolbar, h_dialog, %tool_bar.IDC, "", 0, 0, 0, 0, %WS_Visible Or %WS_TabStop Or %TbStyle_Flat Or %CCS_NoDivider, 0

  ' Set the toolbars normal button images
  Toolbar Set ImageList h_dialog, %tool_bar.IDC, h_normal, 0
  Toolbar Set ImageList h_dialog, %tool_bar.IDC, h_disabled, 1
  Toolbar Set ImageList h_dialog, %tool_bar.IDC, h_hot, 2

  ' Add the buttons to the toolbar
  Toolbar Add Button h_dialog, %tool_bar.IDC, 1, %tool_bar.SETTINGS, %TbStyle_Button, "Edit settings"
  Toolbar Add Button h_dialog, %tool_bar.IDC, 2, %tool_bar.GENERATE, %TbStyle_Button, "Generate modes"
  Toolbar Add Button h_dialog, %tool_bar.IDC, 3, %tool_bar.INSTALL, %TbStyle_Button, "Install modes"

  ' Return the control height
  Local tb_width, tb_height As Long
  Control Get Size h_dialog, %tool_bar.IDC To tb_width, tb_height
  Function = tb_height

End Function

'============================================================
'  gui_set_state_ready
'============================================================

Function gui_set_state_ready(h_dialog As Long) As Long

  Local vmm As APP_DATA Ptr
  Local mdb As IMODE_DB
  Dialog Get User h_dialog, 1 To vmm
  mdb = Ptr2Obj(@vmm.mdb)

  Toolbar Set State h_dialog, %tool_bar.IDC, ByCmd %tool_bar.SETTINGS, %TBState_Enabled
  Toolbar Set State h_dialog, %tool_bar.IDC, ByCmd %tool_bar.GENERATE, %TBState_Enabled
  Toolbar Set State h_dialog, %tool_bar.IDC, ByCmd %tool_bar.INSTALL, IIf(@vmm.driver_compatible And mdb.mode_count(), %TBState_Enabled, %TBState_Disabled)
  Control Enable h_dialog, %main_dlg.COMMAND_LINE
  Control Set Text h_dialog, %main_dlg.COMMAND_PROMPT, "Ready>"
  command_line_set_focus()

  Function = 1
End Function

'============================================================
'  gui_set_state_busy
'============================================================

Function gui_set_state_busy(h_dialog As Long) As Long

  Toolbar Set State h_dialog, %tool_bar.IDC, ByCmd %tool_bar.SETTINGS, %TBState_Disabled
  Toolbar Set State h_dialog, %tool_bar.IDC, ByCmd %tool_bar.GENERATE, %TBState_Disabled
  Toolbar Set State h_dialog, %tool_bar.IDC, ByCmd %tool_bar.INSTALL, %TBState_Disabled
  Control Disable h_dialog, %main_dlg.COMMAND_LINE
  Control Set Text h_dialog, %main_dlg.COMMAND_PROMPT, "*BUSY*"

  Function = 1
End Function
