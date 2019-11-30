#Compile SLL
#Dim All

#Include "VMMaker.inc"

'============================================================
'  timing_chart_from_monitor_range
'============================================================

Function timing_chart_from_monitor_range(m As MONITOR_RANGE) Common As Long

  Local h_total, h_active As Double
  Local v_total, v_active As Double

  h_total = 1 / m.h_freq_min * 1000000
  h_active = h_total - m.h_front_porch - m.h_sync_pulse - m.h_back_porch

  v_total = 1 / m.v_freq_min
  v_active = v_total - m.v_front_porch - m.v_sync_pulse - m.v_back_porch

  Graphic Clear RGB(0, 0, 0)
  'Graphic Set Font hFont

  ' Print caption
  Graphic Color %Green, %Black
  Graphic Set Pos (2, 2)
  Graphic Print "T I M I N G    C H A R T"

  draw_signal (Using$ ("Horizontal #.### kHz - values in µs", m.h_freq_min / 1000), 2, 60, h_total, m.h_sync_pulse, m.h_back_porch, h_active, m.h_front_porch, 1, %rgb_Lime)
  draw_signal (Using$ ("Vertical #.### Hz - values in ms", m.v_freq_min), 308, 60, v_total, m.v_sync_pulse, m.v_back_porch, v_active, m.v_front_porch, 1000, %rgb_Lime)

End Function

'============================================================
'  video_mode_draw_timing_chart
'============================================================

Function video_mode_draw_timing_chart (m As modeline) Common As Long

  Local line_time, pixel_time As Double
  Local h_freq, v_freq As Double

  h_freq = m.pclock / m.htotal ' Hz
  v_freq = h_freq / m.vtotal * IIf(m.interlace, 2, 1)
  line_time = 1 / (m.pclock / m.htotal) * 1000 ' ms
  pixel_time = line_time / m.htotal * 1000 ' µs

  Graphic Clear RGB(0, 0, 0)
  'Graphic Set Font hFont

  ' Print caption
  Graphic Color %Blue, %Black
  Graphic Set Pos (2, 2)
  Graphic Print "Timing chart"

  draw_signal (Using$ ("Horizontal #.### kHz - values in µs", h_freq / 1000), 2, 60, m.htotal, m.hend - m.hbegin, m.htotal - m.hend, m.hactive, m.hbegin - m.hactive, pixel_time, %rgb_Lime)
  draw_signal (Using$ ("Vertical #.### Hz - values in ms", v_freq), 308, 60, m.vtotal, m.vend - m.vbegin, m.vtotal - m.vend, m.vactive, m.vbegin - m.vactive, line_time / IIf(m.interlace, 2, 1), %rgb_Lime)

End Function

'============================================================
'  draw_signal
'============================================================

Function draw_signal(m_text As String, x_pos As Long, y_pos As Long, ByVal a As Double, ByVal b As Double, ByVal c As Double, ByVal d As Double, ByVal e As Double, m_units As Double, m_color As Long) As Long

  Local g_width, g_height As Long
  Local h_scale As Double

  Graphic Get Size To g_width, g_height
  h_scale = (g_width - 60) / (d + (e + b + c) * 2) / 2

  ' Print caption
  Graphic Color %Yellow, %Black
  Graphic Set Pos (x_pos, y_pos - 40)
  Graphic Print m_text

  ' Draw vertical dash reference lines first
  Graphic Style 2
  Graphic Color %Blue, %Black
  Graphic Line (x_pos + e * h_scale, y_pos - 20) - Step (0, 100)
  Graphic Line (x_pos + (e + b) * h_scale, y_pos - 20) - Step (0, 80)
  Graphic Line (x_pos + (e + b + c) * h_scale, y_pos - 20) - Step (0, 80)
  Graphic Line (x_pos + (e + b + c + d) * h_scale, y_pos - 20) - Step (0, 80)
  Graphic Line (x_pos + (e + a) * h_scale, y_pos - 20) - Step (0, 100)
  Graphic Line (x_pos + (e + a + b) * h_scale, y_pos - 20) - Step (0, 100)

  ' Draw video signal
  Graphic Style 0
  Graphic Color m_color, %Black
  Graphic Set Pos (x_pos, y_pos)
  Graphic Line - Step ((e + b + c) * h_scale, 0)
  Graphic Line - Step (0, -20)
  Graphic Line - Step (d * h_scale, 0)
  Graphic Line - Step (0, 20)
  Graphic Line - Step ((e + b + c) * h_scale, 0)
  Graphic Print "video"

  ' Draw sync signal
  Graphic Set Pos (x_pos, y_pos + 40)
  Graphic Line - Step (e * h_scale, 0)
  Graphic Line - Step (0, 20)
  Graphic Line - Step (b * h_scale, 0)
  Graphic Line - Step (0, -20)
  Graphic Line - Step ((c + d + e) * h_scale, 0)
  Graphic Line - Step (0, 20)
  Graphic Line - Step (b * h_scale, 0)
  Graphic Line - Step (0, -20)
  Graphic Line - Step (c * h_scale, 0)
  Graphic Print "sync"

  ' Draw dimensions
  draw_dimension (x_pos + (e + b) * h_scale, y_pos + 10, c * h_scale, Using$("#.###", c * m_units))
  draw_dimension (x_pos + (e + b + c) * h_scale, y_pos + 10, d * h_scale, Using$("#.###", d * m_units))
  draw_dimension (x_pos + (e + b + c + d) * h_scale, y_pos + 10, e * h_scale, Using$("#.###", e * m_units))
  draw_dimension (x_pos + e * h_scale, y_pos + 70, a * h_scale, Using$("#.###", a * m_units))
  draw_dimension (x_pos + (e + a) * h_scale, y_pos + 70, b * h_scale, Using$("#.###", b * m_units))

End Function

'============================================================
'  draw_dimension
'============================================================

Function draw_dimension (x_pos As Long, y_pos As Long, m_length As Long, m_text As String) As Long

  Graphic Color %Blue, %Black
  Graphic Line (x_pos, y_pos) - Step (m_length, 0)
  draw_arrow (x_pos, y_pos, 3)
  draw_arrow (x_pos + m_length, y_pos, -3)
  Graphic Color %Yellow, %Black
  Graphic Set Pos (x_pos + (m_length - Len(m_text)* Graphic(Chr.Size.X)) / 2, y_pos + 5)
  Graphic Print m_text

End Function

'============================================================
'  draw_arrow
'============================================================

Function draw_arrow (x_pos As Long, y_pos As Long, m_size As Long) As Long

  Graphic Width 2
  Graphic Line (x_pos, y_pos) - Step(m_size, - m_size)
  Graphic Line (x_pos, y_pos) - Step(- m_size, m_size)
  Graphic Width 1

End Function
