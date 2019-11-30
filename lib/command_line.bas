'==============================================================================
'
'  VideoModeMaker
'  command_line.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "Win32API.inc"
#Include "log_console.inc"
#Include "util.inc"

%COMMAND_SIZE = 256
%COMMAND_PROMPT_WIDTH = 64
%COMMAND_LIST_COUNT = 4
%WM_NEW_COMMAND = %WM_User + 3000

Global h_prompt, h_command, h_parent As Long
Global cmd_list_head, cmd_list_tail, cmd_list_current, cmd_list_full, cmd_list_is_new As Long

'============================================================
'  command_line_init
'============================================================

Function command_line_init(h_dialog As Long, idc_prompt As Long, idc_command As Long, x As Long, y As Long, c_width As Long, c_height As Long, prompt As String) Common As Long

  Dim command_list(%COMMAND_LIST_COUNT) As Global AsciiZ * %COMMAND_SIZE

  Local vista As Long
  vista = IIf(os_version() > 5, 1, 0)

  Local font_height As Long
  font_height = - MulDiv(IIf(vista, 10, 8), GetDeviceCaps(CreateDC("DISPLAY", ByVal 0, ByVal 0, ByVal 0), %LOGPIXELSY), 72)

  Local h_font_command As Long
  h_font_command = CreateFont(font_height, 0, 0, 0, %FW_NORMAL, 0, 0, 0, %OEM_CHARSET, %OUT_DEFAULT_PRECIS, %CLIP_DEFAULT_PRECIS, IIf(vista, %CLEARTYPE_QUALITY, %DEFAULT_QUALITY), %FIXED_PITCH, IIf$(vista, "Consolas", "Lucida Console"))

  Control Add Label, h_dialog, idc_prompt, prompt, x, y, %COMMAND_PROMPT_WIDTH, c_height
  Control Handle h_dialog, idc_prompt To h_prompt
  Control Set Color h_dialog, idc_prompt, %Gray, %Black
  SendMessage(h_prompt, %WM_SETFONT, h_font_command, %TRUE)

  Control Add TextBox, h_dialog, idc_command, "", x + %COMMAND_PROMPT_WIDTH, y, c_width - %COMMAND_PROMPT_WIDTH, c_height, %ES_AutoHScroll Or %WS_TabStop
  Control Handle h_dialog, idc_command To h_command
  Control Send h_dialog, idc_command, %EM_SETLIMITTEXT, %COMMAND_SIZE, 0
  Control Set Color h_dialog, idc_command, %Gray, %Black
  SendMessage(h_command, %WM_SETFONT, h_font_command, %TRUE)
  SetWindowLong(h_command, %GWL_USERDATA, SetWindowLong(h_command, %GWL_WNDPROC, CodePtr(control_proc)))

  h_parent = h_dialog
  Function = h_command
End Function

'============================================================
'  command_line_resize
'============================================================

Function command_line_resize(x As Long, y As Long, c_width As Long, c_height As Long) Common As Long
  SetWindowPos(h_prompt, 0, x, y, %COMMAND_PROMPT_WIDTH, c_height, 0)
  SetWindowPos(h_command, 0, x + %COMMAND_PROMPT_WIDTH, y, c_width - %COMMAND_PROMPT_WIDTH, c_height, 0)
End Function

'============================================================
'  control_proc
'============================================================

