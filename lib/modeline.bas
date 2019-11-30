'==============================================================================
'
'  Modeline library
'  modeline.bas
'  Copyright (c) 2008-2014 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "monitor.inc"
#Include "modeline.inc"
#Include "util.inc"

Declare Function clog(t As String) Common As Long

'============================================================
'  Globals
'============================================================

Global dotclock_table() As Long

'============================================================
'  get_modeline
'============================================================

Function get_modeline(xres As Long, yres As Long, vfreq As Double, ByVal m As MONITOR_DEF Ptr, options As MODELINE_OPTIONS, t_mode As modeline) Common As Long

  Local i As Long
  Local s_mode, dummy_mode, best_mode As modeline

    s_mode.width = xres
    s_mode.height = yres
    s_mode.refresh = vfreq
    s_mode.hactive = xres
    s_mode.vactive = yres
    s_mode.vfreq = vfreq

    If (t_mode.type And %X_RES_EDITABLE) And (t_mode.type And %Y_RES_EDITABLE) And (t_mode.type And %V_FREQ_EDITABLE) Then
      dummy_mode.width = IIf(xres = %DUMMY_WIDTH, %DUMMY_WIDTH, 1)
      dummy_mode.height = 1
      dummy_mode.refresh = 60
      dummy_mode.hactive = IIf(xres = %DUMMY_WIDTH, %DUMMY_WIDTH, 1)
      dummy_mode.vactive = 1
      dummy_mode.vfreq = 60
      dummy_mode.type Or= IIf(xres = %DUMMY_WIDTH, 0 , %X_RES_EDITABLE) Or %Y_RES_EDITABLE Or %V_FREQ_EDITABLE Or IIf((t_mode.type And %MODE_ROTATED), %MODE_ROTATED, 0)
    Else
      dummy_mode = t_mode
    End If

    best_mode.result.weight Or= %R_OUT_OF_RANGE
    options.monitor_aspect = @m.m_aspect_ratio

    While @m.m_range(i).progressive_lines_min And i < %MAX_RANGES
      t_mode = dummy_mode
      modeline_create(s_mode, t_mode, @m.m_range(i), options)
      t_mode.range = i
      'clog modeline_result(t_mode)
      If modeline_compare(t_mode, best_mode) Then
          best_mode = t_mode
      End If
      Incr i
    Wend

    t_mode = best_mode
    t_mode.width = t_mode.hactive
    t_mode.height = t_mode.vactive
    t_mode.refresh = Round(t_mode.vfreq, 0)
End Function

'============================================================
'  modeline_create
'============================================================

