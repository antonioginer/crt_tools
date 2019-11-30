'==============================================================================
'
'  Monitor library
'  monitor.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

%HFREQ_MIN = 14000
%HFREQ_MAX = 540672 '8192 * 1.1 * 60
%VFREQ_MIN = 40
%VFREQ_MAX = 200
%PROGRESSIVE_LINES_MIN = 128
%DEFAULT_LCD_REFRESH = 60
$DEFAULT_MONITOR = "generic_15"
$MONITOR_INI = "monitor.ini"
%SHORT_NAME = 0
%FULL_NAME = 1
Macro STANDARD_CRT_ASPECT = (4/3)
%MAX_RANGES = 10
%MAX_PRESETS = 32

%M_HORIZONTAL = 0
%M_VERTICAL = 1
%M_ROTATING_R = 2
%M_ROTATING_L = 3

'============================================================
'  Types
'============================================================

Type MONITOR_RANGE
  h_freq_min As Double
  h_freq_max As Double
  v_freq_min As Double
  v_freq_max As Double
  h_front_porch As Double
  h_sync_pulse As Double
  h_back_porch As Double
  v_front_porch As Double
  v_sync_pulse As Double
  v_back_porch As Double
  h_sync_polarity As Long
  v_sync_polarity As Long
  progressive_lines_min As Long
  progressive_lines_max As Long
  interlaced_lines_min As Long
  interlaced_lines_max As Long
  vertical_blank As Double
End Type

Type MONITOR_DEF
  m_name As AsciiZ * 32
  m_name_long As AsciiZ * 48
  m_aspect As AsciiZ * 8
  m_aspect_ratio As Double
  m_range(9) As MONITOR_RANGE
End Type

Type MONITOR_OPTIONS
  m_name As AsciiZ * 32
  orientation As AsciiZ * 16
  rotation As Long
  rotating_desktop As Long
  monitor As MONITOR_DEF Ptr
  preset(%MAX_PRESETS) As MONITOR_DEF
End Type

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function monitor_get_default_options(options As MONITOR_OPTIONS) Common As Long
Declare Function monitor_parse_ini(options As MONITOR_OPTIONS) Common As Long
Declare Function monitor_get_specs(ByVal m_name As String, options As MONITOR_OPTIONS) Common As Long
Declare Function monitor_orientation(index As Long) Common As String
Declare Function monitor_get_rotation(ByVal orientation_opt As String) Common As Long
Declare Function monitor_range_to_string(m_range As MONITOR_RANGE) Common As String
#EndIf
