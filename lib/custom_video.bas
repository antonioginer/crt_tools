'==============================================================================
'
'  Custom video library
'  custom_video.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Dim All

#Include Once "win32api.inc"
#Include "modeline.inc"
#Include "edid.inc"
#Include "display.inc"
#Include "ati_reg.inc"
#Include "adl_lib.inc"
#Include "pstrip.inc"
#Include "custom_video.inc"
#Include "util.inc"
#Include "log_console.inc"

'============================================================
'  Globals
'============================================================

Global adl As Long
Global device_name As String
Global driver_regkey As AsciiZ * 256
Global custom_method As Long
Global custom_method_name As String
Global custom_driver_name As String
Global mod_release As String
Global driver_release As String
Global win_version As Long

'============================================================
'  custom_video_get_default_options
'============================================================

Function custom_video_get_default_options(options As CUSTOM_VIDEO_OPTIONS) Common As Long

  options.any_catalyst = 0

End Function

'============================================================
'  custom_video_init
'============================================================

Function custom_video_init(device_name_to_init As String) Common As Long

  ' Reset previous information
  custom_method = 0

  clog $CrLf + "Getting driver information for " + device_name_to_init
  win_version = os_version()
  driver_regkey = display_get_master_device_key(device_name_to_init)
  device_name = device_name_to_init

  If ps_init((ps_monitor_index(device_name_to_init))) Then
    custom_method = %CUSTOM_VIDEO_TIMING_POWERSTRIP
    custom_driver_name = "PowerStrip"
    custom_method_name = "PowerStrip"

  Else
    If ATI_get_driver_release(driver_regkey, driver_release, mod_release) Then

      ' Restart ADL
      adl_close()
      adl = adl_open(driver_release)

      If mod_release <> "" Then
        custom_driver_name = Using$("CRT Emudriver & (&)", mod_release, driver_release)
      Else
        custom_driver_name = "AMD Catalyst " + driver_release
      End If

      Local is_legacy As Long
      is_legacy = ATI_is_legacy_chipset(driver_regkey)

      If is_legacy Then
        custom_method = %CUSTOM_VIDEO_TIMING_ATI_LEGACY
        custom_method_name = "ATI legacy"

      ElseIf adl And win_version > 5 Then
        custom_method = %CUSTOM_VIDEO_TIMING_ATI_ADL
        custom_method_name = "AMD Display Library (ADL)"

      End If
    End If
  End If

  custom_driver_name = IIf$(custom_method, custom_driver_name, "No compatible driver")
  custom_method_name = IIf$(custom_method, custom_method_name, "-")
  clog custom_driver_name + " found."

  Function = custom_method
End Function

'============================================================
'  custom_video_get_method
'============================================================

Function custom_video_get_method() Common As Long
  Function = custom_method
End Function

'============================================================
'  custom_video_get_method_name
'============================================================

Function custom_video_get_method_name() Common As String
  Function = custom_method_name
End Function

'============================================================
'  custom_video_get_driver_name
'============================================================

Function custom_video_get_driver_name() Common As String
  Function = custom_driver_name
End Function

'============================================================
'  custom_video_get_max_modes
'============================================================

Function custom_video_get_max_modes() Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      Select Case As Const$ driver_release
        Case "6.5"
          Function = IIf(mod_release = "", 60, IIf(is_64(), 120, 200))
        Case "9.3", "12.6", "13.1"
          Function = IIf(mod_release = "", 60, 120)
        Case Else
          Function = 60
      End Select

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = IIf(mod_release = "", 10, 120)

    Case Else
      Function = 32
  End Select

End Function

'============================================================
'  custom_video_get_min_dotclock()
'============================================================

Function custom_video_get_min_dotclock() Common As Double

  Select Case custom_method
    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY, %CUSTOM_VIDEO_TIMING_ATI_ADL
      If IsFalse ATI_is_low_dotclocks_supported(driver_regkey) Then Function = 8.0
  End Select

End Function

'============================================================
'  custom_video_get_mode_list
'============================================================

Function custom_video_get_mode_list(video_mode() As MODELINE) Common As Long

  Local custom_count As Long

  If video_mode(0).width Then
    Local i As Long
    While video_mode(i).width
      Select Case custom_method

        Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY, %CUSTOM_VIDEO_TIMING_ATI_ADL
          If custom_video_get_timing(video_mode(i)) Then Incr custom_count

        Case %CUSTOM_VIDEO_TIMING_POWERSTRIP
          If (video_mode(i).type And %MODE_DESKTOP) Then custom_video_get_timing(video_mode(i))
          video_mode(i).type Or= custom_method Or %V_FREQ_EDITABLE
          Incr custom_count

      End Select

      Incr i
    Wend

  Else
    Select Case custom_method

      Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
        custom_count = ATI_get_modeline_list(driver_regkey, video_mode(), win_version)

      Case %CUSTOM_VIDEO_TIMING_ATI_ADL
        custom_count = ADL_get_modeline_list(device_name, video_mode())

    End Select
  End If

  Function = custom_count
