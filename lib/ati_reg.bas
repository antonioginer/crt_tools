'==============================================================================
'
'  ATI registry library
'  ati_reg.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include Once "win32api.inc"
#Include "modeline.inc"
#Include "edid.inc"
#Include "display.inc"
#Include "util.inc"
#Include "log_console.inc"
#Include "radeon_family.inc"

%MAX_NUMBER_OF_MODES = 1024

%CRTC_DOUBLE_SCAN     = &h0001
%CRTC_INTERLACED      = &h0002
%CRTC_H_SYNC_POLARITY = &h0004
%CRTC_V_SYNC_POLARITY = &h0008

'============================================================
'  ATI_get_driver_release
'============================================================

Function ATI_get_driver_release(ByVal device_key As String, cat_release As String, mod_release As String) Common As Long

  mod_release = Trim$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "CalamityRelease", %REG_SZ), Any " " + Chr$(0))
  cat_release = Trim$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "Catalyst_Version", %REG_SZ), Any " " + Chr$(0))
  If cat_release = "" Then cat_release = Trim$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "RadeonSoftwareVersion", %REG_SZ), Any " " + Chr$(0))

  If cat_release = "" Then
    Local device_id As String
    Local vendor_id As Word
    device_id = Trim$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "MatchingDeviceId", %REG_SZ), Any " " + Chr$(0))
    vendor_id = Val("&h0" + Mid$(device_id, 9, 4))
    If vendor_id = &h1002 Then cat_release = Trim$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "DriverVersion", %REG_SZ), Any " " + Chr$(0))
  End If

  If cat_release <> "" Then cat_release = Using$("&.&", Parse$(cat_release, ".", 1), Parse$(cat_release, ".", 2))

  If cat_release <> "" Or mod_release <> "" Then Function = 1
End Function

'============================================================
'  ATI_is_legacy_chipset
'============================================================

Function ATI_is_legacy_chipset(ByVal device_key As String) Common As Long

  Local pci_id As Long
  pci_id = Val("&h" + Mid$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "MatchingDeviceId", %REG_SZ), 18, 4))
  If pci_id Then
    Function =  IsFalse ASIC_IS_DCE4(radeon_family(pci_id))
  Else
    'Windows XP, assume it's legacy
    Function = 1
  End If
End Function

'============================================================
'  ATI_is_low_dotclocks_supported
'============================================================

Function ATI_is_low_dotclocks_supported(ByVal device_key As String) Common As Long

  Local pci_id As Long
  pci_id = Val("&h" + Mid$(get_reg(%HKEY_LOCAL_MACHINE, device_key, "MatchingDeviceId", %REG_SZ), 18, 4))
  If pci_id Then
    Function =  LOW_DOTCLOCKS_SUPPORTED(radeon_family(pci_id))
  Else
    'Windows XP, assume it's legacy
    Function = 1
  End If
End Function

'============================================================
'  ATI_clean_registry
'============================================================