Function modeline_create(s_mode As modeline, t_mode As modeline, m_range As MONITOR_RANGE, options As MODELINE_OPTIONS) Common As Long

    Local vfreq, vfreq_real As Double
    Local interlace, doublescan, scan_factor As Double
    Local xres, yres As Long
    Local x_scale, y_scale, v_scale As Long
    Local x_diff, y_diff, v_diff, y_ratio, x_ratio As Double

    interlace = 1
    doublescan = 1
    scan_factor = 1
    Reset t_mode.result

    ' init all editable fields with source video mode values
    If (t_mode.type And %X_RES_EDITABLE) Then
        xres = s_mode.hactive
    Else
        xres = t_mode.hactive
    End If
    If (t_mode.type And %Y_RES_EDITABLE) Then
        yres = s_mode.vactive
    Else
        yres = t_mode.vactive
    End If
    If (t_mode.type And %V_FREQ_EDITABLE) Then
        vfreq = s_mode.vfreq
    Else
        vfreq = t_mode.vfreq
    End If

    ' ··· Vertical refresh ···
    ' try to fit vertical frequency into current range
    v_scale = scale_into_range_float(vfreq, m_range.v_freq_min, m_range.v_freq_max)

    If IsFalse v_scale And (t_mode.type And %V_FREQ_EDITABLE) Then
        vfreq = IIf(vfreq < m_range.v_freq_min, m_range.v_freq_min, m_range.v_freq_max)
        v_scale = 1

    ElseIf v_scale <> 1 And IsFalse(t_mode.type And %V_FREQ_EDITABLE) Then
        t_mode.result.weight Or= %R_OUT_OF_RANGE
        Function = -1 : Exit Function
    End If

    ' ··· Vertical resolution ···
    ' try to fit active lines in the progressive range first
    If m_range.progressive_lines_min And ((IsFalse t_mode.interlace) Or (t_mode.type And %V_FREQ_EDITABLE)) Then
        y_scale = scale_into_range_int(yres, m_range.progressive_lines_min, m_range.progressive_lines_max)
    End If

    ' if not possible, try to fit in the interlaced range, if any
    If (IsFalse y_scale) And m_range.interlaced_lines_min And options.interlace And (t_mode.interlace Or (t_mode.type And %V_FREQ_EDITABLE)) Then
        y_scale = scale_into_range_int(yres, m_range.interlaced_lines_min, m_range.interlaced_lines_max)
        interlace = 2
    End If

    ' check if we should apply doublescan
    If (t_mode.type And %V_FREQ_EDITABLE) And (options.doublescan And y_scale Mod 2 = 0) Then
        y_scale /= 2
        doublescan = 0.5
    End If
    scan_factor = interlace * doublescan

    ' if we succeeded, let's see if we can apply integer scaling
    If y_scale = 1 Or (y_scale > 1 And (t_mode.type And %Y_RES_EDITABLE)) Then

        ' calculate expected achievable refresh for this height
        vfreq_real = Min(vfreq * v_scale, max_vfreq_for_yres(yres * y_scale, m_range, scan_factor))
        If vfreq_real <> vfreq * v_scale And IsFalse(t_mode.type And %V_FREQ_EDITABLE) Then
            t_mode.result.weight Or= %R_OUT_OF_RANGE
            Function = -1 : Exit Function
        End If

        ' calculate the ratio that our scaled yres represents with respect to the original height
        Local y_source_scaled As Long
        y_ratio = yres * y_scale / s_mode.vactive
        y_source_scaled = s_mode.vactive * Int(y_ratio)

        ' if our original height doesn't fit the target height, we're forced to stretch
        If IsFalse y_source_scaled Then
            t_mode.result.weight Or= %R_RES_STRETCH

        ' otherwise we try to perform integer scaling
        Else
            ' calculate y borders considering physical lines (instead of logical resolution)
            Local tot_yres, tot_source As Long
            tot_yres = total_lines_for_yres(yres * y_scale, vfreq_real, m_range, scan_factor)
            tot_source = total_lines_for_yres(y_source_scaled, vfreq * v_scale, m_range, scan_factor)
            y_diff = IIf(tot_yres > tot_source, (tot_yres Mod tot_source) / tot_yres * 100, 0)

            ' we penalize for the logical lines we need to add in order to meet the user's lower active lines limit
            Local y_min, tot_rest As Long
            y_min = IIf(interlace = 2, m_range.interlaced_lines_min, m_range.progressive_lines_min)
            tot_rest = IIf(y_min >= y_source_scaled / doublescan, y_min Mod (y_source_scaled / doublescan), 0)
            y_diff += tot_rest / tot_yres * 100

            ' we save the integer ratio between source and target resolutions, this will be used for prescaling
            y_scale = Int(y_ratio)

            ' now if the borders obtained are low enough (< 10%) we'll finally apply integer scaling
            ' otherwise we'll stretch the original resolution over the target one
            If IsFalse (y_ratio >= 1.0 And y_ratio < 16.0 And y_diff < 10.0) Then
                t_mode.result.weight Or= %R_RES_STRETCH
            End If
        End If

    ' otherwise, check if we're allowed to apply fractional scaling
    ElseIf (t_mode.type And %Y_RES_EDITABLE) Then
        t_mode.result.weight Or= %R_RES_STRETCH

    ' if there's nothing we can do, we're out of range
    Else
        t_mode.result.weight Or= %R_OUT_OF_RANGE
        Function = -1 : Exit Function
    End If

    ' ··· Horizontal resolution ···
    ' make the best possible adjustment of xres depending on what happened in the previous steps
    ' let's start with the SCALED case
    If IsFalse(t_mode.result.weight And %R_RES_STRETCH) Then
        ' if we can, let's apply the same scaling to both directions
        If (t_mode.type And %X_RES_EDITABLE) Then
            If (t_mode.type And %Y_RES_EDITABLE) Then yres *= y_scale
                x_scale = y_scale
                xres = norm(xres * x_scale * IIf((t_mode.type And %MODE_ROTATED), STANDARD_CRT_ASPECT, 1.0/STANDARD_CRT_ASPECT) * options.monitor_aspect, 8)

        ' otherwise, try to get the best out of our current xres
        Else
            x_scale = Int(xres / s_mode.hactive)
            ' if the source width fits our xres, try applying integer scaling
            If x_scale Then
                x_scale = scale_into_aspect(s_mode.hactive, xres, IIf((t_mode.type And %MODE_ROTATED), 1.0/STANDARD_CRT_ASPECT, STANDARD_CRT_ASPECT), options.monitor_aspect, x_diff)
                If x_diff > 15.0 Then
                        t_mode.result.weight Or= %R_RES_STRETCH
                End If

            ' otherwise apply fractional scaling
            Else
                t_mode.result.weight Or= %R_RES_STRETCH
            End If
        End If
    End If

    ' if the resulted was fractional scaling in any of the previous steps, deal with it
    If (t_mode.result.weight And %R_RES_STRETCH) Then
        If (t_mode.type And %Y_RES_EDITABLE) Then
            ' always try to use the interlaced range first if it exists, for better resolution
            yres = stretch_into_range(vfreq, m_range, options.interlace, interlace)

            ' check in case we couldn't achieve the desired refresh
            vfreq_real = Min(vfreq, max_vfreq_for_yres(yres, m_range, interlace))
        End If

        ' check if we can create a normal aspect resolution
        If (t_mode.type And %X_RES_EDITABLE) Then
            xres = Max(xres, norm(STANDARD_CRT_ASPECT * yres, 8))
        End If

        ' calculate integer scale for prescaling
        x_scale = Max(1, Int(xres / s_mode.hactive))
        y_scale = Max(1, Int(yres / s_mode.vactive))

        scan_factor = interlace
        doublescan = 1
    End If

    x_ratio = xres / s_mode.hactive
    y_ratio = yres / s_mode.vactive
    v_scale = Max(Int(vfreq_real / s_mode.vfreq), 1)
    v_diff = (vfreq_real / v_scale) -  s_mode.vfreq
    If Abs(v_diff) > options.sync_refresh_tolerance Then
        t_mode.result.weight Or= %R_V_FREQ_OFF
    End If

    ' --------------------------
    ' Modeline calculation

    Local v_margin, v_blank_lines, vvt_ini As Double

    ' Get games basic resolution
    t_mode.hactive = xres
    t_mode.vactive = yres
    t_mode.vfreq = vfreq_real

    ' Get total vertical lines
    vvt_ini = total_lines_for_yres(t_mode.vactive, t_mode.vfreq, m_range, scan_factor) + IIf(interlace = 2, 0.5, 0)

    ' Calculate horizontal frequency
    t_mode.hfreq = t_mode.vfreq * vvt_ini

    horizontal_values:

    ' Fill horizontal part of modeline
    modeline_get_line_params(t_mode, m_range)

    ' Calculate pixel clock
    t_mode.pclock = t_mode.htotal * t_mode.hfreq
    If t_mode.pclock <= options.pclock_min Then
        If (t_mode.type And %X_RES_EDITABLE) Then
            x_scale *= 2
            t_mode.hactive *= 2
            GoTo horizontal_values

        Else
            t_mode.result.weight Or= %R_OUT_OF_RANGE
            Function = -1 : Exit Function
        End If
    End If

    ' Vertical blanking
    t_mode.vtotal = vvt_ini * scan_factor
    v_blank_lines = Int(t_mode.hfreq * m_range.vertical_blank) + IIf(interlace = 2, 0.5, 0)
    v_margin = (t_mode.vtotal - t_mode.vactive - v_blank_lines * scan_factor) / 2
    t_mode.vbegin = t_mode.vactive + Max(Round(t_mode.hfreq * m_range.v_front_porch * scan_factor + v_margin, 0), 1)
    t_mode.vend = t_mode.vbegin + Max(Round(t_mode.hfreq * m_range.v_sync_pulse * scan_factor, 0), 1)

    ' Recalculate final vfreq
    t_mode.vfreq = (t_mode.hfreq / t_mode.vtotal) * scan_factor

    t_mode.hsync = m_range.h_sync_polarity
    t_mode.vsync = m_range.v_sync_polarity
    t_mode.interlace = IIf(interlace = 2, 1, 0)
    t_mode.doublescan = IIf(doublescan = 1, 0, 1)
    t_mode.result.x_scale = x_scale
    t_mode.result.y_scale = y_scale
    t_mode.result.v_scale = v_scale
    t_mode.result.x_diff = x_diff
    t_mode.result.y_diff = y_diff
    t_mode.result.v_diff = v_diff
    t_mode.result.x_ratio = x_ratio
    t_mode.result.y_ratio = y_ratio
    t_mode.result.v_ratio = 0
    t_mode.result.rotated = (t_mode.type And %MODE_ROTATED)

    Function = 0
