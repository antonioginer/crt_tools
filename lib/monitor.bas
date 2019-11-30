'==============================================================================
'
'  Monitor library
'  monitor.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "monitor.inc"
#Include "modeline.inc"

Declare Function clog(t As String) Common As Long
Declare Function modeline_vesa_gtf(m As MODELINE) Common As Long

'============================================================
'  monitor_get_default_options
'============================================================

Function monitor_get_default_options(options As MONITOR_OPTIONS) Common As Long

  options.m_name = "generic_15"
  options.orientation = "horizontal"
  monitor_parse_ini(options)

End Function

'============================================================
'  monitor_parse_ini
'============================================================

Function monitor_parse_ini(options As MONITOR_OPTIONS) Common As Long

  Local new_line, option_name, option_text As String
  Local m_name, m_name_long, m_aspect As String

  Local monitor_ini As Long
  monitor_ini = FreeFile
  Open $MONITOR_INI For Input As monitor_ini

  Local i_range As Long
  i_range = -1

  Dim monitor(%MAX_PRESETS) As MONITOR_DEF
  Dim monitor As MONITOR_DEF Ptr

  While Not Eof(monitor_ini)

    Local line_number As Long
    Incr line_number

    Line Input #monitor_ini, new_line
    new_line = Trim$(Parse$(new_line, "#", 1), Any $Spc + $Tab)
    If new_line = "" Then Iterate Loop

    option_name = LCase$(Parse$(new_line, $Spc, 1))
    option_text = Clip$(Left new_line, Len(option_name))

    Select Case Const$ Trim$(option_name, Any "0123456789")

      Case "monitor"
        ' Check if previous monitor definition is empty
        If i_range = 0 Then
          Reset @monitor
          clog "no ranges defined for monitor " + m_name
        End If

        m_name = LCase$(Trim$(Parse$(option_text, 1), Any $Spc + $Tab))
        m_name_long = Trim$(Parse$(option_text, 2), Any $Spc + $Tab)
        m_aspect = Trim$(Parse$(option_text, 3), Any $Spc + $Tab)
        If m_name = "" Or m_name_long = "" Or m_aspect = "" Then clog Using$("monitor definition error at line #", line_number): GoTo exit_error

        Local i As Long : i = 0
        While monitor(i).m_name <> ""
          If monitor(i).m_name = m_name Then clog Using$("monitor definition duplicated at line #", line_number): GoTo Exit_Error
          Incr i
        Wend
        monitor(i).m_name = m_name
        monitor(i).m_name_long = m_name_long
        monitor(i).m_aspect = m_aspect
        monitor(i).m_aspect_ratio = Val(Parse$(m_aspect, ":", 1)) / Val(Parse$(m_aspect, ":", 2))

        monitor = VarPtr(monitor(i))
        i_range = 0

      Case "crt_range"
        If i_range < %MAX_RANGES Then
          monitor_fill_range(@monitor.m_range(i_range), option_text)
          Incr i_range
        Else
          clog "too many ranges defined for monitor " + m_name
        End If

      Case "gtf_range"
        If i_range < %MAX_RANGES Then
          monitor_fill_vesa_range(@monitor.m_range(i_range), option_text)
          Incr i_range
        Else
          clog "too many ranges defined for monitor " + m_name
        End If

      Case Else
        clog Using$("syntax error at line #", line_number)

    End Select
  Wend

  For i = 0 To %MAX_PRESETS
    options.preset(i) = monitor(i)
  Next
  Function = 1

  exit_error:
  Close monitor_ini

End Function

'============================================================
'  monitor_get_specs
'============================================================

Function monitor_get_specs(ByVal m_name As String, options As MONITOR_OPTIONS) Common As Long

  Local i As Long
  While options.preset(i).m_name <> "" And i < %MAX_PRESETS
    If options.preset(i).m_name = m_name Then
      options.monitor = VarPtr(options.preset(i))
      Function = 1
      Exit Function
    End If
    Incr i
  Wend

End Function

'============================================================
'  monitor_fill_range
'============================================================

