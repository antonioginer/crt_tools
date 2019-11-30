'==============================================================================
'
'  Mode database
'  mode_db.bas
'  Copyright (c) 2008-2014 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Include "monitor.inc"
#Include "modeline.inc"
#Include "edid.inc"
#Include "custom_video.inc"
#Include "util.inc"
#Include "log_console.inc"
#Include "mode_db.inc"

'============================================================
'  mode_db_get_default_options
'============================================================

Function mode_db_get_default_options(options As MODE_DB_OPTIONS) Common As Long

  options.total_modes = "auto"
  options.mode_table_method_user = 0
  options.mode_table_method_xml = 1
  options.x_res_min_xml = 240
  options.y_res_min_xml = 240
  options.y_res_round_xml = 16
  options.x_res_min_user = 240
  options.y_res_min_user = 192
  options.y_res_round_user = 1

End Function

'============================================================
'  class mode_db
'============================================================

Class mode_db Common

  Instance vmode() As MODELINE
  Instance native() As NATIVE_MODE
  Instance m_table() As MODE_DB_NODE
  Instance m_table As MODE_DB_NODE Ptr

  Instance native_count As Long
  Instance mode_count As Long

  Class Method Create()
    Dim vmode(%NUMBER_OF_MODES)
    Dim native(%NUMBER_OF_MODES)
    Dim m_table(%NUMBER_OF_MODES)
    m_table = VarPtr(m_table(0))
  End Method

'============================================================
'  Interface imode_db
'  Inherit IUnknown
'  Property Get mode_count() As Long
'  Method initialize()
'  Method register_mode(xres As Long, yres As Long, vfreq As Double, rotation As Long, priority_level As Long, source_type As Long, source_label As String) As Long
'  Method native_sort_by_xyv() As Long
'  Method mode_table_sort_by_xy() As Long
'  Method mode_table_get_count() As Long
'  Method mode_table_build(opt_mon As MONITOR_OPTIONS, opt_db As MODE_DB_OPTIONS, opt_mdl As MODELINE_OPTIONS) As Long
'  Method mode_table_import_modes(ByVal m As MODELINE Ptr) As Long
'  Method get_modeline_ptr_from_index(index As Long) As Long
'  Method del_modeline_by_index(index As Long, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long
'  Method mode_list_output(opt_mon As MONITOR_OPTIONS, opt_mdl As MODELINE_OPTIONS, file_name As String) As Long
'  Method get_modeline_list(ByVal m As MODELINE Ptr) As Long
'  Method mode_table_disambiguation() As Long
'  Method get_label(ByVal m As MODE_DB_NODE Ptr) As String
'  Method global_result(opt_mon As MONITOR_OPTIONS, opt_mdl As MODELINE_OPTIONS) As mode_result
'  Method mode_table_reduce(ByVal monitor As MONITOR_DEF Ptr, opt_db As MODE_DB_OPTIONS, opt_mdl As MODELINE_OPTIONS) As Long
'  Method insert_node(m As MODELINE) As Long
'  Method delete_node(ByVal n As MODE_DB_NODE Ptr, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long
'  Method compute_score() As Long
'  Method get_best_mode(ByVal r As NATIVE_MODE Ptr, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long
'============================================================

Interface IMODE_DB : Inherit IUnknown

'============================================================
'  Properties
'============================================================

Property Get mode_count() As Long
 Property = mode_count
End Property

'============================================================
'  Methods
'============================================================

'============================================================
'  mode_db::initialize
'============================================================

Method initialize()
    Reset vmode()
    Reset native()
    Reset m_table()
    Reset native_count
    Reset mode_count
    me.set_first_node(VarPtr(m_table(0)))
End Method

'============================================================
'  mode_db::resize
'============================================================

Method resize()
  ReDim Preserve vmode(UBound(vmode()) + %NUMBER_OF_MODES)
  ReDim Preserve native(UBound(native()) + %NUMBER_OF_MODES)
  ReDim Preserve m_table(UBound(m_table()) + %NUMBER_OF_MODES)
  me.set_first_node(VarPtr(m_table(0)))
End Method

'============================================================
'  mode_db::register_mode
'============================================================