Function ATI_clean_registry(ByVal device_key As String) Common As Long

  Local hKey As Dword
  Local dwIndex As Dword
  Local lpValueName As AsciiZ * 1024
  Local lpcValueName As Dword
  Local SubKey As String
  Local KeyIndex As Dword

  Dim RegValue (1024) As String

  lpcValueName = SizeOf(lpValueName)

  If RegOpenKeyEx(%HKEY_LOCAL_MACHINE, Trim$(device_key, "\"), ByVal %Null, %KEY_ALL_ACCESS, hKey) = %ERROR_SUCCESS Then

    While RegEnumValue (hKey, dwIndex, lpValueName, lpcValueName, ByVal %Null, ByVal %Null, ByVal %Null, ByVal %Null) = %ERROR_SUCCESS

      lpcValueName = SizeOf (lpValueName)
      Incr dwIndex

      If InStr (lpValueName, "DALDTMCRTBCD") Or _
         InStr (lpValueName, "DALDTMDFPBCD") Or _
         InStr (lpValueName, "DALNonStandardModesBCD") Or _
         InStr (lpValueName, "DALRestrictedModesBCD") Or _
         (InStr (lpValueName, "DALR6 CRT") And Len(lpValueName) > 10) Then

        Incr KeyIndex
        RegValue (KeyIndex) = lpValueName
      End If

    Wend

    While KeyIndex <> 0
      lpValueName = RegValue (KeyIndex)
      If RegDeleteValue (hKey, lpValueName) <> %ERROR_SUCCESS Then clog "ATI_clean_registry: Error deleting " + lpValueName
      Decr KeyIndex
    Wend

    RegCloseKey hKey
    Function = 1

  End If

End Function

'============================================================
'  ATI_get_modeline
'============================================================

Function ATI_get_modeline(ByVal video_key As String, m As MODELINE, win_version As Long) Common As Long

  Local hKey As Long
  Local interlace As Long
  Local key_name As String
  Local key_data As String
  Local refresh_label As Long

  refresh_label = IIf(m.refresh_label, m.refresh_label, m.refresh * IIf((win_version <= 5 Or m.interlace = -1) Or IsFalse m.interlace, 1, 2))
  key_name = Using$ ("DALDTMCRTBCD#X#X0X#", m.width, m.height, refresh_label)
  key_data = get_reg (%HKEY_LOCAL_MACHINE, video_key, key_name, %REG_BINARY)

  ' W7: we need to check for the case when the interlaced refresh is an uneven integer
  If key_data = "" And m.interlace And win_version > 5 Then
    refresh_label += 1
    key_name = Using$ ("DALDTMCRTBCD#X#X0X#", m.width, m.height, refresh_label)
    key_data = get_reg (%HKEY_LOCAL_MACHINE, video_key, key_name, %REG_BINARY)
  End If

  If key_data = "" Then Exit Function

  interlace = IIf((get_DWORD_BE(key_data, 0) And %CRTC_INTERLACED), 1, 0)
  If (win_version <= 5 Or m.interlace = -1) Or (interlace = m.interlace) Then
    m.refresh_label = refresh_label
    m.interlace = interlace
    m.hsync   = IIf((get_DWORD_BE(key_data, 0) And %CRTC_H_SYNC_POLARITY), 0, 1)
    m.vsync   = IIf((get_DWORD_BE(key_data, 0) And %CRTC_H_SYNC_POLARITY), 0, 1)
    m.pclock  = get_DWORD_BCD(key_data, 36) * 10 * 1000 '10kHz -> Hz
    m.hactive = get_DWORD_BCD(key_data,  8)
    m.hbegin  = get_DWORD_BCD(key_data, 12)
    m.hend    = get_DWORD_BCD(key_data, 16) + m.hbegin
    m.htotal  = get_DWORD_BCD(key_data,  4)
    m.vactive = get_DWORD_BCD(key_data, 24)
    m.vbegin  = get_DWORD_BCD(key_data, 28)
    m.vend    = get_DWORD_BCD(key_data, 32) + m.vbegin
    m.vtotal  = get_DWORD_BCD(key_data, 20)
    m.hfreq   = m.pclock / m.htotal
    m.vfreq   = m.hfreq / m.vtotal * IIf(m.interlace, 2, 1)
    Function = 1
  End If

End Function

'============================================================
'  ATI_set_modeline
'============================================================

Function ATI_set_modeline(ByVal video_key As String, m As MODELINE, win_version As Long, update_mode As Long) Common As Long

  Local Flags, CheckSum As Long
  Local key_name As String
  Local key_data As String
  Local i As Long
  Local a As String
  Local refresh_label As Long

  refresh_label = IIf(m.refresh_label, m.refresh_label, m.refresh * IIf(win_version <= 5 Or IsFalse m.interlace, 1, 2))
  key_name = Using$("DALDTMCRTBCD#X#X0X#", m.width, m.height, refresh_label)
  ' W7: we need to check for the case when the interlaced refresh is an uneven integer
  If (update_mode And %MODELINE_UPDATE) And get_reg (%HKEY_LOCAL_MACHINE, video_key, key_name, %REG_BINARY) = "" And m.interlace And win_version > 5 Then
    refresh_label += 1
    key_name = Using$ ("DALDTMCRTBCD#X#X0X#", m.width, m.height, refresh_label)
    If get_reg (%HKEY_LOCAL_MACHINE, video_key, key_name, %REG_BINARY) = "" Then Exit Function
  End If

  key_data = String$(68, Chr$(0))
  set_DWORD_BCD(key_data, m.pclock / (10 * 1000), 36) 'Hz -> 10kHz
  set_DWORD_BCD(key_data, m.hactive, 8)
  set_DWORD_BCD(key_data, m.hbegin, 12)
  set_DWORD_BCD(key_data, m.hend - m.hbegin, 16)
  set_DWORD_BCD(key_data, m.htotal, 4)
  set_DWORD_BCD(key_data, m.vactive, 24)
  set_DWORD_BCD(key_data, m.vbegin, 28)
  set_DWORD_BCD(key_data, m.vend - m.vbegin, 32)
  set_DWORD_BCD(key_data, m.vtotal, 20)

  Flags = IIf(m.interlace, %CRTC_INTERLACED, 0) Or IIf(m.hsync, 0, %CRTC_H_SYNC_POLARITY) Or IIf(m.vsync, 0, %CRTC_V_SYNC_POLARITY)
  set_DWORD_BE(key_data, Flags, 0)

  CheckSum = 65535 - Flags - m.htotal - m.hactive - m.hend - m.vtotal - m.vactive - m.vend - m.pclock / (10 * 1000)
  set_DWORD_BE(key_data, Checksum, 64)

  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, video_key, key_name, %REG_BINARY, key_data) Then Exit Function

  Function = 1
End Function

'============================================================
'  ATI_get_modeline_list
'============================================================

Function ATI_get_modeline_list(ByVal target_key As String, m() As MODELINE, win_version As Long) Common As Long

  Local i, j As Long
  Local m As MODELINE
  Dim m_label(%MAX_NUMBER_OF_MODES) As MODE_LABEL

  ATI_get_mode_list(target_key, "DALNonStandardModesBCD", m_label())

  While m_label(i).width
    m.width = m_label(i).width
    m.height = m_label(i).height
    m.refresh = m_label(i).refresh
    m.refresh_label = 0
    m.interlace = -1 ' = unknown
    If ATI_get_modeline(target_key, m, win_version) Then
      m.refresh /= IIf(win_version <= 5 Or IsFalse m.interlace, 1, 2)
      m(j) = m
      Incr j
    End If
    Incr i
  Wend

  Function = j
End Function

'============================================================
'  ATI_set_modeline_list
'============================================================

Function ATI_set_modeline_list(ByVal target_key As String, m() As MODELINE, win_version As Long) Common As Long

  Local i As Long
  Dim m_label(%MAX_NUMBER_OF_MODES) As MODE_LABEL

  ATI_clean_registry(target_key)

  While m(i).width
    ATI_set_modeline(target_key, m(i), win_version, %MODELINE_CREATE)
    m_label(i).width = m(i).width
    m_label(i).height = m(i).height
    m_label(i).refresh = m(i).refresh
    m_label(i).refresh_label = m(i).refresh * IIf(win_version <= 5 Or IsFalse m(i).interlace, 1, 2)
    m_label(i).bpp = 0 '32
    Incr i
  Wend

  Function = ATI_set_mode_list(target_key, "DALNonStandardModesBCD", m_label())

  ' Only add restricted mode list in Windows XP
  If win_version <= 5 Then
    Reset m_label()
    Local j As Long
    For i = 1 To DataCount Step 2
      m_label(j).width = Val(Read$(i))
      m_label(j).height = Val(Read$(i + 1))
      Incr j
    Next
    ATI_set_mode_list(target_key, "DALRestrictedModesBCD", m_label())

    Data 320,200, 320,240, 400,300, 512,384, 640,400, 640,480, 720,480, 800,600, 1024,768, 1152,864, 1280,720, 1280,1024
    Data 1600,1200, 1792,1344, 1800,1440, 1920,1080, 1920,1200, 1920,1440, 2048,1536, 0,0
  End If

End Function

'============================================================
'  ATI_get_mode_list
'============================================================

Function ATI_get_mode_list(video_key As String, reg_key_name As String, m_label() As MODE_LABEL) Common As Long

  Local i, key_index, current_pos As Long
  Local key_data, new_data As String
  Local current_key As String

  Do
    key_data = get_reg(%HKEY_LOCAL_MACHINE, video_key, reg_key_name + IIf$(key_index, Using$("#", key_index), ""), %REG_BINARY)
    If key_data = "" Then Exit Loop
    current_pos = 1

    Do
      new_data = Mid$(key_data, current_pos, 8)
      If Len(new_data) <> 8 Then Exit Loop
      current_pos += 8
      m_label(i).width = get_WORD_BCD(new_data, 0)
      m_label(i).height = get_WORD_BCD(new_data, 2)
      m_label(i).bpp = get_WORD_BCD(new_data, 4)
      m_label(i).refresh = get_WORD_BCD(new_data, 6)
      m_label(i).refresh_label = m_label(i).refresh
      Incr i
    Loop
    Incr key_index
  Loop

  Function = i
End Function

'============================================================
'  ATI_set_mode_list
'============================================================

Function ATI_set_mode_list(video_key As String, reg_key_name As String, m_label() As MODE_LABEL) Common As Long

  Local i, key_index As Long
  Local key_data, new_data As String
  Local current_key As String

  While m_label(i).width
    Do
      new_data = String$(8, Chr$(0))
      set_WORD_BCD(new_data, m_label(i).width, 0)
      set_WORD_BCD(new_data, m_label(i).height, 2)
      set_WORD_BCD(new_data, IIf(m_label(i).bpp, m_label(i).bpp, 0), 4)
      set_WORD_BCD(new_data, m_label(i).refresh_label, 6)
      key_data = key_data + new_data
      Incr i
    Loop While m_label(i).width And i Mod 20

    current_key = reg_key_name + IIf$(key_index, Using$("#", key_index), "")
    If IsFalse set_reg(%HKEY_LOCAL_MACHINE, video_key, current_key, %REG_BINARY, key_data) Then Exit Function
    key_data = ""
    Incr key_index
  Wend

  Function = i
End Function

'============================================================
'  ATI_edid_emulation_enable
'============================================================

Function ATI_edid_emulation_enable(ByVal target_key As String, connector As String, edid As EDID_BLOCK) Common As Long

  Local edid_str As String Ptr * 512
  edid_str = VarPtr(edid)

  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, Remove$(target_key, "\Registry\Machine"), edid_key_from_connector(connector), %REG_BINARY, @edid_str + "") Then Exit Function

  Function = 1