Function monitor_fill_range(m_range As MONITOR_RANGE, ByVal specs_line As String) As Long

    Local new_range As MONITOR_RANGE

    If specs_line <> "auto" Then
        If ParseCount (specs_line, Any ",-") = 16 Then
            new_range.h_freq_min = Val(Parse$(specs_line, Any ",-", 1))
            new_range.h_freq_max = Val(Parse$(specs_line, Any ",-", 2))
            new_range.v_freq_min = Val(Parse$(specs_line, Any ",-", 3))
            new_range.v_freq_max = Val(Parse$(specs_line, Any ",-", 4))
            new_range.h_front_porch = Val(Parse$(specs_line, Any ",-", 5))
            new_range.h_sync_pulse = Val(Parse$(specs_line, Any ",-", 6))
            new_range.h_back_porch = Val(Parse$(specs_line, Any ",-", 7))
            new_range.v_front_porch = Val(Parse$(specs_line, Any ",-", 8))
            new_range.v_sync_pulse = Val(Parse$(specs_line, Any ",-", 9))
            new_range.v_back_porch = Val(Parse$(specs_line, Any ",-", 10))
            new_range.h_sync_polarity = Val(Parse$(specs_line, Any ",-", 11))
            new_range.v_sync_polarity = Val(Parse$(specs_line, Any ",-", 12))
            new_range.progressive_lines_min = Val(Parse$(specs_line, Any ",-", 13))
            new_range.progressive_lines_max = Val(Parse$(specs_line, Any ",-", 14))
            new_range.interlaced_lines_min = Val(Parse$(specs_line, Any ",-", 15))
            new_range.interlaced_lines_max = Val(Parse$(specs_line, Any ",-", 16))
            Function = 0
        Else
            clog "Error trying to fill monitor mode with " + specs_line
            Function = -1
            Exit Function
        End If

        ' miliseconds to seconds
        new_range.v_front_porch /= 1000
        new_range.v_sync_pulse /= 1000
        new_range.v_back_porch /= 1000
        new_range.vertical_blank = new_range.v_front_porch + new_range.v_sync_pulse + new_range.v_back_porch

        If monitor_evaluate_range(new_range) Then
            clog "Error in monitor range (ignoring): " + specs_line
            Function = -1
        Else
            m_range = new_range
        End If

    Else
        clog "crt_specs line ignored: " + specs_line
        Function = -1
    End If

End Function

'============================================================
'  fill_lcd_range
'============================================================

Function fill_lcd_range(m_range As MONITOR_RANGE, ByVal specs_line As String) As Long

    If specs_line <> "auto" Then
        If ParseCount (specs_line, Any ",-") = 2 Then
            m_range.v_freq_min = Val(Parse$(specs_line, Any ",-", 1))
            m_range.v_freq_max = Val(Parse$(specs_line, Any ",-", 2))
            clog "LCD vfreq range set by user as " + Using$("#-#", m_range.v_freq_min, m_range.v_freq_max)
            Function = 1
            Exit Function
        Else
            clog "Error trying to fill LCD range with " + specs_line
        End If
    End If

    ' Use Default values
    m_range.v_freq_min = %DEFAULT_LCD_REFRESH
    m_range.v_freq_max = %DEFAULT_LCD_REFRESH
    clog "Using default vfreq range for LCD " + Using$("#-#", m_range.v_freq_min, m_range.v_freq_max)

    Function = 0
End Function

'============================================================
'  monitor_fill_vesa_range
'============================================================

Function monitor_fill_vesa_range(m_range As MONITOR_RANGE, ByVal specs_line As String) As Long

    Local vesa_mode As MODELINE
    Local lines_min, lines_max As Long

    lines_min = Val(Parse$(specs_line, 1))
    lines_max = Val(Parse$(specs_line, 2))
    If lines_min = 0 Or lines_max = 0 Then Exit Function

    vesa_mode.width = real_res(STANDARD_CRT_ASPECT * lines_max)
    vesa_mode.height = lines_max
    vesa_mode.refresh = 60
    m_range.v_freq_min = 50
    m_range.v_freq_max = 65

    modeline_vesa_gtf(vesa_mode)
    monitor_range_from_modeline(m_range, vesa_mode)

    m_range.progressive_lines_min = lines_min
    m_range.h_freq_min = vesa_mode.hfreq - 500
    m_range.h_freq_max = vesa_mode.hfreq + 500

    Function = 1
End Function

'============================================================
'  monitor_range_to_string
'============================================================