Method register_mode(xres As Long, yres As Long, vfreq As Double, rotation As Long, priority_level As Long, source_type As Long, source_label As String) As Long

  Local i, found As Long

  i = 0 : found = -1
  While native(i).width
    If xres = native(i).width And yres = native(i).height And vfreq = native(i).refresh And rotation = native(i).rotation Then found = i : Exit Loop
    Incr i
  Wend

  If found = -1 Then
    native(i).width = xres
    native(i).height = yres
    native(i).refresh = vfreq
    native(i).rotation = rotation
    native(i).priority = priority_level
    native(i).source = source_type
    native(i).label = source_label
    Incr native(i).gcount
    Incr native_count
    If native_count = UBound(native()) Then me.resize()
    clog Using$ ("##### video modes found", native_count) + ";"
    Method = 1
  Else
    native(found).priority += priority_level
    Incr native(found).gcount
    If priority_level Then native(found).label = RTrim$(native(found).label) + "/" + source_label
    Method = 0
  End If
End Method

'============================================================
'  mode_db::native_order_by_xyv
'============================================================

Method native_sort_by_xyv() As Long

  Local i, j As Long

  For i = 0 To native_count - 1
    For j = i To native_count - 1
      If native(j).width < native(i).width Or _
        (native(j).width = native(i).width And native(j).height < native(i).height) Or _
        (native(j).width = native(i).width And native(j).height = native(i).height And native(j).refresh < native(i).refresh) Or _
        (native(j).width = native(i).width And native(j).height = native(i).height And native(j).refresh = native(i).refresh And native(j).rotation < native(i).rotation) Then
        Swap native(i), native(j)
      End If
    Next
  Next

End Method

'============================================================
'  mode_db::mode_table_order_by_xy
'============================================================

Method mode_table_sort_by_xy() As Long

  Local mt, i, j, pi, ni, pj, nj As MODE_DB_NODE Ptr
  Local k, m As MODELINE Ptr

  mt = me.get_first_node()
  i = mt
  Do
    j = i
    Do
      k = @i.modeline
      m = @j.modeline
      If @m.width < @k.width Or _
        (@m.width = @k.width And @m.height < @k.height) Or _
        (@m.width = @k.width And @m.height = @k.height And @m.refresh < @k.refresh ) Then
        pi = @i.prev : ni = @i.next
        pj = @j.prev : nj = @j.next
        If pi Then @pi.next = j Else me.set_first_node(j)
        If nj Then @nj.prev = i
        If ni Then @ni.prev = j
        If pj Then @pj.next = i
        Swap @i.prev, @j.prev
        Swap @i.next, @j.next
        Swap i, j
      End If
      j = @j.next
    Loop While j
    i = @i.next
  Loop While i

End Method

'============================================================
'  mode_db::mode_table_get_count
'============================================================

Method mode_table_get_count() As Long

  Local i As Long

  mode_count = 0
  For i = 0 To UBound(m_table())
    If m_table(i).active Then Incr mode_count
  Next

  Method = mode_count
End Method

'============================================================
'  mode_db::mode_table_build
'============================================================

Method mode_table_build(opt_mon As MONITOR_OPTIONS, opt_db As MODE_DB_OPTIONS, opt_mdl As MODELINE_OPTIONS) As Long

  Local i, j, found As Long
  Local xres, yres As Long
  Local vfreq As Double
  Local r As NATIVE_MODE Ptr
  Local m As MODELINE Ptr
  Local effective_orientation As Long
  Local mode_table_method, x_res_min, y_res_min, y_res_round As Long

  i = 0
  While native(i).width
    r = VarPtr(native(i))
    m = VarPtr(vmode(i))
    mode_table_method = IIf(@r.source, opt_db.mode_table_method_user, opt_db.mode_table_method_xml)
    x_res_min = IIf(@r.source, opt_db.x_res_min_user, opt_db.x_res_min_xml)
    y_res_min = IIf(@r.source, opt_db.y_res_min_user, opt_db.y_res_min_xml)
    y_res_round = IIf(@r.source, opt_db.y_res_round_user, opt_db.y_res_round_xml)
    effective_orientation = IIf(opt_mon.rotation < %M_ROTATING_R, opt_mon.rotation Xor @r.rotation, 0)
    If effective_orientation Then @m.type Or= %MODE_ROTATED
    xres = IIf(effective_orientation, Norm(@r.height, 8), Norm(@r.width, 8))
    yres = IIf(effective_orientation, Norm(@r.width, y_res_round), Norm(@r.height, y_res_round))
    If (xres < x_res_min And IsFalse @r.rotation) Then
      xres = 1 : yres = 1
    ElseIf yres < y_res_min Then
      yres = y_res_min
    End If

    Select Case As Const mode_table_method
      Case %STATIC_LIST
        vfreq = @r.refresh

      Case %DYNAMIC_LIST
        vfreq = 60

      Case %MAGIC_LIST
        xres = %DUMMY_WIDTH
        vfreq = 60
        @m.type And= Not %MODE_ROTATED
    End Select

    @m.type Or= %XYV_EDITABLE
    get_modeline(xres, yres, vfreq, opt_mon.monitor, opt_mdl, @m)

    found = -1
    For j = 0 To i - 1
      If m_table(j).active And @m.hactive = vmode(j).hactive And @m.vactive = vmode(j).vactive And @m.vfreq = vmode(j).vfreq Then found = j : Exit For
    Next

    If found <> -1 Then
      @r.p_mt = VarPtr(m_table(found))
    Else
      @r.p_mt = me.insert_node(@m)
    End If

    Incr i
  Wend

  Method = mode_count