End Function

'============================================================
'  modeline_get_line_params
'============================================================

Function modeline_get_line_params(t_mode As modeline, m_range As MONITOR_RANGE) As Long

    Local hhi, hhe, hht As Long
    Local hh, hs, he, ht As Long
    Local line_time, char_time, new_char_time As Double
    Local h_front_porch_min, h_sync_pulse_min, h_back_porch_min As Double

    h_front_porch_min = m_range.h_front_porch * .90
    h_sync_pulse_min  = m_range.h_sync_pulse  * .90
    h_back_porch_min  = m_range.h_back_porch  * .90

    line_time = 1 / t_mode.hfreq * 1000000

    hh = Round(t_mode.hactive / 8, 0)
    hs = he = ht = 1

    Do
        char_time = line_time / (hh + hs + he + ht)
        If hs * char_time < h_front_porch_min Or _
            Abs((hs + 1) * char_time - m_range.h_front_porch) < Abs(hs * char_time - m_range.h_front_porch) Then
            hs += 1
        End If

        If he * char_time < h_sync_pulse_min Or _
            Abs((he + 1) * char_time - m_range.h_sync_pulse) < Abs(he * char_time - m_range.h_sync_pulse) Then
            he += 1
        End If

        If ht * char_time < h_back_porch_min Or _
            Abs((ht + 1) * char_time - m_range.h_back_porch) < Abs(ht * char_time - m_range.h_back_porch) Then
            ht += 1
        End If

        new_char_time = line_time / (hh + hs + he + ht)
    Loop While new_char_time <> char_time

    hhi = (hh + hs) * 8
    hhe = (hh + hs + he) * 8
    hht = (hh + hs + he + ht) * 8

    t_mode.hbegin  = hhi
    t_mode.hend    = hhe
    t_mode.htotal  = hht

    Function = 0
