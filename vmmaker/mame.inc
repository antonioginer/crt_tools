'==============================================================================
'
'  VideoModeMaker
'  mame.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

%NUMBER_OF_DRIVERS = 512
$MAME_XML = "mame.xml"
$MAME_FAVOURITES = "mame_favourites.ini"

'============================================================
'  Types
'============================================================

Type MAME_OPTIONS
  exe_path As AsciiZ * 256
  favourites As AsciiZ * 256
  generate_xml As Long
  list_xml_modes As Long
  only_list_favourites As Long
  export_settings As Long
End Type

'============================================================
'  Functions
'============================================================

Declare Function mame_get_modes(mdb As IMODE_DB, options As MAME_OPTIONS) Common As Long
Declare Function mame_update_ini(opt_mame As MAME_OPTIONS, opt_monitor As MONITOR_OPTIONS) Common As Long
