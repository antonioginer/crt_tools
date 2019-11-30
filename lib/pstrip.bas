'==============================================================================
'
'  PowerStrip library
'  pstrip.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include Once "win32api.inc"
#Include "modeline.inc"
#Include "log_console.inc"

%UM_SETCUSTOMTIMING     = %WM_User + 200
%UM_SETCUSTOMTIMINGFAST = %WM_User + 211
%UM_SETREFRESHRATE      = %WM_User + 201
%UM_SETPOLARITY         = %WM_User + 202
%UM_REMOTECONTROL       = %WM_User + 210
%UM_SETGAMMARAMP        = %WM_User + 203
%UM_CREATERESOLUTION    = %WM_User + 204
%UM_GETTIMING           = %WM_User + 205
%UM_GETSETCLOCKS        = %WM_User + 206

%HSYNC_POLARITY_POS = &h00
%VSYNC_POLARITY_POS = &h00
%HSYNC_POLARITY_NEG = &h02
%VSYNC_POLARITY_NEG = &h04
%INTERLACED         = &h08

%HideTrayIcon       = &h00
%ShowTrayIcon       = &h01
%ClosePowerStrip    = &h63

Global hPSWnd As Long
Global timing_backup As AsciiZ * 255

'============================================================
'  ps_init
'============================================================

Function ps_init(monitor_index As Long) Common As Long

  hPSWnd = FindWindow ("TPShidden", ByVal %NULL)
  If hPSWnd Then timing_backup = ps_get_monitor_timing(monitor_index)

  Function = hPSWnd
End Function

'============================================================
'  ps_reset
'============================================================

Function ps_reset(monitor_index As Long) Common As Long

  Function = ps_set_monitor_timing(monitor_index, timing_backup)
End Function

'============================================================
'  ps_get_monitor_timing
'============================================================

Function ps_get_monitor_timing(monitor_index As Long) Common As String

  Local lresult As Long
  Local monitor_timing As AsciiZ * 255
  Local fname As String

  fname = Using$("PStrip.GetMonitorTiming(#): ", monitor_index)

  lresult = SendMessage(hPSWnd, %UM_GETTIMING, monitor_index, 0)
  If lresult < 0 Then
    clog fname + "Could not get PowerStrip timing string"
    Function = ""
    Exit Function
  End If

  GlobalGetAtomName( lresult, monitor_timing, SizeOf(monitor_timing))
  GlobalDeleteAtom(lresult)
  clog fname + monitor_timing

  Function = monitor_timing
End Function

'============================================================
'  ps_set_monitor_timing
'============================================================

Function ps_set_monitor_timing(monitor_index As Long, monitor_timing As AsciiZ) Common As Long

  Local lresult As Long
  Local atom As Word
  Local fname As String

  fname = Using$("PStrip.SetMonitorTiming(#): ", monitor_index)

  atom = GlobalAddAtom(monitor_timing)

  If atom Then

    lresult = SendMessage(hPSWnd, %UM_SETCUSTOMTIMING, monitor_index, atom)
    If lresult < 0 Then
      clog fname + "SendMessage failed"
      GlobalDeleteAtom(atom)
    Else
      clog fname + monitor_timing
      Function = 1
      Exit Function
    End If

  Else
    clog fname + "atom creation failed"
  End If

End Function

'============================================================
'  ps_set_refresh
'============================================================

Function ps_set_refresh(monitor_index As Long, Refresh As Long) Common As Long

  Local lresult As Long
  Local fname As String

  fname = Using$("PStrip.SetMonitorRefresh(#): ", monitor_index)

  lresult = SendMessage(hPSWnd, %UM_SETREFRESHRATE, monitor_index, Refresh)
  If lresult < 0 Then
    clog fname + "error setting refresh rate"
  Else
    clog fname + "refresh rate set to" + Str$(Refresh)
    Function = 1
  End If

End Function

'============================================================
'  ps_set_modeline_list
'============================================================

Function ps_set_modeline_list(monitor_index As Long, m() As MODELINE) Common As Long

  Local i, j As Long

  While m(i).width
    If IsFalse ps_create_mode(monitor_index, ps_pstiming_from_modeline(m(i))) Then
      clog Using$("Mode & rejected by driver.", modeline_print(m(i), %MS_LABEL))
      Incr j
    End If
    Incr i
  Wend

  Function = i - j