End Function

'============================================================
'  scale_into_range_int
'============================================================

Function scale_into_range_int (value As Long, lower_limit As Long, higher_limit As Long) As Long

    Local i_scale As Long
    i_scale = 1

    While value * i_scale < lower_limit
        i_scale += 1
    Wend
    If value * i_scale <= higher_limit Then
        Function = i_scale
    Else
        Function = 0
    End If

End Function

'============================================================
'  scale_into_range_float
'============================================================

Function scale_into_range_float (value As Double, lower_limit As Double, higher_limit As Double) As Long

    Local f_scale As Long
    f_scale = 1

    While value * f_scale < lower_limit
        f_scale += 1
    Wend
    If value * f_scale <= higher_limit Then
        Function = f_scale
    Else
        Function = 0
    End If

End Function

'============================================================
'  scale_into_aspect
'============================================================

Function scale_into_aspect (source_res As Long, tot_res As Long, original_monitor_aspect As Double, users_monitor_aspect As Double, best_diff As Double) As Long

    Local f_scale, best_scale As Long
    Local diff As Double

    f_scale = 1
    best_scale = 1

    While source_res * f_scale <= tot_res
        diff = Abs(1.0 - (users_monitor_aspect / (tot_res / (source_res * f_scale) * original_monitor_aspect))) * 100
        If diff < best_diff Or best_diff = 0 Then
            best_diff = diff
            best_scale = f_scale
        End If
        f_scale += 1
    Wend

    Function = best_scale
End Function

'============================================================
'  stretch_into_range
'============================================================

Function stretch_into_range(vfreq As Double, m_range As MONITOR_RANGE, interlace_allowed As Long, interlace As Double) As Long

    Local yres, lower_limit As Long

    If m_range.interlaced_lines_min And interlace_allowed Then
        yres = m_range.interlaced_lines_max
        lower_limit = m_range.interlaced_lines_min
        interlace = 2
    Else
        yres = m_range.progressive_lines_max
        lower_limit = m_range.progressive_lines_min
    End If

    While yres > lower_limit And max_vfreq_for_yres(yres, m_range, interlace) < vfreq
        yres -= 8
    Wend

    Function = yres
End Function

'============================================================
'  total_lines_for_yres
'============================================================

