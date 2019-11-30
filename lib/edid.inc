'==============================================================================
'
'  EDID library
'  edid.inc
'  Copyright (c) 2008-2014 Antonio Giner González
'
'==============================================================================

#Include Once "monitor.inc"
#Include Once "modeline.inc"

'============================================================
'  Types
'============================================================

Type EDID_BLOCK
  b(127) As Byte
  ext1(127) As Byte
  ext2(127) As Byte
  ext3(127) As Byte
End Type

Type DTD_BLOCK
  b(17) As Byte
End Type

Type EDID_OPTIONS
  from_modelist As Long
End Type


'============================================================
'  Types
'============================================================

$CONNECTOR_VGA      = "vga"
$CONNECTOR_DVI_D    = "dvi"
$CONNECTOR_HDMI     = "hdmi"

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function edid_from_modeline(m() As MODELINE, monitor As MONITOR_DEF, edid As EDID_BLOCK, ByVal connector As String) Common As Long
Declare Function edid_get_monitor_name(edid As EDID_BLOCK) Common As String
Declare Function edid_to_file(edid As EDID_BLOCK, file_name As String) Common As String
#EndIf
