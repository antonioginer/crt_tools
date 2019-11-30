'==============================================================================
'
'  VMMAker command parser
'  command_vmm.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Dim All

#Include "vmmaker.inc"

'============================================================
'  constants
'============================================================

%PARSING_WHITE_SPACE = 0
%PARSING_QUOTED_PARAM = 1
%PARSING_NORMAL_PARAM = 2

'============================================================
'  command_parse
'============================================================

Function command_parse(ByVal command_line As String, params() As AsciiZ * 128) Common As Long

  Local i, j As Long
  Local current_state As Long

  Local c As String Ptr * 1
  c = StrPtr(command_line)

  Do
    Select Case current_state

      Case %PARSING_WHITE_SPACE
        If @c <> $Spc And @c <> $Tab Then
          Incr i
          If @c = $Dq Then current_state = %PARSING_QUOTED_PARAM Else current_state = %PARSING_NORMAL_PARAM : params(i) = params(i) + @c
        End If

      Case %PARSING_QUOTED_PARAM
        If @c <> $Dq Then
          params(i) = params(i) + @c
        Else
          current_state = %PARSING_WHITE_SPACE
        End If

      Case %PARSING_NORMAL_PARAM
        If @c <> $Spc And @c <> $Tab Then
          params(i) = params(i) + @c
        Else
          current_state = %PARSING_WHITE_SPACE
        End If
    End Select

    Incr c
    Incr j
  Loop While j <= Len(command_line)

  Function = i
End Function

'============================================================
'  command_execute
'============================================================

Function command_execute(vmm As APP_DATA, cmd_name As AsciiZ, Opt param_1 As AsciiZ, param_2 As AsciiZ, param_3 As AsciiZ, param_4 As AsciiZ, _
                                                                  param_5 As AsciiZ, param_6 As AsciiZ, param_7 As AsciiZ, param_8 As AsciiZ, _
                                                                  param_9 As AsciiZ, param_10 As AsciiZ, param_11 As AsciiZ, param_12 As AsciiZ, _
                                                                  param_13 As AsciiZ, param_14 As AsciiZ, param_15 As AsciiZ, param_16 As AsciiZ) Common As Long
  Local result As Long
  clog $CrLf + Using$(">>& & & & & & & & & & & & & & & & &", cmd_name, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8,_
                                                             param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16)

  Select Case Const$ cmd_name

    Case $CMD_HELP
      result = cmd_help(vmm)

    Case $CMD_DISPLAY
      result = cmd_display(vmm, param_1, param_2)

    Case $CMD_MODELIST
      result = cmd_modelist(vmm, param_1, param_2)

    Case $CMD_MODE
      result = cmd_mode(vmm, param_1, $Dq + param_2 + $Dq, Using$("& & & & & & & & & & & &", param_3, param_4, param_5, param_6, param_7, param_8,_
                                     param_9, param_10, param_11, param_12, param_13, param_14))
    Case $CMD_EDID
      result = cmd_edid(vmm, param_1, param_2, param_3)

    Case $CMD_CSYNC
      result = cmd_csync(vmm, param_1)

    Case $CMD_CONFIG
      result = cmd_config(vmm)

    Case $CMD_EXIT
      result = %RESULT_EXIT

    Case Else
      result = %RESULT_SYNTAX_ERROR

  End Select

  If result = %RESULT_SYNTAX_ERROR Then
    clog "Syntax error"
  End If

  Function = result
End Function

'============================================================
'  cmd_help
'============================================================

Function cmd_help(vmm As APP_DATA) As Long
  cmd_display(vmm, $CMD_HELP, "")
  cmd_modelist(vmm, $CMD_HELP, "")
  cmd_mode(vmm, $CMD_HELP, "", "")
  cmd_edid(vmm, $CMD_HELP, "", "")
  cmd_csync(vmm, $CMD_HELP)
  Function = %RESULT_SUCCESS
End Function

'============================================================
'  cmd_display
'============================================================