Function total_lines_for_yres(yres As Long, vfreq As Double, m_range As MONITOR_RANGE, interlace As Double) As Long

    Local vvt As Long

    vvt = Max(yres / interlace + Round(vfreq * yres / (interlace * (1.0 - vfreq * m_range.vertical_blank)) * m_range.vertical_blank, 0), 1)
    While (vfreq * vvt < m_range.h_freq_min) And (vfreq * (vvt + 1) < m_range.h_freq_max)
        vvt += 1
    Wend

    Function = vvt
End Function

'============================================================
'  max_vfreq_for_yres
'============================================================

Function max_vfreq_for_yres (yres As Long, m_range As monitor_range, interlace As Double) As Double

    Function = m_range.h_freq_max / (yres / interlace + Round(m_range.h_freq_max * m_range.vertical_blank, 0))
End Function

'============================================================
'  modeline_print
'============================================================

Function modeline_print(t_mode As modeline, flags As Long) Common As String

    Local m_label As String
    Local m_params As String

    If (flags And %MS_LABEL) Then
        m_label = Using$("""#x#__# #.##KHz #.##Hz""", t_mode.width, t_mode.height, t_mode.refresh, t_mode.hfreq/1000, t_mode.vfreq)
    End If

    If (flags And %MS_LABEL_SDL) Then
        m_label = Using$ ("""#x#_#.##""", t_mode.hactive, t_mode.vactive, t_mode.vfreq)
    End If

    If (flags And %MS_PARAMS) Then
        m_params = Using$ (" #.## # # # # # # # # ", t_mode.pclock/1000000.0, t_mode.hactive, t_mode.hbegin, t_mode.hend, t_mode.htotal, t_mode.vactive, t_mode.vbegin, t_mode.vend, t_mode.vtotal) + _
                   IIf$(t_mode.interlace, "interlace ", "") + IIf$(t_mode.doublescan, "doublescan ", "") + IIf$(t_mode.hsync, "+hsync ", "-hsync ") + IIf$(t_mode.vsync, "+vsync ", "-vsync")
    End If

    Function = m_label + m_params
End Function

'============================================================
'  modeline_result
'============================================================

Function modeline_result(t_mode As modeline) Common As String

    Local result As String

    If (t_mode.result.weight And %R_OUT_OF_RANGE) Then
        result = " out of range"

    Else
        result = Using$("#### x####__##.###", t_mode.hactive, t_mode.vactive, t_mode.vfreq) + IIf$(t_mode.interlace, "i", "p") + IIf$(t_mode.doublescan, "d", "") + _
                 Using$(" ###.### ", t_mode.hfreq/1000) +  IIf$((t_mode.result.weight And %R_RES_STRETCH), "[fract]", "[integ]") + _
                 Using$(" scale(#_, #_, #) diff(#.##_, #.##_, #.####) ratio(#.###_, #.###)", t_mode.result.x_scale, t_mode.result.y_scale, t_mode.result.v_scale, _
                 t_mode.result.x_diff, t_mode.result.y_diff, t_mode.result.v_diff, t_mode.result.x_ratio, t_mode.result.y_ratio)
    End If

    result = Using$("   rng(#): ", t_mode.range) + result

    Function = result
End Function

'============================================================
'  modeline_compare
'============================================================

Function modeline_compare(t As modeline, best As modeline) Common As Long

    Local vector As Long
    Local t_v_diff, b_v_diff, t_y_score, b_y_score As Double
    Local xy_diff, best_xy_diff As Double

    vector = (t.hactive = Int(t.result.x_ratio))

    If t.result.weight < best.result.weight Then
        Function = 1 : Exit Function

    ElseIf t.result.weight <= best.result.weight Then

        t_v_diff = Abs(t.result.v_diff)
        b_v_diff = Abs(best.result.v_diff)

        If (t.result.weight And %R_RES_STRETCH) Or vector Then

            t_y_score = t.result.y_ratio * IIf(t.interlace, 2.0/3.0, 1.0)
            b_y_score = best.result.y_ratio * IIf(best.interlace, 2.0/3.0 ,1.0)

            If  t_v_diff <  b_v_diff Or _
                (t_v_diff = b_v_diff And t_y_score > b_y_score) Or _
                (t_v_diff = b_v_diff And t_y_score = b_y_score And t.result.x_ratio > best.result.x_ratio) Then
                    Function = 1 : Exit Function
            End If

        Else
            t_y_score = t.result.y_scale + t.interlace + t.doublescan
            b_y_score = best.result.y_scale + best.interlace + best.doublescan
            xy_diff = t.result.x_diff + t.result.y_diff
            best_xy_diff = best.result.x_diff + best.result.y_diff

            If  t_y_score < b_y_score Or _
                (t_y_score = b_y_score And xy_diff < best_xy_diff) Or _
                (t_y_score = b_y_score And xy_diff = best_xy_diff And t.result.x_scale < best.result.x_scale) Or _
                (t_y_score = b_y_score And xy_diff = best_xy_diff And t.result.x_scale = best.result.x_scale And t_v_diff < b_v_diff) Then
                    Function = 1 : Exit Function
            End If
        End If

    End If

    Function = 0