End Function

'============================================================
'  ps_create_mode
'============================================================

Function ps_create_mode(monitor_index As Long, monitor_timing As AsciiZ) Common As Long

  Local lresult As Long
  Local atom As Word
  Local fname As String

  fname = Using$("PStrip.CreateResolution(#): ", monitor_index)

  atom = GlobalAddAtom(monitor_timing)

  If atom Then

    lresult = SendMessage(hPSWnd, %UM_CREATERESOLUTION, monitor_index, atom)
    If lresult < 0 Then
      clog fname + "SendMessage failed"
      GlobalDeleteAtom(atom)
    Else
      Function = 1
      Exit Function
    End If
  Else
    clog fname + "atom creation failed"
  End If

End Function

'============================================================
'  ps_pstiming_from_modeline
'============================================================

Function ps_pstiming_from_modeline(m As MODELINE) As String

  Function = Using$( "#_,#_,#_,#_,#_,#_,#_,#_,#_,#",  m.hactive, _
                                                      m.hbegin - m.hactive, _
                                                      m.hend - m.hbegin, _
                                                      m.htotal - m.hend, _
                                                      m.vactive, _
                                                      m.vbegin - m.vactive, _
                                                      m.vend - m.vbegin, _
                                                      m.vtotal - m.vend, _
                                                      Int(m.pclock / 1000), _
                                                      IIf(m.interlace, %INTERLACED, 0) Or _
                                                      IIf(m.hsync, %HSYNC_POLARITY_POS, %HSYNC_POLARITY_NEG) Or _
                                                      IIf(m.vsync, %VSYNC_POLARITY_POS, %VSYNC_POLARITY_NEG))
End Function

'============================================================
'  ps_get_timing
'============================================================

Function ps_set_timing(m As MODELINE, monitor_index As Long) Common As Long

  ps_set_monitor_timing(monitor_index, ps_pstiming_from_modeline(m))
  ps_get_timing(m, monitor_index)

End Function

'============================================================
'  ps_get_timing
'============================================================

Function ps_get_timing(m As MODELINE, monitor_index As Long) Common As Long

  Local PSTiming As String

  PSTiming = ps_get_monitor_timing(monitor_index)
  If PSTiming = "" Then Exit Function

  Local v As MODELINE
  v.hactive = Val(Parse$(PSTiming, 1))
  v.hbegin  = Val(Parse$(PSTiming, 2)) + v.hactive
  v.hend    = Val(Parse$(PSTiming, 3)) + v.hbegin
  v.htotal  = Val(Parse$(PSTiming, 4)) + v.hend
  v.vactive = Val(Parse$(PSTiming, 5))
  v.vbegin  = Val(Parse$(PSTiming, 6)) + v.vactive
  v.vend    = Val(Parse$(PSTiming, 7)) + v.vbegin
  v.vtotal  = Val(Parse$(PSTiming, 8)) + v.vend
  v.pclock  = Val(Parse$(PSTiming, 9)) * 1000 ' kHZ -> Hz

  Local flags As Long
  flags = Val(Parse$(PSTiming, 10))
  v.interlace = IIf((flags And %INTERLACED), 1, 0)
  v.hsync = IIf((flags And %HSYNC_POLARITY_NEG), 0, 1)
  v.vsync = IIf((flags And %VSYNC_POLARITY_NEG), 0, 1)

  ' Only return modeline if timings match requested mode
  If m.width  = v.hactive And m.height = v.vactive Then
    m.hactive = v.hactive
    m.hbegin  = v.hbegin
    m.hend    = v.hend
    m.htotal  = v.htotal
    m.vactive = v.vactive
    m.vbegin  = v.vbegin
    m.vend    = v.vend
    m.vtotal  = v.vtotal
    m.pclock  = v.pclock
    m.interlace = v.interlace
    m.hsync   = v.hsync
    m.vsync   = v.vsync
    Function = 1
  End If

End Function

'============================================================
'  ps_monitor_index
'============================================================

Function ps_monitor_index(display_name As String) Common As Long
  Function = Val(Right$(display_name, 1))
End Function
