'==============================================================================
'  Arcade OSD
'  Custom video editor
'
'  Author: Antonio Giner González
'  Date:   January 2019
'
'  arcade_osd.bas
'==============================================================================

%IS_HOST_APP = 1
#Register None
#Compile Exe
#Dim All

#Include "win32api.inc"
#Include "arcade_osd.inc"

#Resource Icon, APP_ICON, "arcade_osd.ico"
#Resource Manifest, 1, "arcade_osd.xml"

#Resource VersionInfo
#Resource StringInfo "0809", "0000"
#Resource Version$ "FileDescription", "Advanced video timing editor"
#Resource Version$ "LegalCopyright", "Antonio Giner"
#Resource Version$ "ProductName", "Arcade OSD"
#Resource Version$ "ProductVersion", $app_version

#Link "..\lib\custom_video.sll"
#Link "..\lib\adl_lib.sll"
#Link "..\lib\ati_reg.sll"
#Link "..\lib\display.sll"
#Link "..\lib\render.sll"
#Link "..\lib\render_ddraw.sll"
#Link "..\lib\render_d3d.sll"
#Link "..\lib\log_console.sll"
#Link "..\lib\modeline.sll"
#Link "..\lib\pstrip.sll"
#Link "..\lib\util.sll"

Global osd_render_lock As Long

'============================================================
'  WinMain
'============================================================

Function WinMain(ByVal hInst As Long, ByVal hPrevInst As Long, ByVal CmdLine As AsciiZ Ptr, ByVal CmdShow As Long) As Long

  Dim osd As Global OSD_DEF
  Dim Mnu(16) As Global MENU_DEF

  Local msg As TAGMSG
  Local wc As WNDCLASSEX
  Local ClassName As AsciiZ * 32

  osd.width = %OSD_WIDTH
  osd.line_count = %OSD_HEIGHT
  osd.input_focus = %TRUE
  osd.lock_vfreq = %TRUE
  osd.lock_unsupported_modes = %TRUE
  osd.win_version = os_version()

  Local error_message As String
  If is_already_running($APP_TITLE) Then error_message = "The program is already running." : GoTo exit_error

  Local commands_from_stdi As String
  commands_from_stdi = log_console_create()

  Dialog New Pixels, 0, $APP_TITLE + $Spc + $APP_VERSION + " debug console",,, 640, 480, %WS_OverlappedWindow To osd.h_debug
  Dialog Set Icon osd.h_debug, "APP_ICON"
  log_console_gui_init(osd.h_debug, %DEBUG_CONSOLE, 0, 0, %DEBUG_WIDTH, %DEBUG_HEIGHT)
  Dialog Show Modeless osd.h_debug, Call debug_proc
  ShowWindow(osd.h_debug, %SW_Hide)
  SetWindowLong(osd.h_debug, %GWL_EXSTYLE, GetWindowLong(osd.h_debug, %GWL_EXSTYLE) Or %WS_Ex_Layered)
  SetLayeredWindowAttributes(osd.h_debug, 0, (255 * 90) / 100, %LWA_ALPHA)

  display_rect_from_primary_monitor(osd.display_area)
  osd_resize(%OSD_SIZE_AND_CENTER)

  ' Create app window
  ClassName = $APP_CLASS
  wc.cbSize       = SizeOf(WNDCLASSEX)
  wc.style        = %CS_HREDRAW Or %CS_VREDRAW
  wc.lpfnWndProc  = CodePtr(window_proc)
  wc.cbClsExtra   = 0
  wc.cbWndExtra   = 0
  wc.hInstance    = hInst
  wc.hIcon        = LoadIcon(hInst, ByVal MakDwd(1000, 0))
  wc.hCursor      = LoadCursor(%NULL, ByVal %IDC_ARROW)
  wc.hbrBackground = GetStockObject(%BLACK_BRUSH)
  wc.lpszMenuName  = VarPtr(ClassName)
  wc.lpszClassName = VarPtr(ClassName)
  RegisterClassEx(wc)
  osd.hwnd = CreateWindowEx(%WS_Ex_Topmost, $APP_CLASS, $APP_TITLE, %WS_Popup, osd.xpos, osd.ypos, osd.xsize, osd.ysize, %NULL, %NULL, hInst, ByVal %NULL)
  If IsFalse osd.hwnd Then Function = %FALSE : Exit Function

  osd.menu_display = display_rect_from_window(osd.hwnd, osd.display_area)
  osd.target_display = osd.menu_display
  osd_display_init(osd.target_display)

  osd_cls()
  menu_start(%START_MENU)
  osd_resize(%OSD_SIZE)

  ShowWindow(osd.hwnd, CmdShow)
  UpdateWindow(osd.hwnd)
  SetFocus(osd.hwnd)

  While(GetMessage(msg, %NULL, 0, 0))
    TranslateMessage(msg)
    DispatchMessage(msg)
  Wend
  Function = msg.wParam
  Exit Function

exit_error:
  MsgBox error_message, %MB_Ok Or %MB_IconError Or %MB_SystemModal, $APP_TITLE

End Function

'============================================================
'  debug_proc
'============================================================

CallBack Function debug_proc() As Long

  Select Case As Long CbMsg

    Case %WM_CONSOLE
      log_console_update()

    Case %WM_Size
      Local client_width, client_height As Long
      Dialog Get Client Cb.Hndl To client_width, client_height
      log_console_gui_resize(client_width, client_height)

    Case Else
      Function = 0
      Exit Function

  End Select
  Function = 1
End Function

'============================================================
'  window_proc
'============================================================

Function window_proc(ByVal hWnd As Long, ByVal message As Dword, ByVal wParam As Long, ByVal lParam As Long)As Long

  Local ps As PAINTSTRUCT

  Select Case (message)

    Case %WM_Destroy
      render_exit()
      PostQuitMessage(0)
      Function = 0
      Exit Function

    Case %WM_KeyDown
      Select Case menu_action(wParam)
        Case %EXIT
          PostMessage(hWnd, %WM_Close, 0, 0)
        Case %REDRAW
          menu_start(osd.current_menu)
        Case %RESIZE
          osd_resize(%OSD_SIZE)
        Case %RESIZE_CENTER
          osd_resize(%OSD_SIZE_AND_CENTER)
        Case %RESET
          display_reset_video_driver(osd.target_display)
        Case %REFRESH
      End Select
      SendMessage(hWnd, %WM_Paint, 0, 0)
      Function = 0
      Exit Function

    Case %WM_Paint
      BeginPaint(hWnd, ps)
      osd_update(osd.current_mode, hWnd)
      EndPaint(hWnd, ps)
      Function = 0
      Exit Function

    Case %WM_LButtonDown
      If osd.fullscreen = 0 Then
        SendMessage(hWnd, %WM_NCLButtonDown, %HTCAPTION, %NULL)
        Function = 0
        Exit Function
      End If

    Case %WM_Move
      If osd.fullscreen = 0 Then
        osd.xpos = Lo(Integer, lParam)
        osd.ypos = Hi(Integer, lParam)
      End If
      Function = 0
      Exit Function

    Case %WM_EXITSIZEMOVE
      osd.menu_display = display_rect_from_window(hWnd, osd.display_area)
      Function = 0

    Case %WM_SETCURSOR
      If osd.fullscreen Then
        SetCursor %NULL
        Function = %TRUE
        Exit Function
      End If

    Case %WM_SetFocus
      osd.input_focus = %TRUE
      SendMessage(hWnd, %WM_Paint, 0, 0)
      Function = 0
      Exit Function

    Case %WM_KillFocus
      osd.input_focus = %FALSE
      SendMessage(hWnd, %WM_Paint, 0, 0)
      Function = 0
      Exit Function

    End Select

  Function = DefWindowProc(hWnd, message, wParam, lParam)
End Function

'============================================================
'  menu_start
'============================================================