End Function

'============================================================
'  modeline_vesa_gtf
'  Based on the VESA GTF spreadsheet by Andy Morrish 1/5/97
'============================================================

Function modeline_vesa_gtf(vm As modeline) Common As Long

    Local C, M As Long
    Local v_sync_lines, v_porch_lines_min, v_front_porch_lines, v_back_porch_lines, v_sync_v_back_porch_lines, v_total_lines As Long
    Local h_sync_width_percent, h_sync_width_pixels, h_blanking_pixels, h_front_porch_pixels, h_total_pixels As Long
    Local v_freq, v_freq_est, v_freq_real, v_sync_v_back_porch As Double
    Local h_freq, h_period, h_period_real, h_ideal_blanking As Double
    Local pixel_freq, interlace As Double

    ' Check if there's a value defined for vfreq. We're assuming input vfreq is the total field vfreq regardless interlace
    v_freq = IIf(vm.vfreq, vm.vfreq, vm.refresh)

    ' These values are GTF defined defaults
    v_sync_lines = 3
    v_porch_lines_min = 1
    v_front_porch_lines = v_porch_lines_min
    v_sync_v_back_porch = 550
    h_sync_width_percent = 8
    M = 128.0 / 256 * 600
    C = ((40 - 20) * 128.0 / 256) + 20

    ' GTF calculation
    interlace = IIf(vm.interlace, 0.5, 0)
    h_period = ((1.0 / v_freq) - (v_sync_v_back_porch / 1000000)) / (vm.height + v_front_porch_lines + interlace) * 1000000
    v_sync_v_back_porch_lines = Round(v_sync_v_back_porch / h_period, 0)
    v_back_porch_lines = v_sync_v_back_porch_lines - v_sync_lines
    v_total_lines = vm.height + v_front_porch_lines + v_sync_lines + v_back_porch_lines
    v_freq_est = (1.0 / h_period) / v_total_lines * 1000000
    h_period_real = h_period / (v_freq / v_freq_est)
    v_freq_real = (1.0 / h_period_real) / v_total_lines * 1000000
    h_ideal_blanking = C - (M * h_period_real / 1000)
    h_blanking_pixels = Round(vm.width * h_ideal_blanking /(100 - h_ideal_blanking) / (2 * 8), 0) * (2 * 8)
    h_total_pixels = vm.width + h_blanking_pixels
    pixel_freq = h_total_pixels / h_period_real * 1000000
    h_freq = 1000000 / h_period_real
    h_sync_width_pixels = Round(h_sync_width_percent * h_total_pixels / 100 / 8, 0) * 8
    h_front_porch_pixels = (h_blanking_pixels / 2) - h_sync_width_pixels

    ' Results
    vm.hactive = vm.width
    vm.hbegin = vm.hactive + h_front_porch_pixels
    vm.hend = vm.hbegin + h_sync_width_pixels
    vm.htotal = h_total_pixels
    vm.vactive = vm.height
    vm.vbegin = vm.vactive + v_front_porch_lines
    vm.vend = vm.vbegin + v_sync_lines
    vm.vtotal = v_total_lines
    vm.hfreq = h_freq
    vm.vfreq = v_freq_real
    vm.pclock = pixel_freq
    vm.hsync = 0
    vm.vsync = 1

    Function = 1
End Function

'============================================================
'  modeline_info
'============================================================

