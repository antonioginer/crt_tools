'===========================================================
'  ATI/AMD ADL helper library
'  by Calamity - 2015-2019
'===========================================================

#If Not %Def(%IS_HOST_APP)
Declare Function ADL_open(driver_release As String) Common As Long
Declare Function ADL_close() Common As Long
Declare Function ADL_enum_connectors_from_adapter(index As Long, connector_label As String) Common As Long
Declare Function ADL_get_modeline_list(target_display As String, m() As MODELINE) Common As Long
Declare Function ADL_set_modeline_list(target_display As String, m() As MODELINE) Common As Long
Declare Function ADL_delete_modeline_list(target_display As String) Common As Long
Declare Function ADL_get_modeline_from_cache(target_display As String, m As MODELINE) Common As Long
Declare Function ADL_get_modeline(target_display As String, m As MODELINE) Common As Long
Declare Function ADL_set_modeline(target_display As String, m As MODELINE, update_mode As Long) Common As Long
Declare Function ADL_csync_read(ByVal target_key As String, ByVal target_display As String) Common As Long
Declare Function ADL_csync_enable(ByVal target_key As String, ByVal target_display As String) Common As Long
Declare Function ADL_csync_disable(ByVal target_key As String, ByVal target_display As String) Common As Long
#EndIf