Function monitor_range_to_string(m_range As MONITOR_RANGE) Common As String

  If m_range.h_freq_min = 0 Then
    Function = "auto"

  Else
    Function = Using$( "#_-#_, #.##_-#.##_, #.###_, #.###_, #.###_, #.###_, #.###_, #.###_, #_, #_, #_, #_, #_, #",_
      m_range.h_freq_min, m_range.h_freq_max,_
      m_range.v_freq_min, m_range.v_freq_max,_
      m_range.h_front_porch, m_range.h_sync_pulse, m_range.h_back_porch,_
      m_range.v_front_porch * 1000, m_range.v_sync_pulse * 1000, m_range.v_back_porch * 1000,_
      m_range.h_sync_polarity, m_range.v_sync_polarity,_
      m_range.progressive_lines_min, m_range.progressive_lines_max,_
      m_range.interlaced_lines_min, m_range.interlaced_lines_max)
  End If

End Function

'============================================================
'  monitor_evaluate_range
'============================================================

Function monitor_evaluate_range(m_range As MONITOR_RANGE) As Long

    Local line_time, frame_time As Double

    ' First we check that all frequency ranges are reasonable
    If m_range.h_freq_min < %HFREQ_MIN Or m_range.h_freq_min > %HFREQ_MAX Then
        clog Using$("h_freq_min #.## out of range", m_range.h_freq_min)
        Function = 1 : Exit Function
    End If

    If m_range.h_freq_max < %HFREQ_MIN Or m_range.h_freq_max < m_range.h_freq_min Or m_range.h_freq_max > %HFREQ_MAX Then
        clog Using$("h_freq_max #.## out of range", m_range.h_freq_max)
        Function = 1 : Exit Function
    End If

    If m_range.v_freq_min < %VFREQ_MIN Or m_range.v_freq_min > %VFREQ_MAX Then
        clog Using$("v_freq_min #.## out of range", m_range.v_freq_min)
        Function = 1 : Exit Function
    End If

    If m_range.v_freq_max < %VFREQ_MIN Or m_range.v_freq_max < m_range.v_freq_min Or m_range.v_freq_max > %VFREQ_MAX Then
        clog Using$("v_freq_max #.## out of range", m_range.v_freq_max)
        Function = 1 : Exit Function
    End If

    ' line_time in µs. We check that no horizontal value is longer than a whole Line
    line_time = 1 / m_range.h_freq_max * 1000000

    If m_range.h_front_porch <= 0 Or m_range.h_front_porch > line_time Then
        clog Using$("h_front_porch #.## out of range", m_range.h_front_porch)
        Function = 1 : Exit Function
    End If

    If m_range.h_sync_pulse <= 0 Or m_range.h_sync_pulse > line_time Then
        clog Using$("h_sync_pulse #.## out of range", m_range.h_sync_pulse)
        Function = 1 : Exit Function
    End If

    If m_range.h_back_porch <= 0 Or m_range.h_back_porch > line_time Then
        clog Using$("h_back_porch #.## out of range", m_range.h_back_porch)
        Function = 1 : Exit Function
    End If

    ' FrameTime in ms. We check that no vertical value is longer than a whole frame
    frame_time = 1 / m_range.v_freq_max * 1000

    If m_range.v_front_porch <= 0 Or m_range.v_front_porch > frame_time Then
        clog Using$("v_front_porch #.### out of range", m_range.v_front_porch)
        Function = 1 : Exit Function
    End If

    If m_range.v_sync_pulse <= 0 Or m_range.v_sync_pulse > frame_time Then
        clog Using$("v_sync_pulse #.### out of range", m_range.v_sync_pulse)
        Function = 1 : Exit Function
    End If

    If m_range.v_back_porch <= 0 Or m_range.v_back_porch > frame_time Then
        clog Using$("v_back_porch #.### out of range", m_range.v_back_porch)
        Function = 1 : Exit Function
    End If

    ' Now we check sync polarities
    If m_range.h_sync_polarity <> 0 And m_range.h_sync_polarity <> 1 Then
        clog "Hsync polarity can be only 0 or 1"
        Function = 1 : Exit Function
    End If

    If m_range.v_sync_polarity <> 0 And m_range.v_sync_polarity <> 1 Then
        clog "Vsync polarity can be only 0 or 1"
        Function = 1 : Exit Function
    End If

    ' Finally we check that the line limiters are reasonable
    ' Progressive range:
    If m_range.progressive_lines_min > 0 And m_range.progressive_lines_min < %PROGRESSIVE_LINES_MIN Then
        clog Using$("progressive_lines_min must be greater than #", %PROGRESSIVE_LINES_MIN)
        Function = 1 : Exit Function
    End If

    If (m_range.progressive_lines_min + m_range.h_freq_max * m_range.vertical_blank) * m_range.v_freq_min > m_range.h_freq_max Then
        clog Using$("progressive_lines_min # out of range", m_range.progressive_lines_min)
        Function = 1 : Exit Function
    End If

    If m_range.progressive_lines_max < m_range.progressive_lines_min Then
        clog "progressive_lines_max must greater than progressive_lines_min"
        Function = 1 : Exit Function
    End If

    If (m_range.progressive_lines_max + m_range.h_freq_max * m_range.vertical_blank) * m_range.v_freq_min > m_range.h_freq_max Then
        clog Using$("progressive_lines_max # out of range", m_range.progressive_lines_max)
        Function = 1 : Exit Function
    End If

    ' Interlaced range:
    If m_range.interlaced_lines_min <> 0 Then

        If m_range.interlaced_lines_min < m_range.progressive_lines_max Then
            clog "interlaced_lines_min must greater than progressive_lines_max"
            Function = 1 : Exit Function
        End If

        If m_range.interlaced_lines_min < %PROGRESSIVE_LINES_MIN * 2 Then
            clog Using$("interlaced_lines_min must be greater than #", %PROGRESSIVE_LINES_MIN * 2)
            Function = 1 : Exit Function
        End If

        If (m_range.interlaced_lines_min / 2 + m_range.h_freq_max * m_range.vertical_blank) * m_range.v_freq_min > m_range.h_freq_max Then
            clog Using$("interlaced_lines_min # out of range", m_range.interlaced_lines_min)
            Function = 1 : Exit Function
        End If

        If m_range.interlaced_lines_max < m_range.interlaced_lines_min Then
            clog "interlaced_lines_max must greater than interlaced_lines_min"
            Function = 1 : Exit Function
        End If

        If (m_range.interlaced_lines_max / 2 + m_range.h_freq_max * m_range.vertical_blank) * m_range.v_freq_min > m_range.h_freq_max Then
            clog Using$("interlaced_lines_max # out of range", m_range.interlaced_lines_max)
            Function = 1 : Exit Function
        End If

    Else
        If m_range.interlaced_lines_max <> 0 Then
            clog("interlaced_lines_max must be zero if interlaced_lines_min is not defined")
            Function = 1 : Exit Function
        End If
    End If

    Function = 0