Function modeline_info (m As modeline, dotclock_table() As Long) Common As String

  Local hh, hs, he, ht As Long
  Local vfreq, hfreq, dotclock, dotclock_real, char_time, line_time, interlace As Single
  Local a, format As String

  dotclock_real = dotclock_table(m.pclock / 10000)
  dotclock = m.pclock
  interlace = IIf(m.interlace, 2, 1)
  hfreq = dotclock_real / m.htotal
  vfreq = hfreq / m.vtotal * interlace
  line_time = 1 / hfreq * 1000000
  char_time = line_time * 8 / m.htotal

  hh = m.hactive / 8
  hs = (m.hbegin - m.hactive) / 8
  he = (m.hend - m.hbegin) / 8
  ht = (m.htotal - m.hactive) / 8

  a = modeline_print(m, %MS_FULL)
  format = $Tab + "##.## ###" + $Tab + "#####.## ###"
  a = a + $CrLf + $CrLf + Using$ ( "Vfreq = ##.###### Hz", vfreq ) + $CrLf
  a = a + Using$ ( "Hfreq = ##,###.## kHz", hfreq ) + $CrLf
  a = a + Using$ ( "DotClock = #,", dotclock_real ) + $CrLf + $CrLf
  a = a + String$ ( 16, " " ) + "(h)" + Chr$ ( 181 ) + "s  ch" + String$ ( 10, " " ) + "(v)"+ Chr$ ( 181 ) + "s  ln" + $CrLf
  a = a + String$ ( 44, "-" ) + $CrLf
  a = a + Using$ ( "Total video" + format, (hh + ht) * char_time, hh + ht, m.vtotal * line_time / interlace, m.vtotal) + $CrLf
  a = a + Using$ ( "Active video" + format, hh * char_time, hh, m.vactive * line_time / interlace, m.vactive) + $CrLf
  a = a + Using$ ( "Front porch" + format, hs * char_time, hs, (m.vbegin - m.vactive) * line_time / interlace, m.vbegin - m.vactive) + $CrLf
  a = a + Using$ ( "Sync pulse" + format, he * char_time, he, (m.vend - m.vbegin) * line_time / interlace, m.vend - m.vbegin) + $CrLf
  a = a + Using$ ( "Back porch" + format, (ht - he - hs) * char_time, ht - he - hs, (m.vtotal - m.vend) * line_time, m.vtotal - m.vend) + $CrLf
  a = a + Using$ ( "Total blanking" + format, ht * char_time, ht, (m.vtotal - m.vactive) * line_time / interlace, m.vtotal - m.vactive) + $CrLf
  a = a + String$ ( 92, "_" )

  Function = a
End Function

'============================================================
'  modeline_get_default_options
'============================================================

Function modeline_get_default_options(options As MODELINE_OPTIONS) Common As Long

  options.interlace = 1
  options.doublescan = 0
  options.effective_orientation = 0
  options.monitor_aspect = STANDARD_CRT_ASPECT
  options.sync_refresh_tolerance = 2.0
  options.pclock_min = 0
  options.s_pclock_min = "auto"

End Function

'============================================================
'  modeline_get_dotclock_table
'============================================================

Function modeline_get_dotclock_table(dotclock_file As String) Common As Long

  Dim dotclock_table(%DOTCLOCK_MAX) As Global Long
  Local i, file_num, dotclock_10khz, dotclock_hz As Long

  For i = 0 To %DOTCLOCK_MAX
    dotclock_table(i) = i * 10000
  Next

  file_num = FreeFile
  Open dotclock_file For Input As file_num

  While Not Eof(file_num)
    Input #file_num, dotclock_10khz, dotclock_hz
    dotclock_table(dotclock_10khz) = dotclock_hz
  Wend

  Function = 1
End Function

'============================================================
'  modeline_dotclock
'============================================================

Function modeline_dotclock(m As MODELINE) Common As Long
 Function = IIf(m.pclock <= %DOTCLOCK_MAX And dotclock_table(m.pclock / 10000), dotclock_table(m.pclock / 10000), m.pclock)
End Function

'============================================================
'  modeline_reclock
'============================================================

Function modeline_reclock(p As MODELINE, c As MODELINE) Common As Long

  Local vfreq As Single
  If p.htotal And c.htotal Then
    vfreq = modeline_dotclock(p) / (p.htotal * p.vtotal) * IIf(p.interlace, 2, 1)
    c.pclock = vfreq * c.htotal * c.vtotal / IIf(c.interlace, 2, 1)
    Function = 1
  End If
End Function

'============================================================
'  modeline_compute_frequency
'============================================================

Function modeline_compute_frequency(m As MODELINE) Common As Long
  If m.htotal Then
    m.hfreq = modeline_dotclock(m) / m.htotal
    m.vfreq = m.hfreq / m.vtotal * IIf(m.interlace, 2, 1)
    Function = 1
  End If
End Function

'============================================================
'  modeline_parse
'============================================================

