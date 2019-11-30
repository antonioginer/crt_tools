'==============================================================================
'
'  EDID library
'  edid.bas
'  Copyright (c) 2008-2017 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "monitor.inc"
#Include "modeline.inc"
#Include "util.inc"
#Include "edid.inc"

Declare Function clog(t As String) Common As Long

'============================================================
'  edid_from_modeline
'============================================================

Function edid_from_modeline(m() As MODELINE, monitor As MONITOR_DEF, edid As EDID_BLOCK, ByVal connector As String) Common As Long

  Dim dtd As DTD_BLOCK Ptr

  ' header
  edid.b(0) = &h00
  edid.b(1) = &hff
  edid.b(2) = &hff
  edid.b(3) = &hff
  edid.b(4) = &hff
  edid.b(5) = &hff
  edid.b(6) = &hff
  edid.b(7) = &h00

  ' Manufacturer ID = "VMM"
  edid.b(8) = &h59 '&h4e
  edid.b(9) = &had '&hf2

  ' Manufacturer product code
  Local pcode As Dword
  pcode = Int(Timer)
  edid.b(10) = Lo(Byte, pcode)
  edid.b(11) = Hi(Byte, pcode)

  ' Serial number
  edid.b(12) = &h00
  edid.b(13) = &h00
  edid.b(14) = &h00
  edid.b(15) = &h00

  ' Week of manufacture
  edid.b(16) = 5

  ' Year of manufacture
  edid.b(17) = 2015 - 1990

  ' EDID version and revision
  edid.b(18) = 1
  edid.b(19) = 3

  ' video params
  edid.b(20) = IIf(connector = $CONNECTOR_VGA, &h6d, &h80)

  ' Maximum H & V size in cm
  edid.b(21) = 48
  edid.b(22) = 36

  ' Gamma
  edid.b(23) = 120

  ' Display features
  edid.b(24) = &h0A

  ' Chromacity coordinates
  edid.b(25) = &h5e
  edid.b(26) = &hc0
  edid.b(27) = &ha4
  edid.b(28) = &h59
  edid.b(29) = &h4a
  edid.b(30) = &h98
  edid.b(31) = &h25
  edid.b(32) = &h20
  edid.b(33) = &h50
  edid.b(34) = &h54

  ' Established timings
  edid.b(35) = &h00
  edid.b(36) = &h00
  edid.b(37) = &h00

  ' Standard timing information
  edid.b(38) = &h01
  edid.b(39) = &h01
  edid.b(40) = &h01
  edid.b(41) = &h01
  edid.b(42) = &h01
  edid.b(43) = &h01
  edid.b(44) = &h01
  edid.b(45) = &h01
  edid.b(46) = &h01
  edid.b(47) = &h01
  edid.b(48) = &h01
  edid.b(49) = &h01
  edid.b(50) = &h01
  edid.b(51) = &h01
  edid.b(52) = &h01
  edid.b(53) = &h01

  ' Descriptor DTD (Detailed Timing Descriptor)
  dtd = VarPtr(edid.b(54))
  If m(0).hactive = 0 Then Exit Function
  dtd_from_modeline(m(0), @dtd)

  ' Descriptor: DTD or monitor serial number
  If m(1).hactive = 0 Then
    Local desc_serial As String Ptr * 18
    desc_serial = VarPtr(edid.b(72))
    @desc_serial = Chr$(0, 0, 0, &hff, 0, "VMMaker 2.0", &h0a)
  Else
    dtd = VarPtr(edid.b(72))
    dtd_from_modeline(m(1), @dtd)
  End If

  ' Descriptor: monitor range limits
  Local desc_range As String Ptr * 18
  desc_range = VarPtr(edid.b(90))
  Local v_freq_min, v_freq_max, h_freq_min, h_freq_max As Long
  edid_get_frequencies_from_preset(monitor, v_freq_min, v_freq_max, h_freq_min, h_freq_max)
  @desc_range = Chr$(0, 0, 0, &hfd, 0, v_freq_min, v_freq_max, Fix(h_freq_min / 1000), Fix(h_freq_max / 1000), &hff, 0, &h0a)

  ' Descriptor: monitor name
  Local desc_name As String Ptr * 18
  desc_name = VarPtr(edid.b(108))
  @desc_name = Chr$(0, 0, 0, &hfc, 0, UCase$(monitor.m_name), &h0a)

  ' EIA/CEA-861 extension blocks
