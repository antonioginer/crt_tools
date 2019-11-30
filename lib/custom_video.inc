'==============================================================================
'
'  Custom video library
'  custom_video.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

%CUSTOM_VIDEO_TIMING_MASK        = &h00000ff0
%CUSTOM_VIDEO_TIMING_SYSTEM      = &h00000008
%CUSTOM_VIDEO_TIMING_XRANDR      = &h00000010
%CUSTOM_VIDEO_TIMING_POWERSTRIP  = &h00000020
%CUSTOM_VIDEO_TIMING_ATI_LEGACY  = &h00000040
%CUSTOM_VIDEO_TIMING_ATI_ADL     = &h00000080

'============================================================
'  Types
'============================================================

Type CUSTOM_VIDEO_OPTIONS
  any_catalyst As Long
End Type

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function custom_video_get_default_options(options As CUSTOM_VIDEO_OPTIONS) Common As Long
Declare Function custom_video_init(device_name As String) Common As Long
Declare Function custom_video_get_method() Common As Long
Declare Function custom_video_get_method_name() Common As String
Declare Function custom_video_get_driver_name() Common As String
Declare Function custom_video_get_min_dotclock() Common As Double
Declare Function custom_video_get_max_modes() Common As Long
Declare Function custom_video_get_mode_list(video_mode() As MODELINE) Common As Long
Declare Function custom_video_set_mode_list(video_mode() As MODELINE) Common As Long
Declare Function custom_video_reset_mode_list() Common As Long
Declare Function custom_video_get_timing(m As MODELINE) Common As Long
Declare Function custom_video_update_timing(m As MODELINE) Common As Long
Declare Function custom_video_read_timing(m As MODELINE) Common As Long
Declare Function custom_video_edid_emulation_enable(ByVal connector As String, edid As EDID_BLOCK) Common As Long
Declare Function custom_video_edid_emulation_disable(ByVal connector As String) Common As Long
Declare Function custom_video_edid_emulation_read(ByVal connector As String, edid As EDID_BLOCK) Common As Long
Declare Function custom_video_csync_read() Common As Long
Declare Function custom_video_csync_enable() Common As Long
Declare Function custom_video_csync_disable() Common As Long
Declare Function custom_video_get_connectors(i As Long, connector_label As String) Common As Long
#EndIf
