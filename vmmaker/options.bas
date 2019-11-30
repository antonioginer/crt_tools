'==============================================================================
'
'  VideoModeMaker
'  options.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "vmmaker.inc"

Declare Function display_get_default_options(options As DISPLAY_OPTIONS) Common As Long
Declare Function modeline_get_default_options(options As MODELINE_OPTIONS) Common As Long
Declare Function monitor_get_default_options(options As MONITOR_OPTIONS) Common As Long
Declare Function edid_get_default_options(options As EDID_OPTIONS) Common As Long
Declare Function mode_db_get_default_options(options As MODE_DB_OPTIONS) Common As Long
Declare Function mame_get_default_options(options As MAME_OPTIONS) Common As Long
Declare Function ati_inf_get_default_options(options As INF_OPTIONS) Common As Long
Declare Function clog(t As String) Common As Long

%TAB_SIZE = 32

'============================================================
'  options_init_default_data
'============================================================

Function options_init_default_data(options As APP_OPTIONS) Common As Long

  display_get_default_options(options.display)
  custom_video_get_default_options(options.custom_video)
  modeline_get_default_options(options.modeline)
  monitor_get_default_options(options.monitor)
  edid_get_default_options(options.edid)
  mode_db_get_default_options(options.mode_db)
  mame_get_default_options(options.mame)
  user_get_default_options(options.user)
  ati_inf_get_default_options(options.inf)

End Function

'============================================================
'  options_get_from_ini
'============================================================

Function options_get_from_ini(app_ini_file As String, options As APP_OPTIONS) Common As Long

  Local app_ini, line_number As Long
  Local new_line, option_name, option_text As String
  Local option_value As Double

  app_ini = FreeFile
  Open app_ini_file For Input As app_ini

  While Not Eof(app_ini)

    Line Input #app_ini, new_line
    new_line = Trim$(Parse$(new_line, "#", 1), Any $Spc + $Tab)
    Incr line_number
    If new_line <> "" Then

      new_line = Trim$(new_line, Any $Spc + $Tab)
      option_name = LCase$(Parse$(new_line, $Spc, 1))
      option_text = Trim$(Clip$(Left new_line, Len(option_name)), Any $Spc + $Tab)
      option_value = Val(option_text)

      Select Case As Const$ option_name
        Case "mame_exe"
          options.mame.exe_path = option_text
        Case "mame_favourites"
          options.mame.favourites = option_text
        Case "mame_list_from_xml"
          options.mame.list_xml_modes = option_value
        Case "mame_generate_xml"
          options.mame.generate_xml = option_value
        Case "mame_only_list_favourites"
          options.mame.only_list_favourites = option_value
        Case "mame_export_settings"
          options.mame.export_settings = option_value
        Case "user_modes"
          options.user.mode_list = option_text
        Case "user_list_modes"
          options.user.list_user_modes = option_value
        Case "monitor"
          options.monitor.m_name = LCase$(option_text)
        Case "orientation"
          options.monitor.orientation = option_text
        Case "rotating_desktop"
          options.monitor.rotating_desktop = option_value
        Case "total_modes"
          options.mode_db.total_modes = option_text
        Case "mode_table_method_xml"
          options.mode_db.mode_table_method_xml = option_value
        Case "mode_table_method_user"
          options.mode_db.mode_table_method_user = option_value
        Case "x_res_min_xml"
          options.mode_db.x_res_min_xml = option_value
        Case "y_res_min_xml"
          options.mode_db.y_res_min_xml = option_value
        Case "y_res_round_xml"
          options.mode_db.y_res_round_xml = option_value
        Case "x_res_min_user"
          options.mode_db.x_res_min_user = option_value
        Case "y_res_min_user"
          options.mode_db.y_res_min_user = option_value
        Case "y_res_round_user"
          options.mode_db.y_res_round_user = option_value
        Case "dotclock_min"
          options.modeline.s_pclock_min = option_text
          options.modeline.pclock_min = option_value * 1000000
        Case "display_device_key"
          options.display.device_key = option_text
        Case "auto_extend_desktop"
          options.display.auto_extend_desktop = option_value
        Case "edid_from_modelist"
          options.edid.from_modelist = option_value
        Case Else
          clog app_ini_file + Using$ (" error in line #: ", line_number) + option_name
      End Select
    End If
  Wend

  Close