'  If cea_ext_from_modeline(m(),  2, VarPtr(edid.ext1(0))) Then Incr edid.b(126)
'  If cea_ext_from_modeline(m(),  8, VarPtr(edid.ext2(0))) Then Incr edid.b(126)
'  If cea_ext_from_modeline(m(), 14, VarPtr(edid.ext3(0))) Then Incr edid.b(126)

  ' EIA/CEA-861 extension blocks
  If cea_ext_from_modeline(m(),  2, VarPtr(edid.ext1(0)), connector) Then Incr edid.b(126)
  If cea_ext_from_modeline(m(),  8, VarPtr(edid.ext2(0)), "") Then Incr edid.b(126)
  If cea_ext_from_modeline(m(), 14, VarPtr(edid.ext3(0)), "") Then Incr edid.b(126)

  ' Compute checksum
  Local checksum As Byte
  Local i As Long
  For i = 0 To 126
    checksum += edid.b(i)
  Next
  edid.b(127) = 256 - checksum

  ' Return final EDID size
  Function = 128 + 128 * edid.b(126)
End Function

'============================================================
'  dtd_from_modeline
'============================================================

Function dtd_from_modeline(m As MODELINE, dtd As DTD_BLOCK) As Long

  ' Pixel clock in 10 kHz units. (0.-655.35 MHz, little-endian)
  dtd.b(0) = Lo(Byte, (m.pclock / 10000))
  dtd.b(1) = Hi(Byte, (m.pclock / 10000))

  Local h_active, h_blank, h_offset, h_pulse As Word
  Local v_active, v_blank, v_offset, v_pulse As Word
  Local interlace_factor As Long

  h_active = m.hactive
  h_blank  = m.htotal - m.hactive
  h_offset = m.hbegin - m.hactive
  h_pulse  = m.hend - m.hbegin

  interlace_factor = IIf(m.interlace, 2, 1)
  v_active = Int(m.vactive / interlace_factor)
  v_blank  = Int((m.vtotal - m.vactive) / interlace_factor)
  v_offset = Int((m.vbegin - m.vactive) / interlace_factor)
  v_pulse  = Int((m.vend - m.vbegin) / interlace_factor)

  ' Horizontal active pixels 8 lsbits (0-4095)
  dtd.b(2) = Lo(Byte, h_active)

  ' Horizontal blanking pixels 8 lsbits (0-4095)
  dtd.b(3) = Lo(Byte, h_blank)

  ' Bits 7-4 Horizontal active pixels 4 msbits
  ' Bits 3-0 Horizontal blanking pixels 4 msbits
  dtd.b(4) = ((Hi(Byte, h_active) And &h0f) * 16) + (Hi(Byte, h_blank) And &h0f)

  ' Vertical active lines 8 lsbits (0-4095)
  dtd.b(5) = Lo(Byte, v_active)

  ' Vertical blanking lines 8 lsbits (0-4095)
  dtd.b(6) = Lo(Byte, v_blank)

  ' Bits 7-4 Vertical active lines 4 msbits
  ' Bits 3-0 Vertical blanking lines 4 msbits
  dtd.b(7) = ((Hi(Byte, v_active) And &h0f) * 16) + (Hi(Byte, v_blank) And &h0f)

  ' Horizontal sync offset pixels 8 lsbits (0-1023) From blanking start
  dtd.b(8) = Lo(Byte, h_offset)

  ' Horizontal sync pulse width pixels 8 lsbits (0-1023)
  dtd.b(9) = Lo(Byte, h_pulse)

  ' Bits 7-4 Vertical sync offset lines 4 lsbits 0-63)
  ' Bits 3-0 Vertical sync pulse width lines 4 lsbits 0-63)
  dtd.b(10) = ((v_offset And &h0f) * 16) + (v_pulse And &h0f)

  ' Bits 7-6   Horizontal sync offset pixels 2 msbits
  ' Bits 5-4   Horizontal sync pulse width pixels 2 msbits
  ' Bits 3-2   Vertical sync offset lines 2 msbits
  ' Bits 1-0   Vertical sync pulse width lines 2 msbits
  dtd.b(11) = ((Hi(Byte, h_offset) And &h03) * 64) + ((Hi(Byte, h_pulse) And &h03) * 16) + ((Hi(Byte, v_offset) And &h03) * 4) + ((Hi(Byte, v_pulse) And &h03))

  ' Horizontal display size, mm, 8 lsbits (0-4095 mm, 161 in)
  dtd.b(12) = Lo(Byte, 485)

  ' Vertical display size, mm, 8 lsbits (0-4095 mm, 161 in)
  dtd.b(13) = Lo(Byte, 364)

  ' Bits 7-4 Horizontal display size, mm, 4 msbits
  ' Bits 3-0 Vertical display size, mm, 4 msbits
  dtd.b(14) = ((Hi(Byte, 485) And &h0f) * 16) + (Hi(Byte, 364) And &h0f)

  ' Horizontal border pixels (each side; total is twice this)
  dtd.b(15) = 0

  ' Vertical border lines (each side; total is twice this)
  dtd.b(16) = 0

  ' Features bitmap
  dtd.b(17) = ((m.interlace And &h01) * 128) + &h18 + (m.vsync * 4) + (m.hsync * 2)