End Function

'============================================================
'  ATI_edid_emulation_disable
'============================================================

Function ATI_edid_emulation_disable(ByVal target_key As String, connector As String) Common As Long

  Local h_key As Long
  If RegOpenKeyEx(%HKEY_LOCAL_MACHINE, Trim$(target_key, "\"), ByVal %Null, %KEY_ALL_ACCESS, h_key) <> %ERROR_SUCCESS Then Exit Function
  If RegDeleteValue(h_key, edid_key_from_connector(connector)) <> %ERROR_SUCCESS Then Exit Function

  Function = 1
End Function

'============================================================
'  ATI_edid_emulation_read
'============================================================

Function ATI_edid_emulation_read(ByVal target_key As String, connector As String, edid As EDID_BLOCK) Common As Long

  Local edid_str_ptr As String Ptr * 128
  Local edid_str As String

  edid_str = get_reg(%HKEY_LOCAL_MACHINE, target_key, edid_key_from_connector(connector), %REG_BINARY)
  If edid_str <> "" Then
    edid_str_ptr = VarPtr(edid)
    @edid_str_ptr = edid_str
    Function = 1
  End If
End Function

'============================================================
'  edid_key_from_connector
'============================================================

Function edid_key_from_connector(connector As String) As String

  Local conn_label As String
  conn_label = Left$(connector, 1) + Parse$(connector, "_", 2)

  Function = "DALEmulatedEDID_" + conn_label
End Function

'============================================================
'  ATI_csync_read
'============================================================

Function ATI_csync_read(ByVal display_name As String) Common As Long

  Local device_key, master_key, crt_key As String
  device_key = display_get_device_key(display_name)
  master_key = display_get_master_device_key(display_name)
  crt_key = "DALR6 CRT" + IIf$(Right$(device_key, 1) = "1", "2", "")

  Local dalr6_crt As String
  dalr6_crt = get_reg(%HKEY_LOCAL_MACHINE, master_key, crt_key, %REG_BINARY)
  If Len(dalr6_crt) Then Function = get_BYTE(dalr6_crt, &h50)
End Function

'============================================================
'  ATI_csync_set
'============================================================

Function ATI_csync_set(ByVal display_name As String, csync As Long) Common As Long

  Local device_key, master_key, crt_key As String
  device_key = display_get_device_key(display_name)
  master_key = display_get_master_device_key(display_name)
  crt_key = "DALR6 CRT" + IIf$(Right$(device_key, 1) = "1", "2", "")

  Local allow_adj As String
  allow_adj = Chr$((csync Xor 1), 0, 0, 0)
  set_reg(%HKEY_LOCAL_MACHINE, master_key, "GXOCRTDisablecompositeSyncAdj", %REG_DWORD, allow_adj)
  set_reg(%HKEY_LOCAL_MACHINE, master_key, "GXOCRTDisableHorizontalSyncAdj", %REG_DWORD, allow_adj)
  set_reg(%HKEY_LOCAL_MACHINE, master_key, "GXOCRTDisableVerticalSyncAdj", %REG_DWORD, allow_adj)

  Local dalr6_crt As String
  dalr6_crt = get_reg(%HKEY_LOCAL_MACHINE, master_key, crt_key, %REG_BINARY)
  If Len(dalr6_crt) = 0 Then dalr6_crt = Nul$(128)

  set_BYTE(dalr6_crt, (csync Xor 1), &h48)
  set_BYTE(dalr6_crt, (csync Xor 1), &h4c)
  set_BYTE(dalr6_crt, csync, &h50)
  Function = set_reg(%HKEY_LOCAL_MACHINE, master_key, crt_key, %REG_BINARY, dalr6_crt)

End Function

'============================================================
'  get_BYTE / set_BYTE
'============================================================

Function get_BYTE(data_string As String, offset As Long) As Long
  Function = Asc(Mid$ (data_string, offset + 1, 1))
End Function

Sub set_BYTE(data_string As String, DataByte As Long, offset As Long)

  If DataByte < 256 Then
    Mid$ (data_string, offset + 1) = Chr$ (DataByte)
  End If
End Sub

'============================================================
'  get_WORD / set_WORD
'============================================================

Function get_WORD(data_string As String, offset As Long) As Long
  Function =  Asc(Mid$ (data_string, offset + 1, 1)) + Asc(Mid$ (data_string, offset + 2, 1)) * 256
End Function

Sub set_WORD(data_string As String, data_word As Long, offset As Long)

  Local data_low, data_high As Long

  If data_word < 65536 Then
    data_low = data_word Mod 256
    data_high = Int (data_word / 256)
    Mid$(data_string, offset + 2) = Chr$(data_high)
    Mid$(data_string, offset + 1) = Chr$(data_low)
  End If
End Sub

'============================================================
'  get_WORD_BCD / set_WORD_BCD
'============================================================

Function get_WORD_BCD(data_string As String, offset As Long) As Long
  Function =  Val(Hex$(Asc(Mid$(data_string, offset + 1, 1)), 2) + Hex$(Asc(Mid$(data_string, offset + 2, 1)), 2))
End Function

Sub set_WORD_BCD(data_string As String, data_word As Long, offset As Long)

  Local data_low, data_high As Long

  If data_word < 10000 Then
    data_low = data_word Mod 100
    data_high = Int(data_word / 100)
    Mid$(data_string, offset + 1) = Chr$(Val("&h" + LTrim$(Str$(data_high))))
    Mid$(data_string, offset + 2) = Chr$(Val("&h" + LTrim$(Str$(data_low))))
  End If
End Sub

'============================================================
'  get_DWORD_BCD / set_DWORD_BE
'============================================================

Function get_DWORD_BCD(data_string As String, offset As Long) As Long

  Local data_DWORD_BCD As String * 4
  Local data_ps As String Ptr * 4
  Local data_pd As Dword Ptr

  data_ps = VarPtr(data_DWORD_BCD)
  data_pd = data_ps
  @data_ps = StrReverse$(Mid$(data_string, offset + 1, 4))

  Function = Val(Hex$(@data_pd))
End Function

Sub set_DWORD_BCD(data_string As String, data_dword As Long, offset As Long)

  Local data_DWORD_BCD As String
  data_DWORD_BCD = Format$(data_dword, "00000000")

  Mid$(data_string, offset + 1) = Chr$(Val("&h" + Mid$(data_DWORD_BCD, 1, 2)))
  Mid$(data_string, offset + 2) = Chr$(Val("&h" + Mid$(data_DWORD_BCD, 3, 2)))
  Mid$(data_string, offset + 3) = Chr$(Val("&h" + Mid$(data_DWORD_BCD, 5, 2)))
  Mid$(data_string, offset + 4) = Chr$(Val("&h" + Mid$(data_DWORD_BCD, 7, 2)))
End Sub

'============================================================
'  get_DWORD_BE / set_DWORD_BE
'============================================================

Function get_DWORD_BE(data_string As String, offset As Long) As Long

  Local data_DWORD_BE As String * 4
  Local data_ps As String Ptr * 4
  Local data_pd As Dword Ptr

  data_ps = VarPtr(data_DWORD_BE)
  data_pd = data_ps
  @data_ps = StrReverse$(Mid$(data_string, offset + 1, 4))

  Function = Val("&h" + Hex$(@data_pd))
End Function

Sub set_DWORD_BE(data_string As String, data_dword As Long, offset As Long)

  Local data_DWORD_BE As String * 4
  Local data_ps As String Ptr * 4
  Local data_pd As Dword Ptr

  data_ps = VarPtr(data_DWORD_BE)
  data_pd = data_ps
  @data_pd = data_dword

  Mid$(data_string, offset + 1) = StrReverse$(@data_ps)
End Sub

'============================================================
'  WORD_to_txt
'============================================================

Function WORD_to_txt(a As Long) As String

  Local n As String
  n = Space$(4)
  RSet n = Using$("#", a) Using "0"
  Function = StrInsert$ (n , ",", 3)
End Function

'============================================================
'  HEX_to_txt
'============================================================

Function HEX_WORD_to_txt (a As Long) As String
  Function = StrInsert$ (Right$ (Hex$ (a), 4), ",", 3)
End Function