End Function

'============================================================
'  monitor_range_from_modeline
'============================================================

Function monitor_range_from_modeline(m_range As MONITOR_RANGE, m As MODELINE) As Long

    Local line_time, pixel_time As Double

    ' This routine assumes v_freq_min-v_freq_max are defined
    line_time = 1 / m.hfreq
    pixel_time = line_time / m.htotal * 1000000

    m_range.h_front_porch = pixel_time * (m.hbegin - m.hactive)
    m_range.h_sync_pulse = pixel_time * (m.hend - m.hbegin)
    m_range.h_back_porch = pixel_time * (m.htotal - m.hend)

    m_range.v_front_porch = line_time * (m.vbegin - m.vactive)
    m_range.v_sync_pulse = line_time * (m.vend - m.vbegin)
    m_range.v_back_porch = line_time * (m.vtotal - m.vend)
    m_range.vertical_blank = m_range.v_front_porch + m_range.v_sync_pulse + m_range.v_back_porch

    m_range.h_sync_polarity = m.hsync
    m_range.v_sync_polarity = m.vsync

    m_range.progressive_lines_min = m.vactive
    m_range.progressive_lines_max = m.vactive
    m_range.interlaced_lines_min = 0
    m_range.interlaced_lines_max= 0

    m_range.h_freq_min = m_range.v_freq_min * m.vtotal
    m_range.h_freq_max = m_range.v_freq_max * m.vtotal

    Function = 1
End Function

'============================================================
'  real_res
'============================================================

Function real_res(x As Long) As Long
    Function = Int (x / 8) * 8
End Function

'============================================================
'  monitor_orientation
'============================================================

Function monitor_orientation(index As Long) Common As String
  Function = Read$(index + 1)
  Data  "horizontal", "vertical", "rotate_r", "rotate_l"
End Function

'============================================================
'  monitor_get_rotation
'============================================================

Function monitor_get_rotation(ByVal orientation_opt As String) Common As Long
  Select Case As Const$ orientation_opt
    Case "horizontal"
      Function = %M_HORIZONTAL
    Case "vertical"
      Function = %M_VERTICAL
    Case "rotate_r"
      Function = %M_ROTATING_R
    Case "rotate_l"
      Function = %M_ROTATING_L
  End Select
End Function