Function cmd_display(vmm As APP_DATA, action As AsciiZ, param As AsciiZ) As Long

  Select Case Const$ action

    Case "", $CMD_HELP
      clog LSet$($CMD_DISPLAY, 8) + "<action> <param>"
      clog $Tab + LSet$($DI_INIT, 9)    + "<device key>  : initializes display device."
      clog $Tab + LSet$($DI_RESTART, 9) + "<device name> : restarts PCI display device, forcing driver to reinitialize."
      clog ""

    Case $DI_INIT 'param = device key
      If IsFalse display_init(param) Then vmm.options.display.device_key = display_get_device_key(display_get_current())
      vmm.driver_compatible = custom_video_init(display_get_current())
      If vmm.options.modeline.s_pclock_min = "auto" Then vmm.options.modeline.pclock_min = custom_video_get_min_dotclock() * 1000000
      Function = %RESULT_SUCCESS

    Case $DI_RESTART 'param = device name
      display_restart(IIf$(param <> "", param, display_get_current()), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case Else
      Function = %RESULT_SYNTAX_ERROR
  End Select

End Function

'============================================================
'  cmd_csync
'============================================================

Function cmd_csync(vmm As APP_DATA, action As AsciiZ) As Long

  Select Case Const$ action

    Case "", $CMD_HELP
      clog LSet$($CMD_CSYNC, 8) + "<action>"
      clog $Tab + LSet$($CS_ENABLE, 6) + ": enables composite sync on current device."
      clog $Tab + LSet$($CS_DISABLE, 6)+ ": disables composite sync on current device."
      clog ""

    Case $CS_ENABLE
      custom_video_csync_enable()
      display_restart(display_get_current(), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case $CS_DISABLE
      custom_video_csync_disable()
      display_restart(display_get_current(), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case Else
      Function = %RESULT_SYNTAX_ERROR
  End Select

End Function


'============================================================
'  cmd_edid
'============================================================

Function cmd_edid(vmm As APP_DATA, action As AsciiZ, param1 As AsciiZ, param2 As AsciiZ) As Long

  Local output_label As String
  Static edid As EDID_BLOCK
  Dim modes(%NUMBER_OF_MODES) As MODELINE
  Local mdb As IMODE_DB
  mdb = Ptr2Obj(vmm.mdb)
  Function = %RESULT_SYNTAX_ERROR

  Select Case Const$ action

    Case "", $CMD_HELP
      clog LSet$($CMD_EDID, 8) + "<action> <params>"
      clog $Tab + LSet$($ED_CREATE, 9) + "<file_name> <connector>: creates an EDID block and saves it to <file_name>. connector: vga|dvi|hdmi"
      clog $Tab + LSet$($ED_START, 9)  + "<output> <file_name>   : starts EDID emulation on <output>. Optional <file_name>"
      clog $Tab + LSet$($ED_STOP, 9)   + "<output>               : stops EDID emulation on <output>."
      clog $Tab + LSet$($ED_READ, 9)   + "<output>               : reads emulated EDID from <output>."
      clog ""
      Function = %RESULT_SUCCESS

    Case $ED_CREATE 'param1 = file ; param2 = output type
      If vmm.options.edid.from_modelist = 0 Or mdb.get_modeline_list(VarPtr(modes(0))) = 0 Then
        modes(0).type = %XYV_EDITABLE
        get_modeline(640, 480, 60, vmm.options.monitor.monitor, vmm.options.modeline, modes(0))
      End If
      If param2 <> "" Then
        Reset edid
        edid_from_modeline(modes(), vmm.options.monitor.@monitor, edid, param2)
        edid_to_file(edid, IIf$(param1 <> "", param1, "edid.bin"))
        Function = %RESULT_SUCCESS
      End If

    Case $ED_START 'param1 = output ; param2 = file_name
      output_label = param1
      If param2 = "" Then
        Local connector As String
        connector = output_label
        custom_video_get_connectors(0, connector)
        cmd_edid(vmm, $ED_CREATE, "edid.bin", connector + "")
      Else
        Local file_num, edid_size As Long
        Local edid_file As String
        Local edid_ptr As String Ptr * 512
        edid_ptr = VarPtr(edid)
        Reset edid
        file_num = FreeFile
        Open param2 For Binary As file_num
        edid_size = Lof(file_num)
        Get$ file_num, IIf(edid_size <= 512, edid_size, 512), edid_file
        Close file_num
        Mid$(@edid_ptr, 1, edid_size) = edid_file
      End If
      custom_video_edid_emulation_enable(output_label, edid)
      display_restart(display_get_current(), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case $ED_STOP 'param1 = output
      output_label = param1
      custom_video_edid_emulation_disable(output_label)
      display_restart(display_get_current(), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case $ED_READ 'param1 = output
      output_label = param1
      custom_video_edid_emulation_read(output_label, edid)
      clog edid_get_monitor_name(edid)
      Function = %RESULT_SUCCESS

    Case Else
      Function = %RESULT_SYNTAX_ERROR
  End Select

End Function

'============================================================
'  cmd_mode
'============================================================

Function cmd_mode(vmm As APP_DATA, action As AsciiZ, param_1 As AsciiZ, param_2 As AsciiZ) As Long

  Local x_res, y_res As Long
  Local v_freq As Double
  Static m As MODELINE
  Local mdb As IMODE_DB
  mdb = Ptr2Obj(vmm.mdb)
  Function = %RESULT_SYNTAX_ERROR

  Select Case Const$ action

    Case "", $CMD_HELP
      clog LSet$($CMD_MODE, 8) + "<action> <params...>"
      clog $Tab + LSet$($MD_CALC, 9)+ "<width_height_refresh> : calculate a modeline."
      clog $Tab + LSet$($MD_ADD, 9) + "<width_height_refresh> : calculate and add a modeline to the mode list."
      clog $Tab + LSet$($MD_ADD, 9) + "<modeline>             : add the specified modeline to the mode list."
      clog $Tab + LSet$($MD_DEL, 9) + "<index>                : delete a modeline at index from the mode list."
      clog ""
      Function = %RESULT_SUCCESS

    Case $MD_ADD 'param_1 = m_label, param_2 = m_timing
      If Trim$(param_2) = "" Then
        'detailed timing not provided, calculate it
        cmd_mode(vmm, $MD_CALC, param_1, "")
      Else
        'detailed timing provided, parse it
        If IsFalse modeline_parse(param_1 + $Spc + param_2, m) Then Exit Function
      End If
      If mdb.insert_node(m) Then
        mdb.mode_table_disambiguation()
        clog "1 mode added to modelist."
        Function = %RESULT_SUCCESS
      End If

    Case $MD_DEL 'param_1 = index
      If mdb.del_modeline_by_index(Val(Unwrap$(param_1, $Dq, $Dq)), vmm.options.monitor.monitor, vmm.options.modeline) Then
        clog "1 mode deleted from modelist."
        Function = %RESULT_SUCCESS
      Else
        clog "invalid index."
      End If

    Case $MD_CALC 'param_1 = mode_label "widthXheight@refresh"
      param_1 = Unwrap$(param_1, $Dq, $Dq)
      x_res = Val(Parse$(param_1, Any "xX_@", 1))
      y_res = Val(Parse$(param_1, Any "xX_@", 2))
      v_freq = Val(Parse$(param_1, Any "xX_@", 3))
      If x_res = 0 Or y_res = 0 Or v_freq = 0 Then Exit Function
      m.type = %XYV_EDITABLE
      get_modeline(x_res, y_res, v_freq, vmm.options.monitor.monitor, vmm.options.modeline, m)
      clog modeline_print(m, %MS_FULL)
      Function = %RESULT_SUCCESS

    Case Else
      Function = %RESULT_SYNTAX_ERROR

  End Select

End Function

'============================================================
'  cmd_modelist
'============================================================

Function cmd_modelist(vmm As APP_DATA, action As AsciiZ, param_1 As AsciiZ) As Long

  Local mdb As IMODE_DB
  mdb = Ptr2Obj(vmm.mdb)
  Dim modes(%NUMBER_OF_MODES) As MODELINE
  Local source_count, mode_count, dropped_count As Long
  Local i, j, num_lines As Long
  Local n_line As String

  Select Case Const$ action

    Case "", $CMD_HELP
      clog LSet$($CMD_MODELIST, 9)         + "<action> <params>"
      clog $Tab + LSet$($ML_BUILD,     21) + ": build RAM mode list calculating modelines from user files."
      clog $Tab + LSet$($ML_RESET,     21) + ": reset RAM mode list to start from scratch."
      clog $Tab + LSet$($ML_INSTALL,   21) + ": install RAM mode list to the video driver."
      clog $Tab + LSet$($ML_UNINSTALL, 21) + ": uninstall mode list from the video driver."
      clog $Tab + LSet$($ML_IMPORT,    21) + ": import mode list from video driver and load it to RAM."
      clog $Tab + LSet$($ML_IMPORT,     9) + "<file_name> : import mode list from file_name and load it to RAM."
      clog $Tab + LSet$($ML_EXPORT,     9) + "<file_name> : export RAM mode list to file_name"
      clog $Tab + LSet$($ML_LIST,      21) + ": list all modes in mode list."
      clog $Tab + LSet$($ML_ENUM,      21) + ": list all modes in mode list with indexes."
      clog ""

    Case $ML_BUILD
      clog "Creating mode list..."
      mdb.initialize

      If vmm.options.user.list_user_modes Then
        source_count += user_get_modes(mdb, vmm.options.user)
      End If
      If vmm.options.mame.list_xml_modes Then
        source_count += mame_get_modes(mdb, vmm.options.mame)
      End If

      mdb.native_sort_by_xyv()

      clog Using$("##### video modes found", source_count) + $CrLf
      If IsFalse source_count Then Exit Function

      clog "Generating " + IIf$(vmm.options.mode_db.mode_table_method_xml, "dynamic", "static") + " mode table..."
      mode_count = mdb.mode_table_build(vmm.options.monitor, vmm.options.mode_db, vmm.options.modeline)
      clog Using$(" # redundant video modes found.", source_count - mode_count) + $CrLf

      mdb.mode_table_sort_by_xy()
      If IsFalse mdb.mode_table_disambiguation() Then mdb.initialize : Exit Function
      mdb.global_result(vmm.options.monitor, vmm.options.modeline)

      clog "Reducing mode list..."
      dropped_count = mdb.mode_table_reduce(vmm.options.monitor.monitor, vmm.options.mode_db, vmm.options.modeline)
      clog Using$(" # video modes dropped.", dropped_count) + $CrLf

      mdb.mode_list_output(vmm.options.monitor, vmm.options.modeline, "mode_list.txt")
      clog Using$(" # modelines generated.", mode_count - dropped_count) + $CrLf

      cmd_modelist(vmm, $ML_LIST, "")
      cmd_modelist(vmm, $ML_EXPORT, "modeline.txt")

      If vmm.options.inf.update Then ati_inf_file_update(vmm.options.inf)
      Function = %RESULT_SUCCESS

    Case $ML_RESET
      clog "Resetting mode list..."
      mdb.initialize

    Case $ML_UNINSTALL
      clog "Removing modelines from system..."
      custom_video_reset_mode_list()
      If custom_video_get_method() = %CUSTOM_VIDEO_TIMING_ATI_LEGACY Then display_restart(display_get_current(), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case $ML_INSTALL
      If mdb.mode_count() = 0 Then clog "No modelines found." : Exit Function

      clog "Installing modelines in system..."
      If IsFalse mdb.mode_table_disambiguation() Then Exit Function
      mdb.get_modeline_list(VarPtr(modes(0)))

      mode_count = custom_video_set_mode_list(modes())
      clog Using$("# modelines installed.", mode_count)

      If custom_video_get_method() = %CUSTOM_VIDEO_TIMING_ATI_LEGACY Then display_restart(display_get_current(), vmm.h_gui, vmm.win_version, vmm.options.display)
      Function = %RESULT_SUCCESS

    Case $ML_IMPORT 'param_1 = filename
      If param_1 <> "" Then
        clog "Importing modelines from file..."
        Local mode_list As String
        mode_list = file_to_string(param_1)
        If mode_list = "" Then clog "File not found." : Exit Function

        num_lines = ParseCount(mode_list, $CrLf)
        For i = 1 To num_lines
          n_line = Trim$(Extract$(Parse$(mode_list, $CrLf, i), "#"), Any $Tab + $Spc)
          If n_line = "" Then Iterate For
          If IsFalse modeline_parse(n_line, modes(j)) Then clog Using$("Error in line #", i) : Exit Function
          Incr j
        Next

      Else
        clog "Importing modelines from system..."
        If IsFalse custom_video_get_mode_list(modes()) Then clog "No modelines found." : Exit Function
      End If

      mode_count = mdb.mode_table_import_modes(VarPtr(modes(0)))
      mdb.mode_table_disambiguation()
      'If IsFalse mdb.mode_table_disambiguation() Then mdb.initialize : Exit Function
      clog Using$("# modelines imported", mode_count)
      Function = %RESULT_SUCCESS

    Case $ML_LIST, $ML_ENUM, $ML_EXPORT 'param1 = filename
      mdb.get_modeline_list(VarPtr(modes(0)))

      Local num As Long
      If action = $ML_ENUM Then num = 1

      Local file_num As Long
      If action = $ML_EXPORT And param_1 <> "" Then
        file_num = FreeFile
        Open param_1 For Output As file_num
      End If

      If mdb.mode_count() Then
        For i = 0 To mdb.mode_count() - 1
          n_line = IIf$(num, Using$("[#] ", i), "") + modeline_print(modes(i), %MS_FULL)
          If file_num Then Print #file_num, n_line Else clog n_line
        Next
      End If

      If file_num Then Close
      Function = %RESULT_SUCCESS

    Case Else
      Function = %RESULT_SYNTAX_ERROR

  End Select

End Function

'============================================================
'  cmd_config
'============================================================

Function cmd_config(vmm As APP_DATA) Common As Long

  clog "Processing config..."
  modeline_get_dotclock_table("Ati9250.txt")

  Local opt_mon As MONITOR_OPTIONS Ptr
  opt_mon = VarPtr(vmm.options.monitor)
  If IsFalse monitor_get_specs(@opt_mon.m_name, @opt_mon) Then monitor_get_specs($DEFAULT_MONITOR, @opt_mon)
  @opt_mon.rotation = monitor_get_rotation(@opt_mon.orientation)

  If vmm.options.mame.export_settings Then
    clog "Exporting settings to mame.ini..."
    mame_update_ini(vmm.options.mame, vmm.options.monitor)
  End If

  Function = %RESULT_SUCCESS
End Function