Function control_proc(ByVal hWnd As Dword, ByVal wMsg As Dword, ByVal wParam As Dword, ByVal lParam As Long) As Long

  Local new_command As AsciiZ * %COMMAND_SIZE

  Select Case wMsg

    ' Gain access to Enter keys from our control
    Case %WM_GETDLGCODE
      If IsTrue lParam Then
        Local ptmsg As tagMsg Ptr
        ptmsg = lParam
        If (@ptmsg.message = %WM_KeyDown) Or (@ptmsg.message = %WM_KeyUp) Then
          If @ptmsg.wParam = %VK_RETURN Then Function = %DlgC_WantMessage : Exit Function
          If @ptmsg.wParam = %VK_ESCAPE Then Function = %DlgC_WantMessage : Exit Function
        End If
      End If

    ' Hide Enter from original proc so it doesn't beep
    Case %WM_Char
      If wParam = &h0D Or wParam = &h1B Then Exit Function

    ' Process Enter
    Case %WM_KeyDown
      Select Case wParam

        Case %VK_RETURN
          Function = CallWindowProc(GetWindowLong(hWnd, %GWL_USERDATA), hWnd, wMsg, wParam, lParam)
          GetWindowText(hWnd, new_command, %COMMAND_SIZE)
          SetWindowText(hWnd, "")
          command_line_save_command(new_command)
          SendMessage(hWnd, %EM_SETSEL, 0, 0)
          SendMessage(h_parent, %WM_NEW_COMMAND, 0, VarPtr(new_command))
          Exit Function

        Case %VK_UP
          Function = CallWindowProc(GetWindowLong(hWnd, %GWL_USERDATA), hWnd, wMsg, wParam, lParam)
          SetWindowText(hWnd, command_line_get_command_up())
          command_line_set_cursor()
          Exit Function

        Case %VK_DOWN
          Function = CallWindowProc(GetWindowLong(hWnd, %GWL_USERDATA), hWnd, wMsg, wParam, lParam)
          SetWindowText(hWnd, command_line_get_command_down())
          command_line_set_cursor()
          Exit Function

        Case %VK_ESCAPE
          Function = CallWindowProc(GetWindowLong(hWnd, %GWL_USERDATA), hWnd, wMsg, wParam, lParam)
          SetWindowText(hWnd, "")
          Exit Function

        Case Else
          cmd_list_is_new = 1
      End Select

    Case %WM_SetFocus
      command_line_set_cursor()


    Case %WM_Destroy
      Function = CallWindowProc(GetWindowLong(hWnd, %GWL_USERDATA), hWnd, wMsg, wParam, lParam)
      SetWindowLong(hWnd, %GWL_WNDPROC, GetWindowLong(hwnd, %GWL_USERDATA))
      Exit Function

    End Select

  Function = CallWindowProc(GetWindowLong(hWnd, %GWL_USERDATA), hWnd, wMsg, wParam, lParam)
End Function

'============================================================
'  command_line_set_focus
'============================================================

Function command_line_set_focus() Common As Long
  SetFocus(h_command)
End Function

'============================================================
'  command_line_set_cursor
'============================================================

Function command_line_set_cursor() As Long

  Local new_command As AsciiZ * %COMMAND_SIZE

  GetWindowText(h_command, new_command, %COMMAND_SIZE)
  SendMessage(h_command, %EM_SETSEL, Len(new_command), Len(new_command))

End Function

'============================================================
'  command_line_save_command
'============================================================

Function command_line_save_command(new_command As AsciiZ) As Long

  If new_command = "" Then Exit Function
  command_list(cmd_list_head) = new_command
  Incr cmd_list_head

  If cmd_list_head > %COMMAND_LIST_COUNT Then
    cmd_list_head = 0
    cmd_list_full = 1
  End If

  If cmd_list_full Then
    Incr cmd_list_tail
    If cmd_list_tail > %COMMAND_LIST_COUNT Then cmd_list_tail = 0
  End If

  If cmd_list_is_new Then
    cmd_list_current = cmd_list_head
    cmd_list_is_new = 0
  End If

End Function

'============================================================
'  command_line_get_command_up
'============================================================

Function command_line_get_command_up() As String

  If cmd_list_current <> cmd_list_tail Then
    Decr cmd_list_current
    If cmd_list_current < 0 Then
      If cmd_list_full Then
        cmd_list_current = %COMMAND_LIST_COUNT
      Else
        cmd_list_current = 0
      End If
    End If
  End If

  Function = command_list(cmd_list_current)
End Function

'============================================================
'  command_line_get_command_down
'============================================================

Function command_line_get_command_down() As String

  If cmd_list_current <> cmd_list_head - 1 Then
    Incr cmd_list_current
    If cmd_list_current > %COMMAND_LIST_COUNT Then
      If cmd_list_full And cmd_list_head Then
        cmd_list_current = 0
      Else
        cmd_list_current = %COMMAND_LIST_COUNT
      End If
    End If
  End If

  Function = command_list(cmd_list_current)
End Function
