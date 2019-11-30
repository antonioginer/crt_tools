'==============================================================================
'
'  VideoModeMaker
'  mame.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Dim All
#Include "vmmaker.inc"

Declare Function clog(Txt As String) Common As Long
Macro degrees_to_radians(alpha) = (alpha * 0.0174532925199433##)

'============================================================
'  Globals
'============================================================

  Global favourite() As String
  Global favourite_count As Long

'============================================================
'  mame_get_default_options
'============================================================

Function mame_get_default_options(options As MAME_OPTIONS) Common As Long

  options.exe_path = ""
  options.favourites = $MAME_FAVOURITES
  options.generate_xml = 0
  options.list_xml_modes = 0
  options.only_list_favourites = 0

End Function

'============================================================
'  mame_get_modes
'============================================================

Function mame_get_modes(mdb As IMODE_DB, options As MAME_OPTIONS) Common As Long

  mame_get_favourites(options.favourites, mdb)

  If options.generate_xml Then
    If IsFalse file_exists(options.exe_path) Then clog "MAME/MESS/UME executable not found: " + options.exe_path : Exit Function
    clog "Extracting mame.xml..." + $CrLf
    If IsFalse mame_get_xml(options.exe_path, $MAME_XML) Then clog "Error extracting " + $MAME_XML : Exit Function
  End If

  If IsFalse file_exists($MAME_XML) Then clog "xml file not found: " + $MAME_XML : Exit Function

  Function = mame_list_from_xml($MAME_XML, mdb, options)
End Function

'============================================================
'  mame_get_xml
'============================================================

Function mame_get_xml(ByVal mame_exe As String, mame_xml As String) Common As Long
  If launch_command(mame_exe, "-listxml", mame_xml) = 0 Then Function = 1
End Function

'============================================================
'  mame_list_from_xml
'============================================================

Function mame_list_from_xml(xml_list As String, mdb As imode_db, options As MAME_OPTIONS) Common As Long

  Local mame_xml, mame_list As Long
  Local mame_version As Long
  Local xres, yres, rotation, favourite As Long
  Local vfreq As Double
  Local element, mame_build, rom_name, source_file, description, video_screen As String
  Local mode_count As Long

  mame_xml = FreeFile
  Open xml_list For Input As mame_xml

  mame_list = FreeFile
  Open "MameList.txt" For Output As mame_list

  clog "Importing video modes from MAME.xml..."

  element = xml_get_element(mame_xml, "mame")
  mame_build = xml_get_attribute(element, "build")

  clog "Mame " + IIf$(mame_build <> "", "v" + mame_build, "unknown version") + $CrLf
  mame_version = Val(Mid$(mame_build, 3, 3))

  While Not Eof(mame_xml)

    element = xml_get_element(mame_xml, IIf$(mame_version < 162, "game", "machine"))
    If element = "" Then Exit Loop

    rom_name = xml_get_attribute(element, "name")
    source_file = Extract$(xml_get_attribute(element, "sourcefile"), ".")
    If xml_get_attribute(element, "ismechanical") = "yes" Then Iterate Loop
    If xml_get_attribute(element, "isdevice") = "yes" Then Iterate Loop
    favourite = is_favourite(rom_name)
    If favourite = 0 And options.only_list_favourites Then Iterate Loop

    description = xml_get_element(mame_xml, "description")
    Replace "&amp;" With "&" In description
    Replace "&quot;" With "'" In description

    Select Case mame_version
      Case < 107
        element = xml_get_element(mame_xml, "video")
        video_screen = xml_get_attribute(element, "screen")
        rotation = IIf(xml_get_attribute(element, "orientation") = "vertical", 1, 0)
      Case >= 107
        element = xml_get_element(mame_xml, "display")
        video_screen = xml_get_attribute(element, "type")
        rotation = Abs(Sin(degrees_to_radians(Val(xml_get_attribute(element, "rotate")))))
    End Select

    If video_screen = "raster" Or video_screen = "lcd" Then
      xres = Val(xml_get_attribute(element, "width"))
      yres = Val(xml_get_attribute(element, "height"))
      If mame_version < 107 And rotation Then Swap xres, yres
    Else
      xres = 640 : yres = 480
    End If
    vfreq = Val(xml_get_attribute(element, "refresh"))
    'effective_orientation = rotation 'Xor IIf(monitor_rotation = %M_ROTATING, rotation, monitor_rotation)

    Print #mame_list, LSet$(rom_name, 9 Using " "); LSet$(source_file, 9 Using " "); "[" + video_screen + "] " + LSet$(IIf$(rotation, "vertical", "horizontal"), 10 Using " " );
    Print #mame_list, Using$("#### x#### @ ##.###### ", xres, yres, vfreq);
    Print #mame_list, $Dq + description + $Dq

    If rotation Then rom_name = rom_name + "(v)"
    If favourite Then rom_name = "[" + rom_name + "]"

    mode_count += mdb.register_mode(xres, yres, vfreq, rotation, IIf(favourite, %PRIORITY_HIGH, %PRIORITY_LOW), %XML_LIST, rom_name)
  Wend

  Function = mode_count
End Function

'============================================================
'  xml_get_element
'============================================================

Function xml_get_element(file_number As Long, element As String) As String

  Local found As Long
  Local current_line As String

  element = "<" + element

  While (IsFalse found) And Not Eof(file_number)
    Line Input #file_number, current_line
    found = InStr(current_line, element)
  Wend

  If found Then Function = Extract$(Trim$(Clip$(Left current_line, found + Len(element)), Any $Tab + $Spc + "</>"), "</")
End Function

'============================================================
'  xml_get_attribute
'============================================================

Function xml_get_attribute(element As String, attr_label As String) As String

  Local attr_pos As Long
  attr_pos = InStr(element, attr_label)
  If IsFalse attr_pos Then Exit Function

  Function = Extract$(attr_pos + Len(attr_label) + 2, element, $Dq)
End Function

'============================================================
'  mame_get_favourites
'============================================================

Function mame_get_favourites(ByVal file_name As String, mdb As imode_db) Common As Long

  Dim favourite(%NUMBER_OF_DRIVERS) As Global String
  Reset favourite()
  Reset favourite_count

  Local favourites As String
  favourites = file_to_string(file_name)

  Local i As Long
  For i = 1 To ParseCount(favourites, $CrLf)
    mame_register_favourite(Trim$(Parse$(Parse$(favourites, $CrLf, i), "#", 1), Any $Spc + $Tab))
  Next

End Function

'============================================================
'  mame_register_favourite
'============================================================

Function mame_register_favourite(source_label As String) As Long
  Incr favourite_count
  favourite(favourite_count) = source_label
End Function

'============================================================
'  is_favourite
'============================================================

Function is_favourite(source_label As String) As Long
  Local i As Long
  For i = 1 To favourite_count
    If source_label = favourite(i) Then Function = i : Exit Function
  Next
End Function

'============================================================
'  mame_update_ini
'============================================================

Function mame_update_ini(opt_mame As MAME_OPTIONS, opt_monitor As MONITOR_OPTIONS) Common As Long

  Local i As Long
  Local mame_ini As String
  mame_ini = PathName$(Path, opt_mame.exe_path) + "mame.ini"

  If IsFalse file_exists(mame_ini) Then clog mame_ini + " not found." : Exit Function

  mame_ini_set_option(mame_ini, "monitor", "custom")
  mame_ini_set_option(mame_ini, "orientation", opt_monitor.orientation)

  For i = 0 To 9
    mame_ini_set_option(mame_ini, Using$("crt__range#", i), monitor_range_to_string(opt_monitor.@monitor.m_range(i)))
  Next i

  Local numerator, denominator As String
  numerator = Parse$(opt_monitor.@monitor.m_aspect, ":", 1)
  denominator = Parse$(opt_monitor.@monitor.m_aspect, ":", 2)
  mame_ini_set_option(mame_ini, "aspect", IIf$(opt_monitor.rotating_desktop, denominator, numerator) + ":" +_
                                          IIf$(opt_monitor.rotating_desktop, numerator, denominator))

  Function = 1
End Function

'============================================================
'  mame_ini_get_option
'============================================================

Function mame_ini_get_option(mame_ini As String, option_name As String) As String

  Local ini As String
  ini = file_to_string(mame_ini)

  Local i, num_lines As Long
  num_lines = ParseCount(ini, $CrLf)

  For i = 1 To num_lines
    Local n_line, n_opt As String
    n_line = Trim$(Parse$(Parse$(ini, $CrLf, i), "#", 1), Any $Spc + $Tab)
    If n_line = "" Then Iterate For
    n_opt = Trim$(Parse$(n_line, Any $Spc + $Tab, 1))
    If n_opt = option_name Then
      Function = Trim$(Remain$(n_line, Any $Spc + $Tab))
      Exit For
    End If
  Next

End Function

'============================================================
'  mame_ini_set_option
'============================================================

Function mame_ini_set_option(mame_ini As String, option_name As String, ByVal new_value As String) As String

  Local ini, ini_mod, line_mod As String
  ini = file_to_string(mame_ini)

  line_mod = LSet$(option_name, 26) + new_value + $CrLf

  Local i, num_lines, found As Long
  num_lines = ParseCount(ini, $CrLf)

  For i = 1 To num_lines
    Local n_line, n_line_org, n_opt As String
    n_line_org = Parse$(ini, $CrLf, i)
    n_line = Trim$(Parse$(n_line_org, "#", 1), Any $Spc + $Tab)
    n_opt = Trim$(Parse$(n_line, Any $Spc + $Tab, 1))
    If n_opt = option_name Then
      ini_mod = ini_mod + line_mod
      found = 1
    Else
      ini_mod = ini_mod + n_line_org + $CrLf
    End If
  Next

  ' If not option is not found, append to file
  If IsFalse found Then ini_mod = ini_mod + line_mod

  ' Save modified file
  Local file_num As Long
  file_num = FreeFile
  Open mame_ini For Output As file_num
  Print #file_num, Trim$(ini_mod, $CrLf)
  Close

End Function