Function modeline_parse(m As String, v As MODELINE) Common As Long

  If Tally(m, $Dq) <> 2 Then Exit Function

  Local quote_pos1, quote_pos2, flags_pos As Long
  quote_pos1 = InStr(m, $Dq)
  quote_pos2 = InStr(quote_pos1 + 1, m, $Dq)
  flags_pos = InStr(-1, m, Any "0123456789")

  Local quoted_part, timing_part, flags_part As String
  quoted_part = Trim$(Mid$(m, quote_pos1 + 1, quote_pos2 - quote_pos1 - 1))
  timing_part = Trim$(Mid$(m, quote_pos2 + 1, flags_pos - quote_pos2))
  flags_part = Trim$(Right$(m, Len(m) - flags_pos))
  If quoted_part = "" Or timing_part = "" Then Exit Function

  v.bpp = 32
  v.width = Val(Parse$(quoted_part, Any "xX_@", 1))
  v.height = Val(Parse$(quoted_part, Any "xX_@", 2))
  v.refresh = Val(Parse$(quoted_part, Any "xX_@", 3))
  If v.width = 0 Or v.height = 0 Or v.refresh = 0 Then Exit Function

  v.pclock = Val(Parse$(timing_part, " ", 1)) * 1000000 ' MHz -> Hz
  If v.pclock = 0 Then Exit Function

  v.hactive = Val(Parse$(timing_part, " ", 2))
  v.hbegin = Val(Parse$(timing_part, " ", 3))
  v.hend = Val(Parse$(timing_part, " ", 4))
  v.htotal = Val(Parse$(timing_part, " ", 5))
  If v.hactive = 0 Or v.hbegin = 0 Or v.hend = 0 Or v.htotal = 0 Then Exit Function

  v.vactive = Val(Parse$(timing_part, " ", 6))
  v.vbegin = Val(Parse$(timing_part, " ", 7))
  v.vend = Val(Parse$(timing_part, " ", 8))
  v.vtotal = Val(Parse$(timing_part, " ", 9))
  If v.vactive = 0 Or v.vbegin = 0 Or v.vend = 0 Or v.vtotal = 0 Then Exit Function

  v.interlace = IIf(InStr(flags_part, "interlace"), 1, 0)
  v.hsync = IIf(InStr(flags_part, "+hsync"), 1, 0)
  v.vsync = IIf(InStr(flags_part, "+vsync"), 1, 0)

  modeline_compute_frequency(v)
  Function = 1
End Function

'============================================================
'  modeline_to_monitor_range
'============================================================

Function modeline_to_monitor_range(v As MODELINE) Common As String

  Local crt_range As String

  Local line_time, pixel_time As Double
  line_time = 1 / v.hfreq * 1000
  pixel_time = line_time / v.htotal * 1000

  Local hfreq_min, hfreq_max As Double
  hfreq_min = v.hfreq - 10
  hfreq_max = v.hfreq + 10

  Local interlace As Long
  interlace = IIf(v.interlace, 2, 1)

  crt_range = Using$("#.##_-#.##, #.##_-#.##, ", hfreq_min, hfreq_max, 50, v.refresh) +_
              Using$("#.###, #.###, #.###, ", pixel_time * (v.hbegin - v.hactive), pixel_time * (v.hend - v.hbegin), pixel_time * (v.htotal - v.hend)) +_
              Using$("#.###, #.###, #.###, ", line_time * (v.vbegin - v.vactive), line_time * (v.vend - v.vbegin), line_time * (v.vtotal - v.vend)) +_
              Using$("#_, #_, ", v.hsync, v.vsync) +_
              Using$("#_, #_, ", v.vactive / interlace, (hfreq_max / 50 - (v.vtotal - v.vactive)) / interlace) +_
              Using$("#_, #", v.vactive / interlace * 2, (hfreq_max / 50 - (v.vtotal - v.vactive)) / interlace * 2)

  Function = crt_range
End Function

'============================================================
'  modeline_from_clipboard
'============================================================

Function modeline_from_clipboard(v As MODELINE) Common As Long
  Local m As String
  Clipboard Get Text m
  If modeline_parse(m, v) Then modeline_compute_frequency(v) : Function = 1
End Function

'============================================================
'  modeline_to_clipboard
'============================================================

Function modeline_to_clipboard(v As MODELINE) Common As Long

  Clipboard Set Text "modeline " + modeline_print(v, %MS_FULL) + $CrLf + "crt_range " + modeline_to_monitor_range(v)
End Function
