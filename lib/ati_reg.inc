'==============================================================================
'
'  ATI registry library
'  ati_reg.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function ATI_get_driver_release(ByVal device_key As String, catalyst_release As String, mod_release As String) Common As Long
Declare Function ATI_is_legacy_chipset(ByVal device_key As String) Common As Long
Declare Function ATI_is_low_dotclocks_supported(ByVal device_key As String) Common As Long
Declare Function ATI_clean_registry(ByVal devide_key As String) Common As Long
Declare Function ATI_get_modeline(ByVal video_key As String, m As MODELINE, win_version As Long) Common As Long
Declare Function ATI_set_modeline(ByVal video_key As String, m As MODELINE, win_version As Long, update_mode As Long) Common As Long
Declare Function ATI_get_modeline_list(ByVal target_key As String, m() As MODELINE, win_version As Long) Common As Long
Declare Function ATI_set_modeline_list(ByVal target_key As String, m() As MODELINE, win_version As Long) Common As Long
Declare Function ATI_get_mode_list(video_key As String, reg_key_name As String, m_label() As MODE_LABEL) Common As Long
Declare Function ATI_set_mode_list(video_key As String, reg_key_name As String, m_label() As MODE_LABEL) Common As Long
Declare Function ATI_modeline_to_reg_file(m As MODELINE) Common As String
Declare Function ATI_mode_list_to_reg_file(reg_key_name As String, m_label() As MODE_LABEL) Common As String
Declare Function ATI_edid_emulation_enable(ByVal target_key As String, connector As String, edid As EDID_BLOCK) Common As Long
Declare Function ATI_edid_emulation_disable(ByVal target_key As String, connector As String) Common As Long
Declare Function ATI_edid_emulation_read(ByVal target_key As String, connector As String, edid As EDID_BLOCK) Common As Long
Declare Function ATI_csync_read(ByVal display_name As String) Common As Long
Declare Function ATI_csync_set(ByVal display_name As String, csync As Long) Common As Long
#EndIf