End Method

'============================================================
' mode_db::mode_table_import_modes
'============================================================

Method mode_table_import_modes(ByVal m As MODELINE Ptr) As Long

'  Reset vmode()
'  Reset m_table
'  Reset m_table()
'  Reset mode_count

  Local current_count As Long
  current_count = mode_count

  Local i As Long
  While @m[i].Width
    me.insert_node(@m[i])
    Incr i
  Wend

  Method = mode_count - current_count
End Method

'============================================================
' mode_db::get_modeline_ptr_from_index
'============================================================

Method get_modeline_ptr_from_index(index As Long) As Long

  Local i As Long
  Local mt As MODE_DB_NODE Ptr

  mt = me.get_first_node()
  If IsFalse mt Then Exit Method

  Do
    If i = index Then Method = @mt.modeline : Exit Method
    mt = @mt.next
    Incr i
  Loop While mt

  Method = 0
End Method

'============================================================
' mode_db::del_modeline_by_index
'============================================================

Method del_modeline_by_index(index As Long, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long

  Local i As Long
  Local mt As MODE_DB_NODE Ptr

  mt = me.get_first_node()
  If IsFalse mt Then Exit Method

  Do
    If i = index Then GoTo node_found
    mt = @mt.next
    Incr i
  Loop While mt
  Exit Method

  node_found:
  me.delete_node(mt, monitor, opt_mdl)

  Method = 1
End Method

'============================================================
'  mode_db::mode_list_output
'============================================================

Method mode_list_output(opt_mon As MONITOR_OPTIONS, opt_mdl As MODELINE_OPTIONS, file_name As String) As Long

  Local i, j, file_num As Long
  Local mt As MODE_DB_NODE Ptr
  Local r As NATIVE_MODE Ptr
  Local m As MODELINE Ptr
  Local t As MODELINE
  Local n_line As String

  If file_name <> "" Then
    file_num = FreeFile
    Open "mode_list.txt" For Output As file_num
  End If

  i = 0 : j = 0
  mt = me.get_first_node()
  If IsFalse mt Then Exit Method

  Do
    m = @mt.modeline
    n_line = Using$ ( "[###]#### x#### @ ## (#.####Hz) rng(#) priority (#) count(#)", i, @m.width, @m.height, @m.refresh, @m.vfreq, @m.range, @mt.priority, @mt.count) + $CrLf +_
             String$ ( 170, "=" ) + $CrLf +_
             $Tab + "[idx] Video mode request   [roms]System Name                range    Video mode result   Hfreq scaling       x  y  v       x(%)   y(%)   v(Hz)        x2/x1  y2/y1" + $CrLf +_
             $Tab + String$ ( 162, "-" )
    If file_num Then Print #file_num, n_line Else clog n_line
    Incr i
    j = 0
    While native(j).width
      r = VarPtr(native(j))
      If @r.p_mt = mt Then
        t = @m
        Local effective_orientation As Long
        effective_orientation = IIf(opt_mon.rotation < %M_ROTATING_R, opt_mon.rotation Xor @r.rotation, 0)
        t.type = IIf(t.width = %DUMMY_WIDTH, %X_RES_EDITABLE, 0) Or %V_FREQ_EDITABLE Or IIf(effective_orientation, %MODE_ROTATED, 0)
        get_modeline(IIf(effective_orientation, @r.height, @r.width), IIf(effective_orientation, @r.width, @r.height), @r.refresh, opt_mon.monitor, opt_mdl, t)
        n_line = $Tab + Using$ ("[###]#### x#### @ ##.######", j, @r.width, @r.height, @r.refresh) + "[" + Format$(@r.gcount, "0000") + "]" + LSet$(RTrim$(@r.label), 23 Using ".") + "." + modeline_result(t)
        If file_num Then Print #file_num, n_line Else clog n_line
      End If
      Incr j
    Wend
    If file_num Then Print #file_num Else clog $CrLf
    mt = @mt.next
  Loop While mt

  If file_num Then Close
End Method

'============================================================
'  mode_db::get_modeline_list
'============================================================

Method get_modeline_list(ByVal m As MODELINE Ptr) As Long

  Local i As MODE_DB_NODE Ptr
  Local j As MODELINE Ptr
  Local k As Long

  If IsFalse me.get_first_node() Then Exit Method

  i = me.get_first_node()
  Do
    j = @i.modeline
    If IsFalse j Then Exit Method ' this happens when the list is empty
    @m[k] = @j
    Incr k
    i = @i.next
  Loop While i

  Method = k
End Method

'============================================================
'  mode_db::mode_table_disambiguation
'============================================================

Method mode_table_disambiguation() As Long

  Local i, j As MODE_DB_NODE Ptr
  Local k, m As MODELINE Ptr
  Local win_version As Long
  win_version = os_version()

  i = me.get_first_node()
  Do
    k = @i.modeline
    j = me.get_first_node()
    While i <> j
      m = @j.modeline
      If @m.width = @k.width And @m.height = @k.height And @m.refresh = @k.refresh Then
        If win_version <= 5 Then
          Incr @k.width
          If @k.width - @k.hactive > 7 Then
            clog "Mode" + Using$ (" #### x#### @ ##.###### ", @k.hactive, @k.vactive, @k.vfreq)
            clog " Error : number of variants exceded."
            Exit Method
          End If
        Else
          clog "Error: overlapped labels for these modes:"
          clog $Tab + modeline_print(@k, %MS_FULL) + $Tab + Left$(me.get_label(i), 32)
          clog $Tab + modeline_print(@m, %MS_FULL) + $Tab + Left$(me.get_label(j), 32) + $CrLf
        End If
      End If
      j = @j.next
    Wend
    i = @i.next
  Loop While i

  Method = 1
End Method

'============================================================
'  mdb:get_label
'============================================================

Method get_label(ByVal m As MODE_DB_NODE Ptr) As String

    Local m_label As String
    Local r As NATIVE_MODE Ptr
    Local j As Long

    While native(j).width
      r = VarPtr(native(j))
      If @r.p_mt = m Then m_label = m_label + "/" + @r.label
      Incr j
    Wend

  Method = m_label
End Method

'============================================================
'  mdb:global_result
'============================================================

Method global_result(opt_mon As MONITOR_OPTIONS, opt_mdl As MODELINE_OPTIONS) As mode_result

  Local i As Long
  Local r As NATIVE_MODE Ptr
  Local mt As MODE_DB_NODE Ptr
  Local m As MODELINE Ptr
  Local t As MODELINE
  Local g_result As mode_result
  Local effective_orientation As Long

  While native(i).width
    r = VarPtr(native(i))
    mt = @r.p_mt
    m = @mt.modeline
    t = @m
    effective_orientation = IIf(opt_mon.rotation < %M_ROTATING_R, opt_mon.rotation Xor @r.rotation, 0)
    t.type = IIf(t.width = %DUMMY_WIDTH, %X_RES_EDITABLE, 0) Or %V_FREQ_EDITABLE Or IIf(effective_orientation, %MODE_ROTATED, 0)
    get_modeline(IIf(@r.rotation, @r.height, @r.width), IIf(@r.rotation, @r.width, @r.height), @r.refresh, opt_mon.monitor, opt_mdl, t)
    g_result.weight += t.result.weight
    g_result.x_scale += t.result.x_scale
    g_result.y_scale += t.result.y_scale
    g_result.v_scale += t.result.v_scale
    g_result.x_diff += t.result.x_diff
    g_result.y_diff += t.result.y_diff
    g_result.v_diff += t.result.v_diff
    g_result.x_ratio += t.result.x_ratio
    g_result.y_ratio += t.result.y_ratio
    g_result.y_ratio += t.result.v_ratio
    Incr i
  Wend
  Method = g_result

End Method

'============================================================
'  mdb::mode_table_reduce
'============================================================

Method mode_table_reduce(ByVal monitor As MONITOR_DEF Ptr, opt_db As MODE_DB_OPTIONS, opt_mdl As MODELINE_OPTIONS) As Long

  Local drop_list, dropped_count, max_modes As Long
  Local i, j As MODE_DB_NODE Ptr
  Local m As MODELINE Ptr

  drop_list = FreeFile
  Open "drop_list.txt" For Output As drop_list

  me.mode_table_get_count
  max_modes = IIf(opt_db.total_modes = "auto", custom_video_get_max_modes(), Val(opt_db.total_modes))

  While mode_count > max_modes
    i = me.get_first_node()
    j = i
    me.compute_score()

    Do
      If @i.priority < @j.priority Or _
        (@i.priority = @j.priority And @i.count < @j.count) Then j = i
      i = @i.next
    Loop While i

    me.delete_node(j, monitor, opt_mdl)

    Incr dropped_count
    m = @j.modeline
    Print #drop_list, Using$ ("#### x#### @ ##.######", @m.width, @m.height, @m.refresh)
  Wend

  Close
  Method = dropped_count
End Method

'============================================================
' mode_db::get_first_node
'============================================================

Method get_first_node() As Long
  Method = m_table
End Method

'============================================================
' mode_db::set_first_node
'============================================================

Method set_first_node(ByVal m As MODE_DB_NODE Ptr)
  m_table = m
End Method

'============================================================
' mode_db::is_first_node
'============================================================

Method is_first_node(ByVal m As MODE_DB_NODE Ptr) As Long
  Method = IIf(m = m_table, 1, 0)
End Method

'============================================================
' mode_db::insert_node
'============================================================

Method insert_node(m As MODELINE) As Long

  ' Find an empty slot
  Local i As Long
  While m_table(i).active
    Incr i
    If i > UBound(m_table()) Then Exit Method
  Wend

  vmode(i) = m
  m_table(i).active = 1
  m_table(i).modeline = VarPtr(vmode(i))

  Local n, np As MODE_DB_NODE Ptr

  ' find last node
  n = me.get_first_node()
  Do
    np = n
    n = @n.next
  Loop While n
  n = VarPtr(m_table(i))
  If IsFalse me.is_first_node(n) Then
    @np.next = n
    @n.prev = np
  End If

  Incr mode_count
  If mode_count = UBound(m_table()) Then me.resize()

  Method = n
End Method

'============================================================
'  mode_db::delete_node
'============================================================

Method delete_node(ByVal n As MODE_DB_NODE Ptr, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long

  Local i As Long
  Local r As NATIVE_MODE Ptr
  Local m, pn, nn As MODE_DB_NODE Ptr

  ' First, detach the node from the linked list
  pn = @n.prev : nn = @n.next
  If nn Then @nn.prev = pn
  If pn Then @pn.next = nn
  If n = me.get_first_node() Then me.set_first_node(nn)

  ' Now find all references to this node and recalculate them
  i = 0
  While native(i).width
    r = VarPtr(native(i))
    m = @r.p_mt
    If n = m Then me.get_best_mode(r, monitor, opt_mdl)
    Incr i
  Wend

  Decr mode_count

End Method

'============================================================
'  mode_db::compute_score
'============================================================

Method compute_score() As Long

  Local i As Long
  Local r As NATIVE_MODE Ptr
  Local m As MODE_DB_NODE Ptr

  m = me.get_first_node()
  Do
    @m.priority = 0
    @m.count = 0
    m = @m.next
  Loop While m

  i = 0
  While native(i).width
    r = VarPtr(native(i))
    m = @r.p_mt
    @m.priority += @r.priority
    @m.count += @r.gcount
    Incr i
  Wend

End Method

'============================================================
'  mode_db::get_best_mode
'============================================================

Method get_best_mode(ByVal r As NATIVE_MODE Ptr, ByVal monitor As MONITOR_DEF Ptr, opt_mdl As MODELINE_OPTIONS) As Long

  Local i As MODE_DB_NODE Ptr
  Local m, best_mode As MODELINE
  Local mp As MODELINE Ptr

  best_mode.result.weight Or= %R_OUT_OF_RANGE
  i = me.get_first_node()
  Do
    mp = @i.modeline
    m = @mp
    m.type = %V_FREQ_EDITABLE
    get_modeline(@r.width, @r.height, @r.refresh, monitor, opt_mdl, m)
    If modeline_compare(m, best_mode) Then best_mode = m : @r.p_mt = i
    i = @i.next
  Loop While i

End Method

End Interface
End Class
