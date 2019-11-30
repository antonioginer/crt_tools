'==============================================================================
'
'  Modeline library
'  modeline.inc
'  Copyright (c) 2008-2014 Antonio Giner González
'
'==============================================================================

#Include Once "monitor.inc"

'============================================================
'  Constants
'============================================================

' Modelines
%MS_LABEL      = &h00000001
%MS_LABEL_SDL  = &h00000002
%MS_PARAMS     = &h00000004
%MS_FULL       = %MS_LABEL Or %MS_PARAMS

' Modeline result
%R_V_FREQ_OFF    = &h00000001
%R_RES_STRETCH   = &h00000002
%R_OUT_OF_RANGE  = &h00000004

' Modeline commands
%MODELINE_DELETE      = &h01
%MODELINE_CREATE      = &h02
%MODELINE_UPDATE      = &h04
%MODELINE_UPDATE_LIST = &h08

' Mode types
%MODE_OK         = &h00000000
%MODE_DESKTOP    = &h10000000
%MODE_ROTATED    = &h20000000
%MODE_LOCKED     = &h80000000
%V_FREQ_EDITABLE = &h00000001
%X_RES_EDITABLE  = &h00000002
%Y_RES_EDITABLE  = &h00000004
%XYV_EDITABLE    = %X_RES_EDITABLE Or %Y_RES_EDITABLE Or %V_FREQ_EDITABLE

%DEFAULT_VFREQ = 60
%DOTCLOCK_MAX = 600000 ' 6GHz
%DUMMY_WIDTH = 1234

'============================================================
'  Types
'============================================================

Type MODE_RESULT
  weight As Long
  x_scale As Long
  y_scale As Long
  v_scale As Long
  x_diff As Double
  y_diff As Double
  v_diff As Double
  x_ratio As Double
  y_ratio As Double
  v_ratio As Double
  rotated As Long
End Type

Type MODELINE
  pclock As Quad
  hactive As Long
  hbegin As Long
  hend As Long
  htotal As Long
  vactive As Long
  vbegin As Long
  vend As Long
  vtotal As Long
  interlace As Long
  doublescan As Long
  hsync As Long
  vsync As Long

  vfreq As Double
  hfreq As Double

  width As Long
  height As Long
  refresh As Long
  refresh_label As Long
  bpp As Long

  type As Long
  range As Long
  result As MODE_RESULT
End Type

Type MODE_LABEL
  width As Long
  height As Long
  bpp As Long
  refresh As Long
  refresh_label As Long
End Type

Type MODELINE_OPTIONS
  interlace As Long
  doublescan As Long
  effective_orientation As Long
  monitor_aspect As Double
  sync_refresh_tolerance As Double
  pclock_min As Double
  s_pclock_min As AsciiZ * 8
End Type

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function get_modeline(xres As Long, yres As Long, vfreq As Double, ByVal m As MONITOR_DEF Ptr, options As MODELINE_OPTIONS, t_mode As modeline) Common As Long
Declare Function modeline_create(s_mode As modeline, t_mode As modeline, m_range As MONITOR_RANGE, options As MODELINE_OPTIONS) Common As Long
Declare Function modeline_print(t_mode As modeline, flags As Long) Common As String
Declare Function modeline_result(t_mode As modeline) Common As String
Declare Function modeline_compare(t As modeline, best As modeline) Common As Long
Declare Function modeline_vesa_gtf(vm As modeline) Common As Long
Declare Function modeline_info (m As modeline, dotclock_table() As Long) Common As String
Declare Function modeline_get_default_options(options As MODELINE_OPTIONS) Common As Long
Declare Function modeline_get_dotclock_table(dotclock_file As String) Common As Long
Declare Function modeline_dotclock(m As MODELINE) Common As Long
Declare Function modeline_reclock(p As MODELINE, c As MODELINE) Common As Long
Declare Function modeline_compute_frequency(m As MODELINE) Common As Long
Declare Function modeline_parse(m As String, v As MODELINE) Common As Long
Declare Function modeline_to_monitor_range(v As MODELINE) Common As String
Declare Function modeline_from_clipboard(v As MODELINE) Common As Long
Declare Function modeline_to_clipboard(v As MODELINE) Common As Long
#EndIf