End Function

'============================================================
'  custom_video_set_mode_list
'============================================================

Function custom_video_set_mode_list(video_mode() As MODELINE) Common As Long

  Local custom_count As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      custom_count = ATI_set_modeline_list(driver_regkey, video_mode(), win_version)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      custom_count = ADL_set_modeline_list(device_name, video_mode())

    Case %CUSTOM_VIDEO_TIMING_POWERSTRIP
      custom_count = ps_set_modeline_list(display_monitor_index_from_device(device_name), video_mode())

  End Select

  Function = custom_count
End Function

'============================================================
'  custom_video_reset_mode_list
'============================================================

Function custom_video_reset_mode_list() Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      ATI_clean_registry(driver_regkey)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      ADL_delete_modeline_list(device_name)

  End Select

End Function

'============================================================
'  custom_video_get_timing
'============================================================

Function custom_video_get_timing(m As MODELINE) Common As Long

  Local found As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      found = ATI_get_modeline(driver_regkey, m, win_version)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      found = ADL_get_modeline(device_name, m)

    Case %CUSTOM_VIDEO_TIMING_POWERSTRIP
      found = ps_get_timing(m, display_monitor_index_from_device(device_name))

  End Select

  If found And m.hactive Then
    m.type Or= custom_method Or %V_FREQ_EDITABLE
    modeline_compute_frequency(m)
    Function = 1
  End If

End Function

'============================================================
'  custom_video_update_timing
'============================================================

Function custom_video_update_timing(m As MODELINE) Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      Function = ATI_set_modeline(driver_regkey, m, win_version, %MODELINE_UPDATE)
      display_reset_video_driver(device_name)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ADL_set_modeline(device_name, m, %MODELINE_UPDATE)

    Case %CUSTOM_VIDEO_TIMING_POWERSTRIP
      Function = ps_set_timing(m, display_monitor_index_from_device(device_name))
      modeline_compute_frequency(m)

    End Select

End Function

'============================================================
'  custom_video_read_timing
'============================================================

Function custom_video_read_timing(m As MODELINE) Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_POWERSTRIP
      Function = ps_get_timing(m, display_monitor_index_from_device(device_name))
      m.type Or= custom_method Or %V_FREQ_EDITABLE
      modeline_compute_frequency(m)

  End Select

End Function

'============================================================
'  custom_video_edid_emulation_enable
'============================================================

Function custom_video_edid_emulation_enable(ByVal connector As String, edid As EDID_BLOCK) Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY, %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ATI_edid_emulation_enable(driver_regkey, connector, edid)

  End Select
End Function


'============================================================
'  custom_video_edid_emulation_disable
'============================================================

Function custom_video_edid_emulation_disable(ByVal connector As String) Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY, %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ATI_edid_emulation_disable(driver_regkey, connector)

  End Select
End Function

'============================================================
'  custom_video_edid_emulation_read
'============================================================

Function custom_video_edid_emulation_read(ByVal connector As String, edid As EDID_BLOCK) Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY, %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ATI_edid_emulation_read(driver_regkey, connector, edid)

  End Select
End Function

'============================================================
'  custom_video_csync_enable
'============================================================

Function custom_video_csync_enable() Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      Function = ATI_csync_set(device_name, 1)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ADL_csync_enable(driver_regkey, device_name)

  End Select
End Function

'============================================================
'  custom_video_csync_enable
'============================================================

Function custom_video_csync_disable() Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      Function = ATI_csync_set(device_name, 0)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ADL_csync_disable(driver_regkey, device_name)

  End Select
End Function

'============================================================
'  custom_video_csync_read
'============================================================

Function custom_video_csync_read() Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_LEGACY
      Function = ATI_csync_read(device_name)

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ADL_csync_read(driver_regkey, device_name)

  End Select
End Function


'============================================================
'  custom_video_get_connectors
'============================================================

Function custom_video_get_connectors(i As Long, connector_label As String) Common As Long

  Select Case custom_method

    Case %CUSTOM_VIDEO_TIMING_ATI_ADL
      Function = ADL_enum_connectors_from_adapter(i, connector_label)

  End Select
End Function