End Function

'============================================================
'  options_write_to_ini
'============================================================

Function options_write_to_ini(app_ini_file As String, options As APP_OPTIONS) Common As Long

  Local app_ini As Long

  app_ini = FreeFile
  Open app_ini_file For Output As app_ini

  Print #app_ini, LSet$("mame_exe", %TAB_SIZE) + Trim$(options.mame.exe_path)
  Print #app_ini, LSet$("mame_favourites", %TAB_SIZE) + Trim$(options.mame.favourites)
  Print #app_ini, LSet$("mame_list_from_xml", %TAB_SIZE) + Using$("#", options.mame.list_xml_modes)
  Print #app_ini, LSet$("mame_generate_xml", %TAB_SIZE) + Using$("#", options.mame.generate_xml)
  Print #app_ini, LSet$("mame_only_list_favourites", %TAB_SIZE) + Using$("#", options.mame.only_list_favourites)
  Print #app_ini, LSet$("mame_export_settings", %TAB_SIZE) + Using$("#", options.mame.export_settings)
  Print #app_ini, LSet$("user_list_modes", %TAB_SIZE) + Using$("#", options.user.list_user_modes)
  Print #app_ini, LSet$("user_modes", %TAB_SIZE) + Trim$(options.user.mode_list)
  Print #app_ini, LSet$("monitor", %TAB_SIZE) + Trim$(options.monitor.m_name)
  Print #app_ini, LSet$("orientation", %TAB_SIZE) + Trim$(options.monitor.orientation)
  Print #app_ini, LSet$("rotating_desktop", %TAB_SIZE) + Trim$(options.monitor.rotating_desktop)
  Print #app_ini, LSet$("total_modes", %TAB_SIZE) + Trim$(options.mode_db.total_modes)
  Print #app_ini, LSet$("mode_table_method_xml", %TAB_SIZE) + Using$("#", options.mode_db.mode_table_method_xml)
  Print #app_ini, LSet$("mode_table_method_user", %TAB_SIZE) + Using$("#", options.mode_db.mode_table_method_user)
  Print #app_ini, LSet$("x_res_min_xml", %TAB_SIZE) + Using$("#", options.mode_db.x_res_min_xml)
  Print #app_ini, LSet$("y_res_min_xml", %TAB_SIZE) + Using$("#", options.mode_db.y_res_min_xml)
  Print #app_ini, LSet$("y_res_round_xml", %TAB_SIZE) + Using$("#", options.mode_db.y_res_round_xml)
  Print #app_ini, LSet$("x_res_min_user", %TAB_SIZE) + Using$("#", options.mode_db.x_res_min_user)
  Print #app_ini, LSet$("y_res_min_user", %TAB_SIZE) + Using$("#", options.mode_db.y_res_min_user)
  Print #app_ini, LSet$("y_res_round_user", %TAB_SIZE) + Using$("#", options.mode_db.y_res_round_user)
  Print #app_ini, LSet$("dotclock_min", %TAB_SIZE) + Trim$(options.modeline.s_pclock_min)
  Print #app_ini, LSet$("display_device_key", %TAB_SIZE) + Trim$(options.display.device_key)
  Print #app_ini, LSet$("auto_extend_desktop", %TAB_SIZE) + Using$("#", options.display.auto_extend_desktop)
  Print #app_ini, LSet$("edid_from_modelist", %TAB_SIZE) + Using$("#", options.edid.from_modelist)

  Close
End Function
