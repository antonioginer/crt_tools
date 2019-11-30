'==============================================================================
'
'  VideoModeMaker
'  user_modes.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Dim All

#Include "modeline.inc"
#Include "mode_db.inc"
#Include "util.inc"
#Include "user.inc"

Declare Function clog(Txt As String) Common As Long

'============================================================
'  user_get_default_options
'============================================================

Function user_get_default_options(options As USER_OPTIONS) Common As Long

  options.list_user_modes = 0
  options.mode_list = $USER_MODE_LIST

End Function

'============================================================
'  user_get_modes
'============================================================

Function user_get_modes(mdb As IMODE_DB, options As USER_OPTIONS) As Long

  Local i, total_lines, members, mode_count As Long
  Local Linea, l_prefix, l_suffix, source_label As String

  Local xres, yres As Long
  Local vfreq As Double

  clog "Importing video modes from custom list..." + $CrLf

  Local user_list As String
  user_list = file_to_string(options.mode_list)
  total_lines = ParseCount(user_list, $CrLf)

  For i = 1 To total_lines

    Linea = Parse$(user_list, $CrLf, i)
    Linea = Trim$(Parse$(Linea, "#", 1), Any $Spc + $Tab)

    members = ParseCount(Linea, "@")
    l_prefix = Parse$(Linea, "@", 1)

    If l_prefix <> "" Then
      xres = Val(Parse$(l_prefix, "x", 1))
      yres = Val(Parse$(l_prefix, "x", 2))

      If xres <> 0 And yres <> 0 Then
        l_suffix = Trim$ (Parse$(Linea, "@", 2), Any $Spc + $Tab)
        vfreq = Val(Parse$(l_suffix, $Spc, 1))
        source_label = Parse$(l_suffix, $Spc, 2)

        If vfreq = 0 Then vfreq = %DEFAULT_VFREQ
        If source_label = "" Then source_label = "unknown"

        mode_count += mdb.register_mode(xres, yres, vfreq, %M_HORIZONTAL, %PRIORITY_HIGH, %CUSTOM_LIST, source_label)
      End If
    End If
  Next
  Function = mode_count
End Function
