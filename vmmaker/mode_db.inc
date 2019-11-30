'==============================================================================
'
'  Mode database
'  mode_db.inc
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

%XML_LIST = 0
%CUSTOM_LIST = 1

%STATIC_LIST = 0
%DYNAMIC_LIST = 1
%MAGIC_LIST = 2

%NUMBER_OF_MODES = 1024

%PRIORITY_LOW = 0
%PRIORITY_HIGH = 1

'============================================================
'  Types
'============================================================

Type MODE_DB_OPTIONS
  total_modes As AsciiZ * 8
  mode_table_method_user As Long
  mode_table_method_xml As Long
  x_res_min_xml As Long
  y_res_min_xml As Long
  y_res_round_xml As Long
  x_res_min_user As Long
  y_res_min_user As Long
  y_res_round_user As Long
End Type

Type MODE_DB_NODE
  next As Long
  prev As Long
  active As Long
  priority As Long
  count As Long
  modeline As Long Ptr
End Type

Type NATIVE_MODE
  width As Long
  height As Long
  refresh As Double
  rotation As Long
  gcount As Long
  label As String * 256
  p_mt As Long Ptr
  priority As Long
  source As Long
  result As Long
  nextresult As Long
End Type

'============================================================
'  Interfaces
'============================================================

#If Not %Def(%IS_HOST_APP)
Interface imode_db
  Inherit IUnknown
  Property Get mode_count() As Long
  Method initialize()
  Method resize()
  Method register_mode(xres As Long, yres As Long, vfreq As Double, rotation As Long, priority_level As Long, source_type As Long, source_label As String) As Long
  Method native_sort_by_xyv() As Long
  Method mode_table_sort_by_xy() As Long
  Method mode_table_get_count() As Long
  Method mode_table_build(opt_mon As MONITOR_OPTIONS, opt_db As MODE_DB_OPTIONS, opt_mdl As MODELINE_OPTIONS) As Long
  Method mode_table_import_modes(ByVal m As MODELINE Ptr) As Long
  Method get_modeline_ptr_from_index(index As Long) As Long
  Method del_modeline_by_index(index As Long, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long
  Method mode_list_output(opt_mon As MONITOR_OPTIONS, opt_mdl As MODELINE_OPTIONS, file_name As String) As Long
  Method get_modeline_list(ByVal m As MODELINE Ptr) As Long
  Method mode_table_disambiguation() As Long
  Method get_label(ByVal m As MODE_DB_NODE Ptr) As String
  Method global_result(opt_mon As MONITOR_OPTIONS, opt_mdl As MODELINE_OPTIONS) As mode_result
  Method mode_table_reduce(ByVal monitor As MONITOR_DEF Ptr, opt_db As MODE_DB_OPTIONS, opt_mdl As MODELINE_OPTIONS) As Long
  Method get_first_node() As Long
  Method set_first_node(ByVal m As MODE_DB_NODE Ptr)
  Method is_first_node(ByVal m As MODE_DB_NODE Ptr) As Long
  Method insert_node(m As MODELINE) As Long
  Method delete_node(ByVal n As MODE_DB_NODE Ptr, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long
  Method compute_score() As Long
  Method get_best_mode(ByVal r As NATIVE_MODE Ptr, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long
End Interface
#EndIf