Function menu_start(m As Long) As Long

    Local i, j, p, IsEditable, ISModified, IsFreqEditable, LineMax As Long

    IsEditable = is_custom(osd.current_mode)
    IsModified = IIf(osd.current_mode <> osd.backup_mode, %ENABLED, %DISABLED)
    IsFreqEditable = IsEditable And (osd.lock_vfreq Xor %TRUE)
    LineMax = OSDTotalLines(osd.current_mode)
    osd_cls()

    Select Case m

    Case %START_MENU
      menu_create_header(m, i, " Arcade OSD :: " + IIf$(osd.show_credits, $APP_VERSION, osd.method_string)) : osd.show_credits = 1
      menu_create_header(m, i, display_get_device_string(osd.target_display))
      menu_create_header(m, i, Using$("& &", osd.target_display, display_get_device_monitor(osd.target_display)))
      menu_create_line(m, j, "Video modes", %ENABLED, %White, %MAIN_MENU, %NONE, %NONE, %EXIT)
      menu_create_line(m, j, "Get mode from clipboard", modeline_from_clipboard(osd.clipboard_mode), %White, %SET_MODE_FROM_CLIPBOARD, %NONE, %NONE, %EXIT)
      menu_create_line(m, j, "Attach OSD to current monitor", %ENABLED, %White, %ATTACH_CURRENT, %NONE, %NONE, %EXIT)
      menu_create_line(m, j, "Lock unsupported modes          " + menu_option_text(%LOCK_UNSUPPORTEDMODES), %ENABLED, %White, %NONE, %LOCK_UNSUPPORTED_SET, %LOCK_UNSUPPORTED_SET, %EXIT)
      menu_create_line(m, j, "Exit", %ENABLED, %White, %EXIT, %NONE, %NONE, %EXIT)
      menu_create_help(m, p, "[ENTER/P1]Select  [P2]SwitchMonitor")
      menu_create_help(m, p, "[5/COIN]Attach    [ESC/BKSPC]Exit")

    Case %MAIN_MENU
      menu_create_header(m, i, display_get_device_string(osd.target_display))
      menu_create_header(m, i, " [ mode label ]  [Vfreq] [Hfreq] [type]")
      menu_create_header(m, i, " Xres Yres Vfrq    Hz      KHz         ")
      While j <= osd.mode_count
        menu_create_line(m, j, ModeInfoBar(osd.video_mode(j)), %ENABLED, IIf((osd.video_mode(j).type And %MODE_DESKTOP), %Cyan, IIf((osd.video_mode(j).type And %V_FREQ_EDITABLE), %White, %Gray)), %EDIT_START, %PAGE_UP, %PAGE_DOWN, %START_MENU)
      Wend
      Mnu(m).option_line(j)= ""
      menu_create_help(m, p, "[ENTER/P1]Test&EditFullScreen [P2]Edit")
      menu_create_help(m, p, "[UP/DOWN]SelectVideoMode      [ESC]Back")

    Case %EDIT_MENU
      menu_normal_header(m, i, "Edit Mode")
      menu_create_line(m, j, "Mode number      " + menu_option_text(%MODE_N), %ENABLED, %White, %TEST, %MODE_N_DEC, %MODE_N_INC, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Horizontal geometry ", IsEditable, %White, %HORZ_GEOMETRY, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Vertical geometry ", IsEditable, %White, %VERT_GEOMETRY, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Edit modeline ", IsEditable, %White, %EDIT_MODELINE, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Set as desktop mode", %ENABLED, %White, %SET_DESKTOP_MODE, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Copy modeline to clipboard", IsEditable, %White, %COPY_MODE_TO_CLIPBOARD, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Save changes ", IsModified, %Red, %SAVE, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_line(m, j, "Back " + IIf$(IsModified, "(undo changes)", ""), %ENABLED, %White, %RETURN_TO_MAIN, %NONE, %NONE, %RETURN_TO_MAIN)
      menu_create_help(m, p, "[ENTER/P1]Select  [P2]FullScreen_ON/OFF")
      menu_create_help(m, p, "[5/COIN]TestVfreq [ESC/BKSPC]Back")

    Case %HORZ_GEOMETRY
      menu_normal_header(m, i, "Horizontal geometry")
      menu_create_line(m, j, "Lock Vfreq      " + menu_option_text(%LOCK_VFREQ), IsEditable, %White, %NONE, %LOCK_VFREQ_SET, %LOCK_VFREQ_SET, %EDIT_MENU)
      menu_create_line(m, j, "DotClock        " + menu_option_text(%DOTCLOCK), IsFreqEditable, menu_option_color(%DOTCLOCK), %TEST, %DOTCLOCK_DEC, %DOTCLOCK_INC, %EDIT_MENU)
      menu_create_line(m, j, "H center        " + menu_option_text(%H_CENTER), IsEditable, menu_option_color(%H_CENTER), %TEST, %H_CENTER_DEC, %H_CENTER_INC, %EDIT_MENU )
      menu_create_line(m, j, "H active        " + menu_option_text(%H_ACT), %DISABLED, menu_option_color(%H_ACT), %TEST, %H_ACT_DEC, %H_ACT_INC, %EDIT_MENU )
      menu_create_line(m, j, "H front porch   " + menu_option_text(%H_F_PORCH), IsEditable, menu_option_color(%H_F_PORCH), %TEST, %H_F_PORCH_DEC, %H_F_PORCH_INC, %EDIT_MENU)
      menu_create_line(m, j, "H sync pulse    " + menu_option_text(%H_SYNC), IsEditable, menu_option_color(%H_SYNC), %TEST, %H_SYNC_DEC, %H_SYNC_INC, %EDIT_MENU )
      menu_create_line(m, j, "H back porch    " + menu_option_text(%H_B_PORCH), IsEditable, menu_option_color(%H_B_PORCH), %TEST, %H_B_PORCH_DEC, %H_B_PORCH_INC, %EDIT_MENU)
      menu_create_line(m, j, "H blanking      " + menu_option_text(%H_BLANK), %DISABLED, %White, %NONE, %NONE, %NONE, %EDIT_MENU)
      menu_create_line(m, j, "H total         " + menu_option_text(%H_AMP), %DISABLED, menu_option_color(%H_AMP), %TEST, %H_AMP_DEC, %H_AMP_INC, %EDIT_MENU )
      menu_create_line(m, j, "Test", IsEditable, %White, %TEST, %NONE, %NONE, %EDIT_MENU)
      menu_create_line(m, j, "Back", %ENABLED, %White, %EDIT_MENU, %NONE, %NONE, %EDIT_MENU)
      menu_create_help(m, p, "[ENTER/P1]Select  [P2]FullScreen_ON/OFF")
      menu_create_help(m, p, "[5/COIN]TestVfreq [ESC/BKSPC]Back")

    Case %VERT_GEOMETRY
      menu_normal_header(m, i, "Vertical geometry")
      menu_create_line(m, j, "Lock Vfreq      " + menu_option_text(%LOCK_VFREQ), IsEditable, %White, %NONE, %LOCK_VFREQ_SET, %LOCK_VFREQ_SET, %EDIT_MENU)
      menu_create_line(m, j, "DotClock        " + menu_option_text(%DOTCLOCK), IsFreqEditable, menu_option_color(%DOTCLOCK), %TEST, %DOTCLOCK_DEC, %DOTCLOCK_INC, %EDIT_MENU)
      menu_create_line(m, j, "V center        " + menu_option_text(%V_CENTER), IsEditable, menu_option_color(%V_CENTER), %TEST, %V_CENTER_DEC, %V_CENTER_INC, %EDIT_MENU)
      menu_create_line(m, j, "V active        " + menu_option_text(%V_ACT), %DISABLED, menu_option_color(%V_ACT), %TEST, %V_ACT_DEC, %V_ACT_INC, %EDIT_MENU)
      menu_create_line(m, j, "V front porch   " + menu_option_text(%V_F_PORCH), IsEditable, menu_option_color(%V_F_PORCH), %TEST, %V_F_PORCH_DEC, %V_F_PORCH_INC, %EDIT_MENU)
      menu_create_line(m, j, "V sync pulse    " + menu_option_text(%V_SYNC), IsEditable, menu_option_color(%V_SYNC), %TEST, %V_SYNC_DEC, %V_SYNC_INC, %EDIT_MENU )
      menu_create_line(m, j, "V back porch    " + menu_option_text(%V_B_PORCH), IsEditable, menu_option_color(%V_B_PORCH), %TEST, %V_B_PORCH_DEC, %V_B_PORCH_INC, %EDIT_MENU)
      menu_create_line(m, j, "V blanking      " + menu_option_text(%V_BLANK), %DISABLED, %White, %NONE, %NONE, %NONE, %EDIT_MENU)
      menu_create_line(m, j, "V total         " + menu_option_text(%V_AMP), %DISABLED, menu_option_color(%V_AMP), %TEST, %V_AMP_DEC, %V_AMP_INC, %EDIT_MENU)
      menu_create_line(m, j, "Test", IsModified, %White, %TEST, %NONE, %NONE, %EDIT_MENU)
      menu_create_line(m, j, "Back", %ENABLED, %White, %EDIT_MENU, %NONE, %NONE, %EDIT_MENU )
      menu_create_help(m, p, "[ENTER/P1]Select  [P2]FullScreen_ON/OFF")
      menu_create_help(m, p, "[5/COIN]TestVfreq [ESC/BKSPC]Back")

    Case %EDIT_MODELINE
      menu_normal_header(m, i, "Edit modeline")
      menu_create_line(m, j, "Lock Vfreq      " + menu_option_text(%LOCK_VFREQ), IsEditable, %White, %NONE, %LOCK_VFREQ_SET, %LOCK_VFREQ_SET, %EDIT_MENU)
      menu_create_line(m, j, "DotClock        " + menu_option_text(%DOTCLOCK), IsFreqEditable, menu_option_color(%DOTCLOCK), %TEST, %DOTCLOCK_DEC, %DOTCLOCK_INC, %EDIT_MENU)
'      menu_create_line(m, j, "H resolution    " + menu_option_text(%H_RES), %DISABLED, menu_option_color(%H_RES), %TEST, %H_RES_DEC, %H_RES_INC, %EDIT_MENU)
      menu_create_line(m, j, "H resolution    " + menu_option_text(%H_RES), IsEditable, menu_option_color(%H_RES), %TEST, %H_RES_DEC, %H_RES_INC, %EDIT_MENU)
      menu_create_line(m, j, "H retrace Start " + menu_option_text(%H_R_START), IsEditable, menu_option_color(%H_R_START), %TEST, %H_R_START_DEC, %H_R_START_INC, %EDIT_MENU)
      menu_create_line(m, j, "H retrace End   " + menu_option_text(%H_R_END), IsEditable, menu_option_color(%H_R_END), %TEST, %H_R_END_DEC, %H_R_END_INC, %EDIT_MENU)
      menu_create_line(m, j, "H total         " + menu_option_text(%H_TOTAL), IsEditable, menu_option_color(%H_TOTAL), %TEST, %H_TOTAL_DEC, %H_TOTAL_INC, %EDIT_MENU)
'      menu_create_line(m, j, "V resolution    " + menu_option_text(%V_RES), %DISABLED, menu_option_color(%V_RES), %TEST, %V_RES_DEC, %v_RES_INC, %EDIT_MENU)
      menu_create_line(m, j, "V resolution    " + menu_option_text(%V_RES), IsEditable, menu_option_color(%V_RES), %TEST, %V_RES_DEC, %V_RES_INC, %EDIT_MENU)
      menu_create_line(m, j, "V retrace Start " + menu_option_text(%V_R_START), IsEditable, menu_option_color(%V_R_START), %TEST, %V_R_START_DEC, %V_R_START_INC, %EDIT_MENU)
      menu_create_line(m, j, "V retrace End   " + menu_option_text(%V_R_END), IsEditable, menu_option_color(%V_R_END), %TEST, %V_R_END_DEC, %V_R_END_INC, %EDIT_MENU)
      menu_create_line(m, j, "V total         " + menu_option_text(%V_TOTAL), IsEditable, menu_option_color(%V_TOTAL), %TEST, %V_TOTAL_DEC, %V_TOTAL_INC, %EDIT_MENU)
      menu_create_line(m, j, "interlaced      " + menu_option_text(%INTERLACED), IsEditable, menu_option_color(%INTERLACED), %TEST, %INTERLACED_SET, %INTERLACED_SET, %EDIT_MENU)
      menu_create_line(m, j, "hsync polarity  " + menu_option_text(%H_SYNC_POL), IsEditable, menu_option_color(%H_SYNC_POL), %TEST, %H_SYNC_POL_SET, %H_SYNC_POL_SET, %EDIT_MENU)
      menu_create_line(m, j, "vsync polarity  " + menu_option_text(%V_SYNC_POL), IsEditable, menu_option_color(%V_SYNC_POL), %TEST, %V_SYNC_POL_SET, %V_SYNC_POL_SET, %EDIT_MENU)
      menu_create_line(m, j, "Test", IsModified, %White, %TEST, %NONE, %NONE, %EDIT_MENU)
      menu_create_line(m, j, "Back", %ENABLED, %White, %EDIT_MENU, %NONE, %NONE, %EDIT_MENU)
      menu_create_help(m, p, "[ENTER/P1]Select  [P2]FullScreen_ON/OFF")
      menu_create_help(m, p, "[5/COIN]TestVfreq [ESC/BKSPC]Back")

    Case %DESKTOP_MODE
      menu_create_header(m, i, "Keep this desktop resolution?")
      menu_create_line(m, j, "Revert", %ENABLED, %White, %RESTORE_DESKTOP_MODE, %NONE, %NONE, %RESTORE_DESKTOP_MODE)
      menu_create_line(m, j, "Keep", %ENABLED, %White, %SAVE_DESKTOP_MODE, %NONE, %NONE, %RESTORE_DESKTOP_MODE)
      menu_create_help(m, p, "[ENTER/P1]Select     [ESC/BKSPC]Back")

    End Select

    Mnu(m).header_count = i
    Mnu(m).option_count = j
    Mnu(m).help_count = p
    osd.line_count = IIf(i + j + p < LineMax, i + j + p, LineMax)
    osd.line_shown = osd.line_count - i - p

    i = 0
    While Mnu(m).header_line(i) <> ""
      osd_print(i, 1, Mnu(m).header_line(i), IIf(i, %White , IIf(osd.custom_video, %Green, %Red)), IIf(i, %Gray, %Blue))
      Incr i
    Wend

    j = 0 : p = 0
    p = Mnu(m).current_line - Mnu(m).cursor_line
    While Mnu(m).option_line(p) <> "" And i + j <> LineMax - Mnu(m).help_count
      osd_print(i + j, 2, Mnu(m).option_line(p), Mnu(m).color_option(p), IIf(Mnu(m).cursor_line = j, %Black, %DBLUE))
      Incr j : Incr p
    Wend

    p = 0
    While Mnu(m).help_line(p) <> ""
      osd_print(i + j + p, 1, Mnu(m).help_line(p), %White, %Gray)
      Incr p
    Wend

    If osd.current_menu <> m And osd.fullscreen = 0 Then Function = %RESIZE Else Function = %REFRESH
    osd.current_menu = m

End Function

'============================================================
'  menu_action
'============================================================

Function menu_action(skey As Long)As Long

  Local m, j, result As Long

  m = osd.current_menu
  j = Mnu(m).current_line

  If osd.test_state = 1 Then
    osd.test_state = 0
    result = %NONE

  Else
    Select Case skey
      Case %VK_ESCAPE
        SendMessage(osd.hwnd, %WM_KeyDown, %VK_BACK, %NULL)
        result = %NONE
      Case %VK_5
        result = menu_command(%M_VFREQ)
      Case %VK_2
        If osd.fullscreen Then
          result = menu_command(%FULLSCREEN_TURN_OFF)
        ElseIf m = %MAIN_MENU Then
          osd.fullscreen_edit_mode = 0
          result = menu_command(Mnu(m).option_command_ok(j))
        ElseIf m = %START_MENU Then
          result = menu_command(%SWITCH_MONITOR)
        Else
          osd.fullscreen_edit_mode = 1
          result = menu_command(%FULLSCREEN_TURN_ON)
        End If
      Case %VK_RETURN, %VK_1
        osd.fullscreen_edit_mode = 1
        result = menu_command(Mnu(m).option_command_ok(j))
      Case %VK_BACK
        result = menu_command(Mnu(m).option_command_back(j))
      Case %VK_LEFT, %VK_PRIOR, %VK_O
        result = menu_command(Mnu(m).option_command_left(j))
      Case %VK_RIGHT, %VK_NEXT, %VK_P
        result = menu_command(Mnu(m).option_command_right(j))
      Case %VK_UP, %VK_Q
        If Mnu(m).option_line(j - 1) <> "" Then
          Decr Mnu(m).current_line
          If Mnu(m).cursor_line > 0 Then Decr Mnu(m).cursor_line
          result = %REDRAW
        End If
      Case %VK_DOWN, %VK_A
        If Mnu(m).option_line(j + 1) <> "" Then
          Incr Mnu(m).current_line
          If Mnu(m).cursor_line < osd.line_count - Mnu(m).help_count - Mnu(m).header_count - 1 Then Incr Mnu(m).cursor_line
          result = %REDRAW
        End If
      Case %VK_D
        osd.debug_enabled Xor= 1
        ShowWindow(osd.h_debug, IIf(osd.debug_enabled, %SW_Show, %SW_Hide))
        SetFocus(osd.hwnd)
        result = %REDRAW
    End Select
  End If

  Function = result

End Function

'============================================================
'  menu_option_text
'============================================================

Function menu_option_text(Command As Long) As String

  Local option_text As String

  Local m As MODELINE Ptr
  m = VarPtr(osd.current_mode)

  Select Case Command
    Case %MODE_N
      option_text = Arrows(Using$("#/#(#)", osd.mode_idx, osd.mode_count, osd.custom_mode_count))
    Case %H_CENTER
      option_text = Arrows(Using$("#/#", (@m.htotal - @m.hend) / 8, (@m.hbegin - @m.hactive + @m.htotal - @m.hend) / 8))
    Case %H_AMP
      option_text = CharBox(@m.htotal) + HTimeBox(@m, @m.htotal)
    Case %H_ACT
      option_text = CharBox(@m.hactive) + HTimeBox(@m, @m.hactive)
    Case %H_F_PORCH
      option_text = CharBox(@m.hbegin - @m.hactive) + HTimeBox(@m, @m.hbegin - @m.hactive)
    Case %H_SYNC
      option_text = CharBox(@m.hend - @m.hbegin) + HTimeBox(@m, @m.hend - @m.hbegin)
    Case %H_B_PORCH
      option_text = CharBox(@m.htotal - @m.hend) + HTimeBox(@m, @m.htotal - @m.hend)
    Case %H_BLANK
      option_text = CharBox(@m.htotal - @m.hactive) + HTimeBox(@m, @m.htotal - @m.hactive)
    Case %V_CENTER
      option_text = Arrows(Using$("#/#",  @m.vtotal - @m.vend, @m.vbegin - @m.vactive + @m.vtotal - @m.vend))
    Case %V_AMP
      option_text = LineBox(@m.vtotal) + VTimeBox(@m, @m.vtotal)
    Case %V_ACT
      option_text = LineBox(@m.vactive) + VTimeBox(@m, @m.vactive)
    Case %V_F_PORCH
      option_text = LineBox(@m.vbegin - @m.vactive) + VTimeBox(@m, @m.vbegin - @m.vactive)
    Case %V_SYNC
      option_text = LineBox(@m.vend - @m.vbegin) + VTimeBox(@m, @m.vend - @m.vbegin)
    Case %V_B_PORCH
      option_text = LineBox(@m.vtotal - @m.vend) + VTimeBox(@m, @m.vtotal - @m.vend)
    Case %V_BLANK
      option_text = LineBox(@m.vtotal - @m.vactive) + VTimeBox(@m, @m.vtotal - @m.vactive)
    Case %DOTCLOCK
      option_text = Using$("[ #.## MHz(#)]", @m.pclock / 1000000, modeline_dotclock(@m))
    Case %H_RES
      option_text = PixelBox(@m.hactive) + HTimeBox(@m, @m.hactive)
    Case %H_R_START
      option_text = PixelBox(@m.hbegin) + HTimeBox(@m, @m.hbegin)
    Case %H_R_END
      option_text = PixelBox(@m.hend) + HTimeBox(@m, @m.hend)
    Case %H_TOTAL
      option_text = PixelBox(@m.htotal) + HTimeBox(@m, @m.htotal)
    Case %V_RES
      option_text = LineBox(@m.vactive) + VTimeBox(@m, @m.vactive)
    Case %V_R_START
      option_text = LineBox(@m.vbegin) + VTimeBox(@m, @m.vbegin)
    Case %V_R_END
      option_text = LineBox(@m.vend) + VTimeBox(@m, @m.vend)
    Case %V_TOTAL
      option_text = LineBox(@m.vtotal) + VTimeBox(@m, @m.vtotal)
    Case %INTERLACED
      option_text = Arrows(IIf$(@m.interlace, " yes", "  no"))
    Case %H_SYNC_POL
      option_text = Arrows(IIf$(@m.hsync, " +hsync", " -hsync"))
    Case %V_SYNC_POL
      option_text = Arrows(IIf$(@m.vsync, " +vsync", " -vsync"))
    Case %LOCK_VFREQ
      option_text = Arrows(IIf$(osd.lock_vfreq, " yes", "  no"))
    Case %LOCK_UNSUPPORTEDMODES
      option_text = Arrows(IIf$(osd.lock_unsupported_modes, " yes", "  no"))
  End Select

  Function = option_text
End Function

'============================================================
'  menu_option_color
'============================================================

Function menu_option_color(m_command As Long) As Long

  Local option_color As Long
  option_color = %White

  Local b, c As MODELINE Ptr
  b = VarPtr(osd.backup_mode)
  c = VarPtr(osd.current_mode)

  Select Case m_command
    Case %H_CENTER
      If @b.hbegin <> @c.hbegin Then option_color = %Cyan
    Case %H_AMP
      If @b.htotal <> @c.htotal Then option_color = %Cyan
    Case %H_ACT
      If @b.hactive <> @c.hactive Then option_color = %Cyan
    Case %H_F_PORCH
      If @b.hbegin - @b.hactive <> @c.hbegin - @c.hactive Then option_color = %Cyan
    Case %H_SYNC
      If @b.hend - @b.hbegin <> @c.hend - @c.hbegin Then option_color = %Cyan
    Case %H_B_PORCH
      If @b.htotal - @b.hend <> @c.htotal - @c.hend Then option_color = %Cyan
    Case %V_CENTER
      If @b.vbegin <> @c.vbegin Then option_color = %Cyan
    Case %V_AMP
      If @b.vtotal <> @c.vtotal Then option_color = %Cyan
    Case %V_ACT
      If @b.vactive <> @c.vactive Then option_color = %Cyan
    Case %V_F_PORCH
      If @b.vbegin - @b.vactive <> @c.vbegin - @c.vactive Then option_color = %Cyan
    Case %V_SYNC
      If @b.vend - @b.vbegin <> @c.vend - @c.vbegin Then option_color = %Cyan
    Case %V_B_PORCH
      If @b.vtotal - @b.vend <> @c.vtotal - @c.vend Then option_color = %Cyan
    Case %DOTCLOCK
      If @b.pclock <> @c.pclock Then option_color = %Cyan
    Case %H_RES
      If @b.hactive <> @c.hactive Then option_color = %Cyan
    Case %H_R_START
      If @c.hbegin <= @c.hactive Then option_color = %Red Else If @b.hbegin <> @c.hbegin Then option_color = %Cyan
    Case %H_R_END
      If @c.hend <= @c.hbegin Then option_color = %Red Else If @b.hend <> @c.hend Then option_color = %Cyan
    Case %H_TOTAL
      If @c.htotal <= @c.hend Then option_color = %Red Else If @b.htotal <> @c.htotal Then option_color = %Cyan
    Case %V_RES
      If @b.vactive <> @c.vactive Then option_color = %Cyan
    Case %V_R_START
      If @c.vbegin <= @c.vactive Then option_color = %Red Else If @b.vbegin <> @c.vbegin Then option_color = %Cyan
    Case %V_R_END
      If @c.vend <= @c.vbegin Then option_color = %Red Else If @b.vend <> @c.vend Then option_color = %Cyan
    Case %V_TOTAL
      If @c.vtotal <= @c.vend Then option_color = %Red Else If @b.vtotal <> @c.vtotal Then option_color = %Cyan
    Case %INTERLACED
      If @b.interlace <> @c.interlace Then option_color = %Cyan
  End Select

  Function = option_color
End Function

'============================================================
'  menu_command
'============================================================

Function menu_command(mCommand As Long)As Long

  Local result As Long

  osd.previous_state = osd.current_mode

  Select Case mCommand

    ' Start Menu
    Case %START_MENU
      result = menu_start(%START_MENU)
    Case %MAIN_MENU
      result = menu_start(%MAIN_MENU)
    Case %RETURN_TO_MAIN
      osd_unload_video_mode(osd.current_mode)
      result = menu_start(%MAIN_MENU)
    Case %SWITCH_MONITOR
      osd.menu_display = display_get_next_display(osd.menu_display, osd.display_area)
      result = %RESIZE_CENTER
    Case %ATTACH_CURRENT
      osd.target_display = display_rect_from_window(osd.hwnd, osd.display_area)
      osd_display_init(osd.target_display)
      result = %REDRAW
    Case %LOCK_UNSUPPORTED_SET
      osd.lock_unsupported_modes Xor= %TRUE
      osd_display_init(osd.target_display)
      result = %REDRAW
    Case %SET_MODE_FROM_CLIPBOARD
      Local found As Long
      found = osd_find_video_mode(osd.clipboard_mode)
      If found <> -1 Then
        osd.mode_idx = found
        osd.clipboard_mode.type Or= custom_video_get_method()
        mnu(%MAIN_MENU).current_line = found
        osd_load_video_mode(osd.video_mode(osd.mode_idx))
        osd.current_mode = osd.clipboard_mode
        menu_command(%TEST)
        result = menu_start(%EDIT_MENU)
      End If

    ' Mode list Menu
    Case %EDIT_START
      osd.mode_idx = mnu(%MAIN_MENU).current_line
      osd_load_video_mode(osd.video_mode(osd.mode_idx))
      If osd.fullscreen_edit_mode Then menu_command(%TEST)
      result = menu_start(%EDIT_MENU)
    Case %EDIT_MENU
      result = menu_start(%EDIT_MENU)
    Case %HORZ_GEOMETRY
      result = menu_start(%HORZ_GEOMETRY)
    Case %VERT_GEOMETRY
      result = menu_start(%VERT_GEOMETRY)
    Case %EDIT_MODELINE
      result = menu_start(%EDIT_MODELINE)

    ' Edit Menu
    Case %M_VFREQ
      If osd.fullscreen Then result = osd_measure_vfreq(osd)
    Case %MODE_N_DEC
      If osd.mode_idx > 0 Then
        Decr osd.mode_idx
        Mnu(%MAIN_MENU).current_line = osd.mode_idx
        If Mnu(%MAIN_MENU).cursor_line > 0 Then Decr Mnu(%MAIN_MENU).cursor_line
      End If
      result = menu_command(%EDIT_START)
    Case %MODE_N_INC
      If osd.mode_idx < osd.mode_count Then
        Incr osd.mode_idx
        Mnu(%MAIN_MENU).current_line = osd.mode_idx
        If Mnu(%MAIN_MENU).cursor_line < OSDTotalLines(osd.current_mode)- Mnu(%MAIN_MENU).help_count - Mnu(%MAIN_MENU).header_count - 1 Then Incr Mnu(%MAIN_MENU).cursor_line
      End If
      result = menu_command(%EDIT_START)
    Case %TEST
      osd_test_video_mode(osd.current_mode)
      result = %REDRAW
    Case %SAVE
      osd_save_video_mode(osd.current_mode)
      result = %REDRAW
    Case %SET_DESKTOP_MODE
      menu_command(%FULLSCREEN_TURN_OFF)
      display_set_desktop_mode(osd.target_display,_
        IIf((osd.current_mode.type And %MODE_ROTATED), osd.current_mode.height, osd.current_mode.width),_
        IIf((osd.current_mode.type And %MODE_ROTATED), osd.current_mode.width, osd.current_mode.height),_
        osd.current_mode.refresh,_
        osd.current_mode.bpp,_
        osd.current_mode.interlace,_
        %CDS_RESET)
      Mnu(%DESKTOP_MODE).current_line = 0
      Mnu(%DESKTOP_MODE).cursor_line = 0
      menu_start(%DESKTOP_MODE)
      result = %RESIZE_CENTER
    Case %COPY_MODE_TO_CLIPBOARD
      modeline_to_clipboard(osd.current_mode)
      result = %REDRAW
    Case %FULLSCREEN_TURN_OFF
      osd_exit_fullscreen()
      osd.fullscreen_edit_mode = 0
      result = %RESIZE
    Case %FULLSCREEN_TURN_ON
      result = menu_command(%TEST)
    Case %PAGE_UP
      osd.mode_idx -= 12
      If osd.mode_idx < 12 Then
        osd.mode_idx = 0
        Mnu(%MAIN_MENU).cursor_line = osd.mode_idx
      End If
      Mnu(%MAIN_MENU).current_line = osd.mode_idx
      result = %REDRAW
    Case %PAGE_DOWN
      osd.mode_idx += 12
      If osd.mode_idx > osd.mode_count - 12 Then
        osd.mode_idx = osd.mode_count
        Mnu(%MAIN_MENU).cursor_line = osd.line_count - Mnu(%MAIN_MENU).help_count - Mnu(%MAIN_MENU).header_count - 1
      End If
      Mnu(%MAIN_MENU).current_line = osd.mode_idx
      result = %REDRAW
    Case %RESET
      result = %RESET
    Case %EXIT
      result = %EXIT
    Case %NONE
      result = %NONE

    ' Desktop mode / desktop mode default menu
    Case %SAVE_DESKTOP_MODE
      display_set_desktop_mode(osd.target_display,_
        IIf((osd.current_mode.type And %MODE_ROTATED), osd.current_mode.height, osd.current_mode.width),_
        IIf((osd.current_mode.type And %MODE_ROTATED), osd.current_mode.width, osd.current_mode.height),_
        osd.current_mode.refresh,_
        osd.current_mode.bpp,_
        osd.current_mode.interlace,_
        %CDS_UPDATEREGISTRY)
      osd_mark_new_desktop_mode(osd.current_mode)
      menu_start(%MAIN_MENU)
      result = %RESIZE_CENTER
    Case %RESTORE_DESKTOP_MODE
      display_restore_desktop_mode(osd.target_display, %CDS_RESET)
      menu_start(%EDIT_MENU)
      result = %RESIZE_CENTER

    ' Edit modeline
    Case %DOTCLOCK_DEC
      If osd.current_mode.pclock > 0 Then osd.current_mode.pclock = osd.current_mode.pclock - 1000 * 10
      result = %REDRAW
    Case %DOTCLOCK_INC
      osd.current_mode.pclock = osd.current_mode.pclock + 1000 * 10
      result = %REDRAW
    Case %H_RES_DEC
      If osd.current_mode.hactive > 0 Then osd.current_mode.hactive -= 8
      result = %REDRAW
    Case %H_RES_INC
      If osd.current_mode.hactive < %HTOT_MAX Then osd.current_mode.hactive += 8
      result = %REDRAW
    Case %H_R_START_DEC
      If osd.current_mode.hbegin > 0 Then osd.current_mode.hbegin -= 8
      result = %REDRAW
    Case %H_R_START_INC
      osd.current_mode.hbegin += 8
      result = %REDRAW
    Case %H_R_END_DEC
      If osd.current_mode.hend > 0 Then osd.current_mode.hend -= 8
      result = %REDRAW
    Case %H_R_END_INC
      osd.current_mode.hend += 8
      result = %REDRAW
    Case %H_TOTAL_DEC
      If osd.current_mode.htotal > 0 Then osd.current_mode.htotal -= 8
      result = %REDRAW
    Case %H_TOTAL_INC
      osd.current_mode.htotal += 8
      result = %REDRAW
    Case %V_RES_DEC
      If osd.current_mode.vactive > 0 Then Decr osd.current_mode.vactive
      result = %REDRAW
    Case %V_RES_INC
      If osd.current_mode.vactive < %VTOT_MAX Then Incr osd.current_mode.vactive
      result = %REDRAW
    Case %V_R_START_DEC
      If osd.current_mode.vbegin > 0 Then Decr osd.current_mode.vbegin
      result = %REDRAW
    Case %V_R_START_INC
      Incr osd.current_mode.vbegin
      result = %REDRAW
    Case %V_R_END_DEC
      If osd.current_mode.vend > 0 Then Decr osd.current_mode.vend
      result = %REDRAW
    Case %V_R_END_INC
      Incr osd.current_mode.vend
      result = %REDRAW
    Case %V_TOTAL_DEC
      If osd.current_mode.vtotal > 0 Then Decr osd.current_mode.vtotal
      result = %REDRAW
    Case %V_TOTAL_INC
      Incr osd.current_mode.vtotal
      result = %REDRAW

    ' Horizontal geometry menu
    Case %H_CENTER_DEC
      If osd.current_mode.htotal - osd.current_mode.hend > 8 Then
        osd.current_mode.hbegin += 8
        osd.current_mode.hend += 8
      End If
      result = %REDRAW
    Case %H_CENTER_INC
      If osd.current_mode.hbegin - osd.current_mode.hactive > 8 Then
        osd.current_mode.hbegin -= 8
        osd.current_mode.hend -= 8
      End If
      result = %REDRAW
    Case %H_AMP_DEC
      If osd.current_mode.htotal - osd.current_mode.hend > 8 Then osd.current_mode.htotal -= 8
      result = %REDRAW
    Case %H_AMP_INC
      osd.current_mode.htotal += 8
      result = %REDRAW
    Case %H_ACT_DEC
      If osd.current_mode.hactive > 8    Then
        osd.current_mode.hactive -= 8
        osd.current_mode.hbegin -= 8
        osd.current_mode.hend -= 8
        osd.current_mode.htotal -= 8
      End If
      result = %REDRAW
    Case %H_ACT_INC
      If osd.current_mode.htotal < %HTOT_MAX Then
        osd.current_mode.hactive += 8
        osd.current_mode.hbegin += 8
        osd.current_mode.hend += 8
        osd.current_mode.htotal += 8
      End If
      result = %REDRAW
    Case %H_F_PORCH_DEC
      If osd.current_mode.hbegin - osd.current_mode.hactive > 8 Then
        osd.current_mode.hbegin -= 8
        osd.current_mode.hend -= 8
        osd.current_mode.htotal -= 8
      End If
      result = %REDRAW
    Case %H_F_PORCH_INC
      osd.current_mode.hbegin += 8
      osd.current_mode.hend += 8
      osd.current_mode.htotal += 8
      result = %REDRAW
    Case %H_SYNC_DEC
      If osd.current_mode.hend - osd.current_mode.hbegin > 8 Then
        osd.current_mode.hend -= 8
        osd.current_mode.htotal -= 8
      End If
      result = %REDRAW
    Case %H_SYNC_INC
      osd.current_mode.hend += 8
      osd.current_mode.htotal += 8
      result = %REDRAW
    Case %H_B_PORCH_DEC
      If osd.current_mode.htotal - osd.current_mode.hend > 8 Then osd.current_mode.htotal -= 8
      result = %REDRAW
    Case %H_B_PORCH_INC
      osd.current_mode.htotal += 8
      result = %REDRAW

    'Vertical geometry
    Case %V_CENTER_DEC
      If osd.current_mode.vtotal - osd.current_mode.vend > 1 Then
        Incr osd.current_mode.vbegin
        Incr osd.current_mode.vend
      End If
      result = %REDRAW
    Case %V_CENTER_INC
      If osd.current_mode.vbegin - osd.current_mode.vactive > 1 Then
        Decr osd.current_mode.vbegin
        Decr osd.current_mode.vend
      End If
      result = %REDRAW
    Case %V_AMP_DEC
      If osd.current_mode.vtotal - osd.current_mode.vend > 1 Then Decr osd.current_mode.vtotal
      result = %REDRAW
    Case %V_AMP_INC
      Incr osd.current_mode.vtotal
      result = %REDRAW
    Case %V_ACT_DEC
      If osd.current_mode.vactive > 1 Then
        Decr osd.current_mode.vactive
        Decr osd.current_mode.vbegin
        Decr osd.current_mode.vend
        Decr osd.current_mode.vtotal
      End If
      result = %REDRAW
    Case %V_ACT_INC
      If osd.current_mode.vactive < %VTOT_MAX Then
        Incr osd.current_mode.vactive
        Incr osd.current_mode.vbegin
        Incr osd.current_mode.vend
        Incr osd.current_mode.vtotal
      End If
      result = %REDRAW
    Case %V_F_PORCH_DEC
      If osd.current_mode.vbegin - osd.current_mode.vactive > 1 Then
        Decr osd.current_mode.vbegin
        Decr osd.current_mode.vend
        Decr osd.current_mode.vtotal
      End If
      result = %REDRAW
    Case %V_F_PORCH_INC
      Incr osd.current_mode.vbegin
      Incr osd.current_mode.vend
      Incr osd.current_mode.vtotal
      result = %REDRAW
    Case %V_SYNC_DEC
      If osd.current_mode.vend - osd.current_mode.vbegin > 1 Then
        Decr osd.current_mode.vend
        Decr osd.current_mode.vtotal
      End If
      result = %REDRAW
    Case %V_SYNC_INC
      Incr osd.current_mode.vend
      Incr osd.current_mode.vtotal
      result = %REDRAW
    Case %V_B_PORCH_DEC
      If osd.current_mode.vtotal - osd.current_mode.vend > 1 Then Decr osd.current_mode.vtotal
      result = %REDRAW
    Case %V_B_PORCH_INC
      Incr osd.current_mode.vtotal
      result = %REDRAW
    Case %INTERLACED_SET
      osd.current_mode.interlace Xor= %TRUE
      result = %REDRAW
    Case %H_SYNC_POL_SET
      osd.current_mode.hsync Xor= %TRUE
      result = %REDRAW
    Case %V_SYNC_POL_SET
      osd.current_mode.vsync Xor= %TRUE
      result = %REDRAW
    Case %LOCK_VFREQ_SET
      osd.lock_vfreq Xor= %TRUE
      result = %REDRAW
  End Select

  If osd.current_mode <> osd.previous_state Then
    If osd.lock_vfreq Then modeline_reclock(osd.backup_mode, osd.current_mode)
    modeline_compute_frequency(osd.current_mode)
  End If

  Function = result
End Function

'============================================================
'  menu_create_header
'============================================================

Sub menu_create_header(m As Long, idx As Long, HeaderLine As String)

  If idx < %MENU_HEADER_MAX Then
    Mnu(m).header_line(idx) = HeaderLine
    Incr idx
  End If
End Sub

'============================================================
'  menu_normal_header
'============================================================

Sub menu_normal_header(m As Long, idx As Long, HeaderTitle As String)

  menu_create_header(m, idx, ModeCaption(osd.backup_mode)+ "- " + HeaderTitle)
  menu_create_header(m, idx, " [Xres] [Yres] [V (Hz)] [H(kHz)] " )
  menu_create_header(m, idx, ModeRealRes(osd.current_mode)+ ModeVFreq(osd.current_mode)+ " " + ModeHFreq(osd.current_mode))
End Sub

'============================================================
'  menu_create_help
'============================================================

Sub menu_create_help(m As Long, idx As Long, HelpLine As String)

  If idx < %MENU_HELP_MAX Then
    Mnu(m).help_line(idx) = HelpLine
    Incr idx
  End If
End Sub

'============================================================
'  menu_create_line
'============================================================

Sub menu_create_line(m As Long, idx As Long, MenuOption As String, Enabled As Long, ColorOption As Long, CommandOK As Long, CommandLeft As Long, CommandRight As Long, CommandBack As Long)

  If idx < %MENU_OPTION_MAX Then
    Mnu(m).option_line(idx) = MenuOption
    If Enabled Then
      Mnu(m).color_option(idx) = ColorOption
      Mnu(m).option_command_ok(idx) = CommandOK
      Mnu(m).option_command_left(idx) = CommandLeft
      Mnu(m).option_command_right(idx) = CommandRight
    Else
      Mnu(m).color_option(idx) = %Gray
      Mnu(m).option_command_ok(idx) = %NONE
      Mnu(m).option_command_left(idx) = %NONE
      Mnu(m).option_command_right(idx) = %NONE
    End If
    Mnu(m).option_command_back(idx) = CommandBack
    Incr idx
  End If

End Sub

'============================================================
'  osd_find_video_mode
'============================================================

Function osd_find_video_mode(m As MODELINE) As Long

  Local j As Long
  Local v As MODELINE Ptr

  While j <= osd.mode_count
    v = VarPtr(osd.video_mode(j))
    If is_custom(@v) Then
      If @v.width = m.width And @v.height = m.height And @v.refresh = m.refresh Then Function = j : Exit Function
    End If
    Incr j
  Wend

  Function = -1
End Function

'============================================================
'  osd_load_video_mode
'============================================================

Function osd_load_video_mode(m As MODELINE) As Long

  ' Check if we need to restore a previously modified mode
  osd_unload_video_mode(osd.current_mode)

  osd.current_mode = m
  osd.backup_mode = m
  osd.driver_mode = m
  osd.previous_state = m

End Function

'============================================================
'  osd_unload_video_mode
'============================================================

Function osd_unload_video_mode(m As MODELINE) As Long

  If m.hactive Then osd_sync_video_mode(osd.backup_mode)
  osd_exit_fullscreen()

  ' Some APIs require manual reset of desktop mode (PowerStrip)
  Local i As Long
  While osd.video_mode(i).width
    If (osd.video_mode(i).type And %MODE_DESKTOP) Then
      Local dm As DEVMODE
      display_get_desktop_mode(osd.target_display, dm)
      If osd.video_mode(i).width <> dm.dmPelsWidth Or osd.video_mode(i).height <> dm.dmPelsHeight Or osd.video_mode(i).refresh <> dm.dmDisplayFrequency Then
        display_set_desktop_mode(osd.target_display,_
          IIf((osd.video_mode(i).type And %MODE_ROTATED), osd.video_mode(i).height, osd.video_mode(i).width),_
          IIf((osd.video_mode(i).type And %MODE_ROTATED), osd.video_mode(i).width, osd.video_mode(i).height),_
          osd.video_mode(i).refresh,_
          osd.video_mode(i).bpp,_
          osd.video_mode(i).interlace,_
          %CDS_RESET Or %CDS_UPDATEREGISTRY)
      End If
    End If
    Incr i
  Wend

End Function

'============================================================
'  osd_save_video_mode
'============================================================

Function osd_save_video_mode(m As MODELINE) As Long

  osd.current_mode = m
  osd.backup_mode = m

  ' Check if an update is required
  osd_sync_video_mode(m)
  osd.video_mode(osd.mode_idx) = m

End Function

'============================================================
'  osd_sync_video_mode
'============================================================

Function osd_sync_video_mode(m As MODELINE) As Long

  If m <> osd.driver_mode Then
    osd.driver_mode = m
    custom_video_update_timing(m)
  End If

End Function

'============================================================
'  osd_read_video_mode_from_hw
'============================================================

Function osd_read_video_mode_from_hw(m As MODELINE) As Long

  Local hw_mode As MODELINE
  hw_mode = m

  If custom_video_read_timing(hw_mode) Then
    m = hw_mode
    osd.current_mode = m
    osd.backup_mode = m
    osd.driver_mode = m
    osd.previous_state = m
    Function = 1
  End If
End Function

'============================================================
'  osd_test_video_mode
'============================================================

Function osd_test_video_mode(m As MODELINE) As Long

  osd_render_lock = %TRUE

  ' Make sure we're not in fullscreen mode
  osd_exit_fullscreen()

  ' Check if an update is required
  osd_sync_video_mode(m)

  ' Get ready for fullscreen
  SetWindowLong(osd.hwnd, %GWL_STYLE, %WS_Popup)
  osd.fullscreen = %TRUE

  ' Create fullscreen display
  Local m_width, m_height As Long
  m_width = IIf((m.type And %MODE_ROTATED), m.height, m.width)
  m_height = IIf((m.type And %MODE_ROTATED), m.width, m.height)

  If render_init(osd.hwnd, osd.target_display, m_width, m_height, m.refresh, m.bpp, m.interlace) Then

    ' Try to read actual video registers
    If m.hactive = 0 Then osd_read_video_mode_from_hw(m)

    Local hdc As Long
    osd.pattern_buffer = render_create_bitmap(m_width + 8, m_height + 8)
    hdc = render_get_dc(osd.pattern_buffer)
    draw_grid_pattern(hdc, m)
    render_release_dc(osd.pattern_buffer, hdc)
    osd_set_font_size(m)
    Function = 1

  Else
    osd.fullscreen = %FALSE
    osd_resize(%OSD_SIZE_AND_CENTER)
    clog "osd_test_video_mode: render_init error"
  End If

  osd_render_lock = %FALSE

End Function

'============================================================
'  osd_exit_fullscreen
'============================================================

Function osd_exit_fullscreen() As Long

  If osd.fullscreen Then
     osd.fullscreen = 0
     render_exit()
  End If

End Function

'============================================================
'  osd_mark_new_desktop_mode
'============================================================

Function osd_mark_new_desktop_mode(m As MODELINE) As Long

  Local i As Long
  While osd.video_mode(i).width
    If osd.video_mode(i).width = m.width And osd.video_mode(i).height = m.height And osd.video_mode(i).refresh = m.refresh Then
      osd.video_mode(i).type Or= %MODE_DESKTOP
    Else
      osd.video_mode(i).type And= Not %MODE_DESKTOP
    End If
    Incr i
  Wend

End Function

'============================================================
'  osd_display_init
'============================================================

Function osd_display_init(ByVal device_name As String) As Long

  If IsFalse display_get_devices() Then clog "osd_display_init: Error enumerating displays."
  osd.custom_video = custom_video_init(device_name)
  osd.method_string = custom_video_get_driver_name()

  Dim video_mode(%MODES_MAX) As MODELINE At VarPtr(osd.video_mode(0))
  osd.mode_count = display_get_available_video_modes(device_name, video_mode(), IIf(osd.lock_unsupported_modes, %NULL, %EDS_RAWMODE))
  osd.custom_mode_count = custom_video_get_mode_list(video_mode())

  Mnu(%MAIN_MENU).current_line = 0
  Mnu(%MAIN_MENU).cursor_line = 0
  osd.show_credits = 0

End Function

'============================================================
'  osd_resize
'============================================================

Function osd_resize(action As Long) As Long

  If osd.menu_display <> "" Then display_get_rect_from_display(osd.menu_display, osd.display_area)

  Local m As MODELINE
  m.width = Abs(osd.display_area.nRight - osd.display_area.nLeft)
  m.height = Abs(osd.display_area.nBottom - osd.display_area.nTop)
  osd_set_font_size(m)

  osd_set_size_and_pos(osd.display_area, action)
  If IsFalse osd.fullscreen Then InvalidateRect(%NULL, "", %TRUE)

End Function

'============================================================
'  osd_set_font_size
'============================================================

Function osd_set_font_size(m As MODELINE) As Long

  Local xres, yres As Long
  xres = IIf((m.type And %MODE_ROTATED), m.height, m.width)
  yres = IIf((m.type And %MODE_ROTATED), m.width, m.height)

  osd.font_face = "Lucida console"

  If yres < 300 Then
    osd.font_height = 10
  ElseIf yres >= 300 And yres < 400 Then
    osd.font_height = 14
  ElseIf yres >= 400 And yres < 2560 Then
    osd.font_height = 24
  Else
    osd.font_height = 64
  End If

  If xres < 400 Then
    osd.font_width = 6
  ElseIf xres >= 400 And xres < 640 Then
    osd.font_width = 9
  ElseIf xres < 1024 Then
    osd.font_width = 14
  Else
    osd.font_width = Max(14, 14 * (xres / 640) * (osd.font_height / yres) / (24 / 480))
  End If


  Function = 1
End Function

'============================================================
'  osd_set_size_and_pos
'============================================================

Function osd_set_size_and_pos(display_rect As RECT, action As Long) As Long

  osd.xsize = %OSD_WIDTH * osd.font_width
  osd.ysize = osd.line_count * osd.font_height

  If action = %OSD_SIZE_AND_CENTER Then
    osd.xpos = display_rect.nLeft + (display_rect.nRight - display_rect.nLeft - osd.xsize) / 2
    osd.ypos = display_rect.nTop + (display_rect.nBottom - display_rect.nTop - osd.ysize) / 2
  End If

  If osd.hwnd Then Function = SetWindowPos(osd.hwnd, -1, osd.xpos, osd.ypos, osd.xsize, osd.ysize, %SWP_SHOWWINDOW)
End Function

'============================================================
'  osd_check_size
'============================================================

Function osd_check_size() As Long

  Local wnd_rect As RECT
  GetWindowRect(osd.hwnd, wnd_rect)
  If osd.xsize <> (wnd_rect.right - wnd_rect.left) Or osd.ysize <> (wnd_rect.bottom - wnd_rect.top) Then osd_resize(%OSD_SIZE_AND_CENTER)
End Function

'============================================================
'  osd_measure_vfreq
'============================================================

Function osd_measure_vfreq(osd As OSD_DEF) As Long

  Local h_thread As Long

  osd.measured_vfreq = 0
  osd.test_state = %TRUE

  Thread Create get_vfreq(VarPtr(osd)) To h_thread
  Thread Set Priority h_thread, %Thread_Priority_Time_Critical

  Function = %NONE
End Function

Thread Function get_vfreq(ByVal osd As OSD_DEF Ptr) As Long

  Local frequency, performance_count, ticks_begin, ticks_gone As Quad
  Local frames, iteration As Long

  QueryPerformanceFrequency(frequency)
  QueryPerformanceCounter(performance_count)

  ticks_begin = performance_count

  While @osd.test_state = 1
    SendMessage(@osd.hwnd, %WM_Paint, 0, 0)
    Incr frames

    If frames = 300 Then
      QueryPerformanceCounter(performance_count)
      ticks_gone = performance_count - ticks_begin
      If iteration Then @osd.measured_vfreq = 300 / (ticks_gone / frequency)

      frames = 0
      Incr iteration
      If iteration = 3 Then @osd.test_state = 0
      ticks_begin = performance_count
    End If
  Wend

  @osd.current_mode.vfreq = @osd.measured_vfreq
  @osd.backup_mode.vfreq = @osd.measured_vfreq
  menu_start(@osd.current_menu)
  SendMessage(@osd.hwnd, %WM_Paint, 0, 0)

  Function = -1
End Function

'============================================================
'  osd_cls
'============================================================

Sub osd_cls()

  Local i As Long
  For i = 0 To osd.line_count
    osd.line_text(i)= Space$(osd.width)
    osd.line_color_f(i)= %White
    osd.line_color_b(i)= %Black
  Next
End Sub

'============================================================
'  osd_print
'============================================================

Sub osd_print(i As Long, j As Long, ByVal TextString As String, ColorF As Long, ColorB As Long)

  Mid$(osd.line_text(i), j)= TextString
  osd.line_color_f(i)= ColorF
  osd.line_color_b(i)= ColorB
End Sub

'============================================================
'  osd_update
'============================================================

Function osd_update(m As MODELINE, hWnd As Long) As Long

  Local hfont, xpos, ypos, i, hDC As Long
  Local txtvfreq As AsciiZ * 255
  Static iter As Long

  If osd_render_lock Then Exit Function

  ' Catch any possible window size mismatch
  If IsFalse osd.fullscreen Then osd_check_size()

  ' Draw background, only in fullscreen mode
  If osd.fullscreen Then
    Local xres, yres As Long
    xres = IIf((m.type And %MODE_ROTATED), m.height, RealRes(m.width))
    yres = IIf((m.type And %MODE_ROTATED), RealRes(m.width), m.height)
    xpos = (xres - osd.width * osd.font_width) / 2
    ypos = (yres - osd.line_count * osd.font_height) / 2

    If IsFalse render_is_ready() Then clog "Error: Rendering backend not ready" : Exit Function

    If osd.test_state Then
      Incr iter
      Local s_rect, d_rect As RECT
      s_rect.nLeft = iter Mod 8
      s_rect.nTop = iter Mod 8
      s_rect.nRight = xres + iter Mod 8
      s_rect.nBottom = yres + iter Mod 8
      d_rect.nLeft = 0
      d_rect.nTop = 0
      d_rect.nRight = xres
      d_rect.nBottom = yres
      render_blit_to_back_buffer(osd.pattern_buffer, s_rect, d_rect)
    Else
       iter = 0
    End If

    hDC = render_get_back_buffer_dc()
    If IsFalse hDC Then clog "Error: not valid hDC" : Exit Function
    draw_mode_frame(m, hDC)

  Else
    hDC = GetDC(hWnd)
  End If

  ' Draw OSD text
  Local font_quality As Long
  font_quality = IIf(osd.win_version > 5 And osd.fullscreen = 0, %CLEARTYPE_QUALITY, %NONANTIALIASED_QUALITY)
  hFont = CreateFont(-osd.font_height, osd.font_width, 0, 0, %FW_NORMAL, 0, 0, 0, %DEFAULT_CHARSET, %OUT_DEFAULT_PRECIS, %CLIP_DEFAULT_PRECIS, font_quality, %DEFAULT_PITCH, osd.font_face)
  SelectObject hDC, hFont

  For i = 0 To osd.line_count - 1
    draw_text_line(osd.line_text(i), xpos, ypos + i * osd.font_height, IIf(osd.input_focus, osd.line_color_f(i), %Gray), IIf(osd.input_focus, osd.line_color_b(i), %LtGray), hDC)
  Next

  If osd.test_state Then draw_text_line(IIf$(osd.measured_vfreq, Using$("###.###", osd.measured_vfreq), " please wait ..."), xpos + 15 * osd.font_width, ypos + 2 * osd.font_height, %Red, %Gray,  hDC)
  DeleteObject(hFont)

  ' Draw scroll bar
  draw_scroll_bar(hDC, xpos, ypos)

  ' Flip and waitvsync in fullscreen mode
  If osd.fullscreen Then
    render_release_back_buffer_dc(hDC)
    render_flip()
  Else
    ReleaseDC(hWnd, hDC)
  End If

  Function = 1
End Function

'============================================================
'  draw_text_line
'============================================================

Function draw_text_line(text_string As AsciiZ, xpos As Long, ypos As Long, text_color As Long, bk_color As Long, hdc As Long) As Long

  SetBkColor(hdc, bk_color)
  SetTextColor(hdc, text_color)
  Function = TextOut(hDC, xpos, ypos, text_string, Len(text_string))
End Function

'============================================================
'  draw_scroll_bar
'============================================================

Sub draw_scroll_bar(hDC As Long, xpos As Long, ypos As Long)

  Local hpen, hbrush, ytot, ylen, ydes As Long

  hpen = CreatePen(0, 1, %Black)
  SelectObject(hDC, hpen)

  hbrush = CreateSolidBrush(%Gray)
  SelectObject(hDC, hbrush)

  ypos = ypos + Mnu(osd.current_menu).header_count * osd.font_height
  ytot = osd.line_shown * osd.font_height
  ylen = osd.line_shown / Mnu(osd.current_menu).option_count * ytot
  ydes =(Mnu(osd.current_menu).current_line - Mnu(osd.current_menu).cursor_line)/ Mnu(osd.current_menu).option_count * ytot

  rectangle(hDC, xpos, ypos, xpos + osd.font_width, ypos + ytot )

  DeleteObject(hbrush)
  hbrush = CreateSolidBrush(%LtGray)
  SelectObject(hDC, hbrush)

  rectangle(hDC, xpos, ypos + ydes, xpos + osd.font_width, ypos + ydes + ylen)

  DeleteObject(hpen)
  hpen = CreatePen(%PS_DOT, 1, %White)
  SelectObject(hDC, hpen)

  xpos = xpos + osd.font_width
  ypos = ypos + Mnu(osd.current_menu).cursor_line * osd.font_height
  MoveTo(hDC, xpos, ypos)
  LineTo(hDC, xpos +(osd.width - 1)* osd.font_width, ypos)
  MoveTo(hDC, xpos, ypos + osd.font_height - 1)
  LineTo(hDC, xpos +(osd.width - 1)* osd.font_width, ypos + osd.font_height - 1)

  DeleteObject(hpen)
  DeleteObject(hbrush)

End Sub

'============================================================
'  draw_mode_frame
'============================================================

Sub draw_mode_frame(m As MODELINE, hdc As Long)

  Local hpen, xres, yres, i As Long
  Local gRect As GRADIENT_RECT

  xres = IIf((m.type And %MODE_ROTATED), m.height, RealRes(m.width))
  yres = IIf((m.type And %MODE_ROTATED), RealRes(m.width), m.height)

  If osd.test_state = 0 Then

    Dim vert(1) As TRIVERTEX
    vert(0).x      = 0
    vert(0).y      = 0
    vert(0).Red    = 0
    vert(0).Green  = &hff00
    vert(0).Blue   = 0
    vert(0).Alpha  = 0
    vert(1).x      = xres
    vert(1).y      = yres
    vert(1).Red    = &hff00
    vert(1).Green  = 0
    vert(1).Blue   = 0
    vert(1).Alpha  = 0
    gRect.UpperLeft  = 0
    gRect.LowerRight = 1
    GradientFill(hdc, vert(0), 2, gRect, 1, %GRADIENT_FILL_RECT_V)

    hpen = CreatePen(0, 1, &h808080)
    SelectObject(hdc, hpen)

    For i = 0 Mod 8 To xres Step 8
      MoveTo(hdc, i, 1)
      LineTo(hdc, i, yres - 1)
    Next

    For i = 0 Mod 8 To yres Step 8
      MoveTo(hdc, 1, i)
      LineTo(hdc, xres - 1, i)
    Next

    DeleteObject(hpen)

  End If

  hpen = CreatePen(0, 1, &hffffff)
  SelectObject(hdc, hpen)
  MoveTo(hdc, 0, 0)
  LineTo(hdc, xres - 1, 0)
  LineTo(hdc, xres - 1, yres -1)
  LineTo(hdc, 0, yres - 1)
  LineTo(hdc, 0, 0)

  Local med As Long
  med = Min(xres, yres) / 2
  LineTo(hdc, med, med)
  MoveTo(hdc, 0, yres - 1)
  LineTo(hdc, med, yres - med - 1)
  MoveTo(hdc, xres - 1, 0)
  LineTo(hdc, xres - 1 - med, med )
  MoveTo(hdc, xres - 1, yres - 1)
  LineTo(hdc, xres - 1 - med, yres - med - 1)

  DeleteObject(hpen)

End Sub

'============================================================
'  draw_grid_pattern
'============================================================

Function draw_grid_pattern(hdc As Long, m As MODELINE) As Long

  Local hpen, i As Long
  Local pattern_width, pattern_height As Long

  pattern_width  = IIf((m.type And %MODE_ROTATED), m.height, m.width) + 8
  pattern_height = IIf((m.type And %MODE_ROTATED), m.width, m.height) + 8

  hpen = CreatePen(0, 1, &h808080)
  SelectObject(hdc, hpen)

  For i = 0 To pattern_width Step 8
    MoveTo(hdc, i, 1)
    LineTo(hdc, i, pattern_height - 1)
  Next

  For i = 0 To pattern_height Step 8
    MoveTo(hdc, 1, i)
    LineTo(hdc, pattern_width - 1, i)
  Next

  DeleteObject(hpen)

  Function = 1
End Function

Function Arrows(String1 As String)As String
  Function = "[" + String1 + "]"
End Function

Function LineFormat(String1 As String, String2 As String)As String
  Function = $Spc + String1 + Space$(78 - Len(String1 + String2)) + String2 + $Spc
End Function

Function RealRes(x As Long)As Long
  Function = Int(x / 8)* 8
End Function

Function is_custom(m As MODELINE) As Long
  Function = IIf((m.type And %CUSTOM_VIDEO_TIMING_MASK), 1, 0)
End Function

Function OSDTotalLines(VM As MODELINE)As Long
  Local LineMax As Long
  LineMax = IIf(osd.fullscreen, Int(VM.height / osd.font_height), Int(osd.display_area.nBottom / osd.font_height))
  Function = IIf(LineMax < %OSD_HEIGHT, LineMax, %OSD_HEIGHT)
End Function

Function ModeInfoBar(VM As MODELINE)As String
  Function = ModeRegLabel(VM)+ ModeVFreq(VM)+ ModeHFreq(VM)+ mode_custom(VM)
End Function

Function ModeRegLabel(VM As MODELINE)As String
  Function = Using$("#### #### ", VM.width, VM.height)+ IIf$(VM.refresh, Using$("###", VM.refresh)+ ModeInterlace(VM), " def ")
End Function

Function ModeVFreq(VM As MODELINE)As String
  Function = IIf$(VM.refresh, Using$(" ###.###", IIf(VM.vfreq, VM.vfreq, VM.refresh)), "  ......")
End Function

Function ModeHFreq(VM As MODELINE)As String
  Function = IIf$(VM.hfreq, Using$(" ###.###", VM.hfreq / 1000), " .......")
End Function

Function ModeRealRes(VM As MODELINE)As String
  Function = Using$("###### ###### ", IIf(VM.hactive, VM.hactive, VM.width), IIf(VM.vactive, VM.vactive, VM.height))
End Function

Function ModeCaption(VM As MODELINE)As String
  Function = Using$(" #x#@#", VM.width, VM.height, VM.refresh)+ ModeInterlace(VM)
End Function

Function ModeInterlace(VM As MODELINE)As String
  Function = IIf$(VM.interlace, "i ", "p ")
End Function

Function mode_custom(m As MODELINE) As String
  Function = IIf$(is_custom(m), " custom", " native")
End Function

Function mode_interlace(m As MODELINE) As Long
  Function = IIf(m.interlace, 2, 1)
End Function

Function mode_line_time(m As MODELINE) As Double
  Function = IIf(m.hfreq, 1 / (m.hfreq), 0)
End Function

Function mode_char_time(m As MODELINE) As Double
  Function = mode_line_time(m) * 8 / m.htotal
End Function

Function NormalBox(n As Long)As String
  Function = Arrows(Using$("####", n))
End Function

Function PixelBox(n As Long)As String
  Function = Arrows(Using$("#### px", n))
End Function

Function CharBox(n As Long)As String
  Function = Arrows(Using$("#### ch", n / 8))
End Function

Function LineBox(n As Long)As String
  Function = Arrows(Using$("#### ln", n))
End Function

Function HTimeBox(m As MODELINE, n As Long)As String
  Function = Arrows(Using$("####.### " + Chr$(181)+ "s", n / 8 * mode_char_time(m) * 1000000)) 's -> us
End Function

Function VTimeBox(m As MODELINE, n As Long)As String
  Function = Arrows(Using$("####.### " + "ms", n * mode_line_time(m) / mode_interlace(m) * 1000)) 's -> ms
End Function
