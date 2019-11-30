'==============================================================================
'
'  ATI inf
'  ati_inf.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "ati_inf.inc
#Include "util.inc"
#Include "log_console.inc"

'============================================================
'  ati_inf_file_update
'============================================================

Function ati_inf_file_update(options As INF_OPTIONS) Common As Long

  Local driver_version, driver_inf_file As String

  If IsFalse dir_exists(options.path) Then clog "driver_path not found: " + options.path : Function = 1: Exit Function

  driver_inf_file = ati_inf_file_get(options, driver_version)
  If driver_inf_file = "" Then clog "No compatible driver found in driver_path: " + options.path : Function = 1: Exit Function
  clog "Catalyst version "+ driver_version + " found in " + options.path

  clog "Updating driver..."
  ati_inf_file_add_modes(driver_inf_file, options)

End Function

'============================================================
'  ati_inf_file_get
'============================================================

Function ati_inf_file_get(options As INF_OPTIONS, driver_version As String) As String

  Local inf_file As String

  inf_file = "2KXP_INF\CX_38185.inf"
  If file_exists(options.path + inf_file) Then driver_version = "06.11" : Function = inf_file : Exit Function

  inf_file = "XP6A_INF\CA_32467.inf"
  If file_exists(options.path + inf_file) Then driver_version = "06.5" : Function = inf_file : Exit Function

  inf_file = "XP_INF\CX_76825.inf"
  If file_exists(options.path + inf_file) Then driver_version = "09.3" : Function = inf_file : Exit Function

  inf_file = "XP6A_INF\CA_76826.inf"
  If file_exists(options.path + inf_file) Then driver_version = "09.3" : Function = inf_file : Exit Function

End Function

'============================================================
'  ati_inf_file_add_modes
'============================================================

Function ati_inf_file_add_modes(inf_file As String, options As INF_OPTIONS) As Long

  Local inf_org, inf_mod, reg_modelines, lines_written As Long
  Local current_line, reg_label As String

  Shell Environ$("COMSPEC") + " /C copy " + options.path + inf_file + " " + options.path + inf_file + ".bak"

  inf_org = FreeFile
  Open options.path + inf_file + ".bak" For Input As inf_org
  reg_modelines = FreeFile
  Open "RegMdlns.txt" For Input As reg_modelines
  inf_mod = FreeFile
  Open options.path + inf_file For Output As inf_mod

  reg_label = "[ati2mtag_SoftwareDeviceSettings]"

  While Not Eof(inf_org)

    Line Input #inf_org, current_line
    Print #inf_mod, current_line

    If IsFalse InStr(current_line, reg_label) Then Iterate Loop

    Print #inf_mod,
    While Not Eof(reg_modelines)
      Line Input #reg_modelines, current_line
      Print #inf_mod, current_line
      Incr lines_written
    Wend

    Do
      Line Input #inf_org, current_line
    Loop While IsFalse InStr(current_line, "DDC2Disabled")
    Print #inf_mod, current_line

  Wend
  Close

End Function

'============================================================
'  ati_inf_get_default_options
'============================================================

Function ati_inf_get_default_options(options As INF_OPTIONS) Common As Long

  options.path = ".\Driver\"
  options.update = 0

End Function