End Function

'============================================================
'  cea_ext_from_modeline
'============================================================

Function cea_ext_from_modeline(m() As MODELINE, i As Long, cea_ptr As Long, connector As String) As Long

  ' If connector is HDMI, we need space for the tag
  Local dtd_start As Long
  dtd_start = IIf(connector = $CONNECTOR_HDMI, 04 + 08, 04)

  'EIA/CEA-861 extension block
  Dim cea_ext(127) As Byte

  ' Extension tag
  cea_ext(0) = 02

  ' Revision number
  cea_ext(1) = 03

  ' DTDs start
  cea_ext(2) = dtd_start

  ' Number of DTDs
  cea_ext(3) = 0

  ' Add HDMI tag if required
  If connector = $CONNECTOR_HDMI Then
    cea_ext(4) = &h67
    cea_ext(5) = &h03
    cea_ext(6) = &h0C
    cea_ext(7) = &h00
    cea_ext(8) = &h20
    cea_ext(9) = &h00
    cea_ext(10) = &h80
    cea_ext(11) = &h2D
  End If

  Local dtd As DTD_BLOCK Ptr
  dtd = VarPtr(cea_ext(dtd_start))

  ' Add DTDs up to 6 per extension
  Local j As Long
  While m(i + j).hactive <> 0 And j < 6
    dtd_from_modeline(m(i + j), @dtd)
    Incr j
    Incr cea_ext(3)
    dtd += SizeOf(DTD_BLOCK)
  Wend

  ' If we have no DTDs, null byte 2
  If j = 0 Then cea_ext(2) = 0

  ' Compute checksum
  Local checksum As Byte
  Local k As Long
  For k = 0 To 126
    checksum += cea_ext(k)
  Next
  cea_ext(127) = 256 - checksum

  ' Copy back to EDID only if any DTD was added
  If j Or connector = $CONNECTOR_HDMI Then
    Dim new_ext(127) As Byte At cea_ptr
    Poke$ VarPtr(new_ext(0)), Peek$(VarPtr(cea_ext(0)), 128)
    Function = 1
  End If

End Function

'============================================================
'  edid_get_monitor_name
'============================================================

Function edid_get_monitor_name(edid As EDID_BLOCK) Common As String

  Local edid_str As String Ptr * 128
  edid_str = VarPtr(edid)

  Function = Mid$(@edid_str, 109 + 5, 18 - 5)
End Function

'============================================================
'  edid_to_file
'============================================================

Function edid_to_file(edid As EDID_BLOCK, file_name As String) Common As String

  Local edid_str As String Ptr * 512
  edid_str = VarPtr(edid)

  If file_exists(file_name) Then Kill file_name

  Local a As Long
  a = FreeFile
  Open file_name For Binary As a
  Put$ a, Left$(@edid_str, 128 + 128 * edid.b(126))
  Close a

End Function

'============================================================
'  edid_get_frequencies_from_preset
'============================================================

Function edid_get_frequencies_from_preset(m As MONITOR_DEF, v_freq_min As Long, v_freq_max As Long, h_freq_min As Long, h_freq_max As Long) As Long

  h_freq_min = %HFREQ_MAX
  v_freq_min = %VFREQ_MAX

  Local i, f As Long
  For i = 0 To %MAX_RANGES
    f = Int(m.m_range(i).v_freq_min) : If f And f < v_freq_min Then v_freq_min = f
    f = Int(m.m_range(i).v_freq_max) : If f And f > v_freq_max Then v_freq_max = f
    f = Int(m.m_range(i).h_freq_min) : If f And f < h_freq_min Then h_freq_min = f
    f = Int(m.m_range(i).h_freq_max) : If f And f > h_freq_max Then h_freq_max = f
  Next

End Function

'============================================================
'  edid_get_default_options
'============================================================

Function edid_get_default_options(options As EDID_OPTIONS) Common As Long

  options.from_modelist = 0

End Function
