'==============================================================================
'
'  Console output box
'  log_console.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "Win32API.inc"
#Include "log_console.inc"
#Include "util.inc"

Global console_lock As CRITICAL_SECTION
Global console_stdout As Long
Global console_stdin As Long
Global console_update_pending As Long
Global console_initialized As Long

Global console_text As String
Global console_text_length As Long
Global console_caret_pos As Long

Global h_console As Long
Global h_parent As Long

'============================================================
'  log_console_create
'============================================================

Function log_console_create() Common As String

  If console_initialized Then Exit Function
  InitializeCriticalSectionAndSpinCount(console_lock, &h00000400)

  Local file_type As Long
  console_stdout = GetStdHandle(%STD_OUTPUT_HANDLE)
  console_stdin = GetStdHandle(%STD_INPUT_HANDLE)

  FreeConsole()
  AttachConsole(%ATTACH_PARENT_PROCESS)

  ' Check if our output is redirected to a file
  file_type = GetFileType(console_stdout)
  If file_type = %FILE_TYPE_DISK Or file_type = %FILE_TYPE_PIPE Then
    SetStdHandle(%STD_OUTPUT_HANDLE, console_stdout)
  Else
    console_stdout = GetStdHandle(%STD_OUTPUT_HANDLE)
  End If

  ' Check if our input is redirected from a file and return it so it can be processed
  file_type = GetFileType(console_stdin)
  If file_type = %FILE_TYPE_DISK Or file_type = %FILE_TYPE_PIPE Then
    Local stdin_file As String
    Local p_overlapped As OVERLAPPED
    SetStdHandle(%STD_INPUT_HANDLE, console_stdin)
    stdin_file = String$(GetFileSize(console_stdin, 0), 0)
    ReadFile(console_stdin, ByVal StrPtr(stdin_file), Len(stdin_file), ByVal %NULL, p_overlapped)
    Function = stdin_file
  Else
    console_stdin = GetStdHandle(%STD_INPUT_HANDLE)
  End If

  console_initialized = 1
End Function

'============================================================
'  log_console_close
'============================================================

Function log_console_destroy() Common As Long

  If IsFalse console_initialized Then Exit Function
  DeleteCriticalSection(console_lock)
  FreeConsole()

  Local file_num As Long
  file_num = FreeFile
  Open "log.txt" For Output As file_num
  Print #file_num, console_text

  Function = 1
End Function

'============================================================
'  log_console_init
'============================================================

Function log_console_gui_init(h_dialog As Long, idc As Long, x As Long, y As Long, c_width As Long, c_height As Long) Common As Long

  Local vista As Long
  vista = IIf(os_version() > 5, 1, 0)

  Control Add TextBox, h_dialog, idc, "", x, y, c_width, c_height, %ES_MultiLine Or %ES_ReadOnly Or %ES_AutoHScroll Or %ES_AutoVScroll Or %WS_VScroll Or %ES_WantReturn Or %WS_TabStop
  Control Handle h_dialog, idc To h_console
  Control Send h_dialog, idc, %EM_SETLIMITTEXT, %EDIT_BOX_SIZE, 0
  Control Set Color h_dialog, idc, %Gray, %Black

  Local font_height As Long
  font_height = - MulDiv(IIf(vista, 10, 8), GetDeviceCaps(CreateDC("DISPLAY", ByVal 0, ByVal 0, ByVal 0), %LOGPIXELSY), 72)

  Local h_font_console As Long
  h_font_console = CreateFont(font_height, 0, 0, 0, %FW_NORMAL, 0, 0, 0, %OEM_CHARSET, %OUT_DEFAULT_PRECIS, %CLIP_DEFAULT_PRECIS, IIf(vista, %CLEARTYPE_QUALITY, %DEFAULT_QUALITY), %FIXED_PITCH, IIf$(vista, "Consolas", "Lucida Console"))
  SendMessage(h_console, %WM_SETFONT, h_font_console, %TRUE)
  PostMessage(h_dialog, %WM_CONSOLE, 0, 0)

  h_parent = h_dialog
  Function = h_console
End Function

'============================================================
'  log_console_update
'============================================================

Function log_console_update() Common As Long

  If IsFalse console_initialized Then Exit Function

  EnterCriticalSection(console_lock)

  Static editbox_caret_pos As Long
  Local pending_length As Long
  pending_length = console_text_length - editbox_caret_pos

  Local pending_text As AsciiZ * 32767
  pending_text = Right$(console_text, Max(pending_length, 0))
  SendMessage(h_console, %EM_SETSEL, editbox_caret_pos, console_text_length)
  SendMessage(h_console, %EM_REPLACESEL, 0, VarPtr(pending_text))
  editbox_caret_pos = Min(console_caret_pos, console_text_length)

  LeaveCriticalSection(console_lock)

  Function = 1
End Function

'============================================================
'  log_console_gui_resize
'============================================================

Function log_console_gui_resize(c_width As Long, c_height As Long) Common As Long
  SetWindowPos(h_console, 0, 0, 0, c_width, c_height, %SWP_NOMOVE)
End Function

'============================================================
'  log_console_get_text
'============================================================

Function log_console_get_text() Common As String
  Function = console_text
End Function

'============================================================
'  log_console_output "clog"
'============================================================

Function clog(new_text As String) Common As Long

  If IsFalse console_initialized Then Exit Function

  EnterCriticalSection(console_lock)

  Local crlf As Long
  crlf = IIf(Right$(new_text, 1) <> ";", 1, 0)
  new_text = IIf$(crlf, new_text, Clip$(Right new_text, 1)) + IIf$(crlf, $CrLf, $Cr)
  console_text = Left$(console_text, console_caret_pos) + new_text
  console_text_length = Len(console_text)
  console_caret_pos = IIf(crlf, console_text_length, console_caret_pos)

  If h_parent Then
    PostMessage(h_parent, %WM_CONSOLE, 0, 0)
  Else
    Local p_overlapped As OVERLAPPED
    p_overlapped.Offset = IIf(crlf, &h0FFFFFFFF, console_caret_pos)
    p_overlapped.OffsetHigh = IIf(crlf, &h0FFFFFFFF, 0)
    WriteFile(console_stdout, ByVal StrPtr(new_text), Len(new_text), ByVal %NULL, p_overlapped)
  End If

  LeaveCriticalSection(console_lock)

  Function = 1
End Function
