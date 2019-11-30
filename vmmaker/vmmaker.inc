'==============================================================================
'
'  VideoModeMaker
'  VMMaker.inc
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

#Include "..\lib\monitor.inc"
#Include "..\lib\modeline.inc"
#Include "..\lib\edid.inc"
#Include "..\lib\display.inc"
#Include "..\lib\custom_video.inc
#Include "..\lib\ati_reg.inc"
#Include "..\lib\log_console.inc"
#Include "..\lib\command_line.inc"
#Include "..\lib\util.inc"

#Include "ati_inf.inc"
#Include "command_vmm.inc"
#Include "mode_db.inc"
#Include "user.inc"
#Include "mame.inc"
#Include "version.inc"


'============================================================
'  Constants
'============================================================

$APP_LOGO = "  _____ _____ _____     _           " + $CrLf +_
            " |  |  |     |     |___| |_ ___ ___ " + $CrLf +_
            " |  |  | | | | | | | .'| '_| -_|  _|" + $CrLf +_
            "  \___/|_|_|_|_|_|_|__,|_,_|___|_|  "
$APP_NAME = "Video Mode Maker " + $APP_VERSION
$APP_COPYRIGHT = "by Calamity - 2008/2019"
%APP_DATA = 1
%IDR_ICON = 1001

%RestrictedModes = 128
%PriorityLevels = 10

'============================================================
'  Types
'============================================================

Type APP_OPTIONS
  display As DISPLAY_OPTIONS
  custom_video As CUSTOM_VIDEO_OPTIONS
  modeline As MODELINE_OPTIONS
  monitor As MONITOR_OPTIONS
  edid As EDID_OPTIONS
  mode_db As MODE_DB_OPTIONS
  inf As INF_OPTIONS
  user As USER_OPTIONS
  mame As MAME_OPTIONS
End Type

Type APP_DATA
  options As APP_OPTIONS
  mdb As Long Ptr
  h_gui As Long
  h_wt_event As Long
  win_version As Long
  driver_compatible As Long
  command As AsciiZ * 256
End Type

Macro CObj(pUnk, dwAddr)
  Poke Dword, VarPtr(pUnk), dwAddr
  pUnk.AddRef()
End Macro

'============================================================
'  Functions
'============================================================

Declare Function vmm_launch_command(vmm As app_data) Common As Long
