'==============================================================================
'
'  VideoModeMaker
'  gui_settings.bas
'  Copyright (c) 2008-2015 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Dim All
#Include "Win32API.inc"
#Include "CommCtrl.inc"
#Include "vmmaker.inc"
#Include "util.inc"

Declare Function command_execute(vmm As APP_DATA, cmd_name As AsciiZ, Opt param_1 As AsciiZ, param_2 As AsciiZ, param_3 As AsciiZ, param_4 As AsciiZ, _
                                                                          param_5 As AsciiZ, param_6 As AsciiZ, param_7 As AsciiZ, param_8 As AsciiZ, _
                                                                          param_9 As AsciiZ, param_10 As AsciiZ, param_11 As AsciiZ, param_12 As AsciiZ, _
                                                                          param_13 As AsciiZ, param_14 As AsciiZ, param_15 As AsciiZ, param_16 As AsciiZ) Common As Long
Declare Function timing_chart_from_monitor_range(m As MONITOR_RANGE) Common As Long

'============================================================
'  Constants
'============================================================

%BUTTON_WIDTH  = 64
%BUTTON_HEIGHT = 32
%SETTINGS_WIDTH = 640
%SETTINGS_HEIGHT = 400
%SETTINGS_BORDER = 4
%TAB_WIDTH = %SETTINGS_WIDTH - 2 * %SETTINGS_BORDER
%TAB_HEIGHT = %SETTINGS_HEIGHT - (%BUTTON_HEIGHT + 3 * %SETTINGS_BORDER)
%MAX_TABS = 16

Enum settings_dlg
  ID_OK = 3000
  ID_CANCEL
End Enum

%ID_TAB = 4000
Enum mame_tab
  FRAME1 = %ID_TAB + 100
  FRAME2
  FRAME3
  LABEL1
  LABEL2
  LABEL3
  LABEL4
  LABEL5
  LABEL6
  CHECK1
  CHECK2
  CHECK3
  CHECK4
  TEXTBOX1
  TEXTBOX2
  TEXTBOX3
  TEXTBOX4
  TEXTBOX5
  BUTTON1
  BUTTON2
  BUTTON3
  COMBO1
  COMBO2
End Enum

Enum custom_tab
  FRAME1 = %ID_TAB + 200
  FRAME2
  LABEL1
  LABEL2
  LABEL3
  LABEL4
  CHECK1
  TEXTBOX1
  TEXTBOX2
  TEXTBOX3
  TEXTBOX4
  BUTTON1
  BUTTON2
  COMBO1
  COMBO2
End Enum

Enum monitor_tab
  FRAME1 = %ID_TAB + 300
  FRAME2
  FRAME3
  LABEL1
  LABEL2
  LABEL3
  LABEL4
  COMBO1
  COMBO2
  COMBO3
  COMBO4
  CHECK1
  GRAPH1
  CHART1
  LABEL10 '10-19
  LABEL11
  LABEL12
  LABEL13
  LABEL14
  LABEL15
  LABEL16
  LABEL17
  LABEL18
  LABEL19
  SLIDER1
  SLIDER2
  SLIDER3
  UPDOWN
  BUTTON1
End Enum

Enum videocard_tab
  FRAME1 = %ID_TAB + 500
  FRAME2
  FRAME3
  LABEL1
  LABEL2
  LABEL3
  LABEL4
  LABEL5
  LABEL6
  LABEL7
  LABEL8
  LABEL9
  LABEL10
  LABEL11
  COMBO1
  COMBO2
  BUTTON1
  BUTTON2
  BUTTON3
  BUTTON4
  BUTTON5
  BUTTON6
  TEXTBOX1
  TEXTBOX2
  CHECK1
  CHECK2
  CHECK3
  CHECK4
End Enum

Enum modeline_tab
  FRAME1 = %ID_TAB + 400
  LABEL1
End Enum

Enum tab_index
  MONITOR_SETTINGS
  VIDEO_CARD
  USER_MODES
  MAME
End Enum

%WM_OPTIONS_FROM_DIALOG = %WM_User + 4000
%WM_OPTIONS_TO_DIALOG = %WM_User + 4001
%WM_UPDATE_SLIDERS = %WM_User + 4002
%WM_UPDATE_ORIENTATION = %WM_User + 4003
%WM_LOAD_RANGE = %WM_User + 4004
%WM_EDID_EMULATION_UPDATE = %WM_User + 4005
%WM_MONITOR_PRESET_UPDATE = %WM_User + 4006
%WM_HARD_RESET = %WM_User + 4007

'============================================================
'  settings_dlg_init
'============================================================

Function settings_dlg_show(h_parent As Long) Common As Long

  Local h_settings, result As Long
  Local vmm As APP_DATA
  Local vmm_ptr As APP_DATA Ptr

  Dialog New Pixels, h_parent, "Settings",,, %SETTINGS_WIDTH, %SETTINGS_HEIGHT, %WS_Caption Or %WS_SysMenu Or %WS_Overlapped, To h_settings
  Dialog Set Icon h_settings, "#101"

  ' Get app data
  Dialog Get User h_parent, 1 To vmm_ptr
  Dialog Set User h_settings, 1, VarPtr(vmm)
  Dialog Set User h_settings, 2, h_parent
  vmm = @vmm_ptr

  ' Build and show dialog
  Control Add Button, h_settings, %settings_dlg.ID_OK, "OK", %SETTINGS_WIDTH - (%BUTTON_WIDTH + %SETTINGS_BORDER) * 2, %SETTINGS_HEIGHT - (%BUTTON_HEIGHT + %SETTINGS_BORDER), %BUTTON_WIDTH, %BUTTON_HEIGHT, %WS_TabStop
  Control Add Button, h_settings, %settings_dlg.ID_CANCEL, "Cancel", %SETTINGS_WIDTH - (%BUTTON_WIDTH + %SETTINGS_BORDER), %SETTINGS_HEIGHT - (%BUTTON_HEIGHT + %SETTINGS_BORDER), %BUTTON_WIDTH, %BUTTON_HEIGHT, %WS_TabStop

  ' Add tabs
  ReDim h_tab(%MAX_TABS) As Long
  Dialog Set User h_settings, 3, VarPtr(h_tab(0))
  Control Add Tab, h_settings, %ID_TAB, "", %SETTINGS_BORDER, %SETTINGS_BORDER, %TAB_WIDTH, %TAB_HEIGHT
  Tab Insert Page h_settings, %ID_TAB, 1, 0, "Monitor settings", Call settings_monitor_proc To h_tab(%tab_index.MONITOR_SETTINGS)
  Tab Insert Page h_settings, %ID_TAB, 2, 0, "Video card", Call settings_videocard_proc To h_tab(%tab_index.VIDEO_CARD)
  Tab Insert Page h_settings, %ID_TAB, 3, 0, "User modes", Call settings_user_modes_proc To h_tab(%tab_index.USER_MODES)
  Tab Insert Page h_settings, %ID_TAB, 4, 0, "MAME", Call settings_mame_proc To h_tab(%tab_index.MAME)
  settings_notify_tabs(h_settings, %WM_OPTIONS_TO_DIALOG)

  Dialog Show Modal h_settings, Call settings_dlg_proc To result

  ' If OK was pressed apply new options
  If result Then @vmm_ptr = vmm

  Function = result
End Function

'============================================================
'  settings_notify_tabs
'============================================================

Function settings_notify_tabs(hdlg As Long, msg As Long) As Long

  Local h_tab As Long Ptr
  Dialog Get User hdlg, 3 To h_tab
  Dim h_tab(%MAX_TABS) As Long At h_tab

  Local i As Long
  For i = 0 To %MAX_TABS
    If IsFalse h_tab(i) Then Exit For
    SendMessage(h_tab(i), msg, 0, 0)
  Next

End Function

'============================================================
'  settings_dlg_proc
'============================================================

CallBack Function settings_dlg_proc() As Long

  Select Case As Long CbMsg

    Case %WM_Command
      Select Case As Long Cb.Ctl
        Case %settings_dlg.ID_OK
          settings_notify_tabs(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG)
          Dialog End Cb.Hndl, 1
        Case %settings_dlg.ID_CANCEL
          Dialog End Cb.Hndl, 0
      End Select

    Case Else
      Exit Function
  End Select

  Function = 1
End Function

'============================================================
'  settings_monitor_proc
'============================================================

CallBack Function settings_monitor_proc() As Long

  Static vmm As APP_DATA Ptr
  Static options As APP_OPTIONS Ptr
  Static h_tab As Long Ptr

  Static h_slider1, h_slider2, h_slider3 As Long
  Static r As MONITOR_RANGE
  Static r_idx As Long
  Local i As Long

  Select Case As Long CbMsg

    Case %WM_InitDialog

      Dialog Get User GetParent(Cb.Hndl), 1 To vmm
      Dialog Get User GetParent(Cb.Hndl), 3 To h_tab
      options = VarPtr(@vmm.options)
      ReDim h_tab(%MAX_TABS) As Static Long At h_tab

      Local tab_rect As RECT
      GetClientRect(Cb.Hndl, tab_rect)
      Local section_width, section_height As Long
      section_width = tab_rect.right - 2 * %SETTINGS_BORDER
      section_height = tab_rect.bottom / 2 - 2 * %SETTINGS_BORDER

      Local x, y As Long
      x = %SETTINGS_BORDER: y = %SETTINGS_BORDER
      Control Add Frame,    Cb.Hndl, %monitor_tab.FRAME1, "Monitor presets", x, y, 292, 72, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %monitor_tab.LABEL1, "Type:", x + 8, y + 22, 32, 18
      Control Add ComboBox, Cb.Hndl, %monitor_tab.COMBO1,, x + 64, y + 18, 222, 160, %CBS_DropDownList Or %WS_TabStop Or %WS_VScroll
      Control Add Button,   Cb.Hndl, %monitor_tab.BUTTON1, "Edit monitor presets...", x + 167, y + 44, 120, 24
      Control Add Frame,    Cb.Hndl, %monitor_tab.FRAME2, "Monitor rotation", x, y + 80, 292, 72, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add ComboBox, Cb.Hndl, %monitor_tab.COMBO2,, x + 8, y + 100, 120, 320, %CBS_DropDownList Or %WS_TabStop
      ComboBox Add Cb.Hndl, %monitor_tab.COMBO2, "Horizontal (fixed)"
      ComboBox Add Cb.Hndl, %monitor_tab.COMBO2, "Vertical (fixed)"
      ComboBox Add Cb.Hndl, %monitor_tab.COMBO2, "Rotating to the right"
      ComboBox Add Cb.Hndl, %monitor_tab.COMBO2, "Rotating to the left"
      Control Add CheckBox, Cb.Hndl, %monitor_tab.CHECK1, "Desktop rotates too", x + 8, y + 130, 128, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Graphic, Cb.Hndl, %monitor_tab.GRAPH1, "", x + 140, y + 96, 140, 52
      Control Add Frame,    Cb.Hndl, %monitor_tab.FRAME3, "Range information", x + 300, y, 316, 152, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %monitor_tab.LABEL10 + 0, "Range:", 308, y + 30, 64, 16
      Control Add Label,    Cb.Hndl, %monitor_tab.LABEL10 + 1, "0", 368, y + 30, 40, 16, %SS_Sunken
      Control Add "msctls_updown32", Cb.Hndl, %monitor_tab.UPDOWN, "", 0, 0, 8, 8, %WS_Child Or %WS_Visible Or %UDS_ArrowKeys Or %UDS_AlignRight Or %UDS_SetBuddyInt
      Control Send Cb.Hndl, %monitor_tab.UPDOWN, %UDM_SetBuddy, GetDlgItem(Cb.Hndl, %monitor_tab.LABEL10 + 1), 0
      Control Send Cb.Hndl, %monitor_tab.UPDOWN, %UDM_SetRange, 0, Mak(Long, 9, 0)

      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 2, "Aspect:", 432, y + 30, 64, 16
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 3, "4:3", 496, y + 30, 40, 16, %SS_Sunken
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 4, "Lines prog.:", 308, y + 62, 64, 16
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 5, "", 368, y + 62, 40, 16, %SS_Sunken
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 6, "H-freq. kHz:", 308, y + 94, 64, 16
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 7, "", 368, y + 94, 40, 16, %SS_Sunken
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 8, "V-freq. Hz:", 308, y + 126, 64, 16
      Control Add Label, Cb.Hndl, %monitor_tab.LABEL10 + 9, "", 368, y + 126, 40, 16, %SS_Sunken

      Control Add "msctls_trackbar32", Cb.Hndl, %monitor_tab.SLIDER1, "", x + 404, y + 52, 210, 32, %WS_Child Or %WS_Visible Or %WS_TabStop Or %TBS_HORZ Or %TBS_LEFT Or %TBS_AUTOTICKS Or %TBS_DOWNISLEFT Or %TBS_ENABLESELRANGE
      Control Add "msctls_trackbar32", Cb.Hndl, %monitor_tab.SLIDER2, "", x + 404, y + 84, 210, 32, %WS_Child Or %WS_Visible Or %WS_TabStop Or %TBS_HORZ Or %TBS_LEFT Or %TBS_AUTOTICKS Or %TBS_DOWNISLEFT Or %TBS_ENABLESELRANGE
      Control Add "msctls_trackbar32", Cb.Hndl, %monitor_tab.SLIDER3, "", x + 404, y + 116, 210, 32, %WS_Child Or %WS_Visible Or %WS_TabStop Or %TBS_HORZ Or %TBS_LEFT Or %TBS_AUTOTICKS Or %TBS_DOWNISLEFT Or %TBS_ENABLESELRANGE
      Control Handle Cb.Hndl, %monitor_tab.SLIDER1 To h_slider1
      Control Handle Cb.Hndl, %monitor_tab.SLIDER2 To h_slider2
      Control Handle Cb.Hndl, %monitor_tab.SLIDER3 To h_slider3

      Control Add Graphic, Cb.Hndl, %monitor_tab.CHART1, "", x, tab_rect.bottom - (section_height + %SETTINGS_BORDER) , section_width, section_height, %SS_Sunken

    Case %WM_OPTIONS_FROM_DIALOG
      Local datav As Long
      Local txtv As String
      ComboBox Get Select Cb.Hndl, %monitor_tab.COMBO1 To datav
      @options.monitor.m_name = @options.monitor.preset(datav - 1).m_name
      ComboBox Get Select Cb.Hndl, %monitor_tab.COMBO2 To datav
      @options.monitor.orientation = monitor_orientation(datav - 1)
      Control Get Check Cb.Hndl, %monitor_tab.CHECK1 To @options.monitor.rotating_desktop

    Case %WM_OPTIONS_TO_DIALOG
      i = 0
      ComboBox Reset Cb.Hndl, %monitor_tab.COMBO1
      While @options.monitor.preset(i).m_name <> ""
        ComboBox Add Cb.Hndl, %monitor_tab.COMBO1, @options.monitor.preset(i).m_name_long
        If @options.monitor.m_name = @options.monitor.preset(i).m_name Then ComboBox Select Cb.Hndl, %monitor_tab.COMBO1, i + 1
        Incr i
      Wend
      If monitor_get_specs(@options.monitor.m_name, @options.monitor) Then SendMessage(Cb.Hndl, %WM_LOAD_RANGE, 0, 0)
      Control Set Text Cb.Hndl, %monitor_tab.LABEL10 + 3, @options.monitor.@monitor.m_aspect

      i = 0
      While monitor_orientation(i) <> ""
        If monitor_orientation(i) = @options.monitor.orientation Then ComboBox Select Cb.Hndl, %monitor_tab.COMBO2, i + 1 : Exit Loop
        Incr i
      Loop
      SendMessage(Cb.Hndl, %WM_UPDATE_ORIENTATION, i, 0)
      Control Set Check Cb.Hndl, %monitor_tab.CHECK1, @options.monitor.rotating_desktop

      r_idx = 0
      Control Send Cb.Hndl, %monitor_tab.UPDOWN, %UDM_SetPos, 0, 0
      SendMessage(h_tab(%tab_index.VIDEO_CARD), %WM_MONITOR_PRESET_UPDATE, 0, 0)

    Case %WM_LOAD_RANGE
      r = @options.monitor.@monitor.m_range(r_idx)
      SendMessage(h_slider1, %TBM_SETRANGE, 0, Mak(Long, r.progressive_lines_min, r.progressive_lines_max))
      SendMessage(h_slider1, %TBM_SETSEL, 0, Mak(Long, r.progressive_lines_min, r.progressive_lines_max))
      SendMessage(h_slider1, %TBM_SETPOS, 0, r.progressive_lines_max)
      SendMessage(h_slider1, %TBM_SETPOS, 1, r.progressive_lines_min)
      SendMessage(h_slider2, %TBM_SETRANGE, 0, Mak(Long, Round(r.h_freq_min / 10, 0), Round(r.h_freq_max / 10, 0)))
      SendMessage(h_slider2, %TBM_SETRANGEMIN, 0, Round(r.h_freq_min / 10, 0))
      SendMessage(h_slider2, %TBM_SETRANGEMAX, 1, Round(r.h_freq_max / 10, 0))
      SendMessage(h_slider3, %TBM_SETRANGE, 1, Mak(Long, Round(r.v_freq_min * 100, 0), Round(r.v_freq_max * 100, 0)))
      SendMessage(Cb.Hndl, %WM_UPDATE_SLIDERS, %monitor_tab.SLIDER1, 0)

    Case %WM_Command
      Select Case As Long Cb.Ctl

        Case %monitor_tab.COMBO1, %monitor_tab.COMBO2
          If Hi(Word, Cb.WParam) = %CBN_SelChange Then
            SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
            SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)
          End If

        Case %monitor_tab.BUTTON1
          edit_file(GetParent(Cb.Hndl), CurDir$ + "\" + "monitor.ini")
          monitor_parse_ini(@options.monitor)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

      End Select

    Case %WM_HScroll
      If Lo(Word, Cb.WParam) = %SB_EndScroll Then Exit Function
      Select Case As Long Cb.LParam
        Case h_slider1
          SendMessage(Cb.Hndl, %WM_UPDATE_SLIDERS, %monitor_tab.SLIDER1, 0)
        Case h_slider2
          SendMessage(Cb.Hndl, %WM_UPDATE_SLIDERS, %monitor_tab.SLIDER2, 0)
        Case h_slider3
          SendMessage(Cb.Hndl, %WM_UPDATE_SLIDERS, %monitor_tab.SLIDER3, 0)

      End Select
      Exit Function

    Case %WM_Notify
      Local p_nmud As NM_UPDOWN Ptr
      p_nmud = Cb.LParam
      Select Case Lo(Word, Cb.WParam)
        Case %monitor_tab.UPDOWN
          If @p_nmud.hdr.code = %UDN_DELTAPOS Then
            If @options.monitor.@monitor.m_range(r_idx + @p_nmud.iDelta).h_freq_min Then
              r_idx += @p_nmud.iDelta
              SendMessage(Cb.Hndl, %WM_LOAD_RANGE, 0, 0)
            Else
              Function = 1 : Exit Function
            End If
          End If
      End Select
      Exit Function

    Case %WM_UPDATE_ORIENTATION
      Graphic Attach Cb.Hndl, %monitor_tab.GRAPH1
      Graphic Clear
      If Cb.WParam = %M_VERTICAL Or Cb.WParam = %M_ROTATING_L Then
        Graphic Box (10,  0) - (47, 47), 20, %Blue, %Black
      Else
        Graphic Box (10, 10) - (60, 47), 20, %Blue, %Black
      End If
      If Cb.WParam = %M_HORIZONTAL Or Cb.WParam = %M_ROTATING_L Then
        Graphic Box (80, 10) - (130, 47), 20, %Blue, %Black
      Else
        Graphic Box (80,  0) - (117, 47), 20, %Blue, %Black
      End If
      If Cb.WParam = %M_HORIZONTAL Or Cb.WParam = %M_ROTATING_R Then
        Graphic Box (12,  12) - (58, 45),, %White, %Gray, 3
      ElseIf Cb.WParam = %M_ROTATING_L Then
        Graphic Box (12,  2) - (45, 45),, %White, %Gray, 3
      ElseIf Cb.WParam = %M_VERTICAL Then
        Graphic Box (12, 12) - (45, 35),, %White, %Gray, 3
      End If
      If Cb.WParam = %M_VERTICAL Or Cb.WParam = %M_ROTATING_R Then
        Graphic Box (82,  2) - (115, 45),, %White, %Gray, 3
      ElseIf Cb.WParam = %M_ROTATING_L Then
        Graphic Box (82, 12) - (128, 45),, %White, %Gray, 3
      ElseIf Cb.WParam = %M_HORIZONTAL Then
        Graphic Box (92, 12) - (118, 45),, %White, %Gray, 3
      End If

    Case %WM_UPDATE_SLIDERS
      Local p_lines As Long
      Local h_freq, v_freq, h_freq_min, h_freq_max, v_freq_min, v_freq_max As Double
      Local t As MONITOR_RANGE
      t = r

      p_lines = SendMessage(h_slider1, %TBM_GETPOS, 0, 0)
      h_freq_max = r.h_freq_max
      h_freq_min = SendMessage(h_slider2, %TBM_GETSELSTART, 0, 0) * 10
      h_freq = Max(h_freq_min, SendMessage(h_slider2, %TBM_GETPOS, 0, 0) * 10)
      v_freq_max = SendMessage(h_slider3, %TBM_GETSELEND, 0, 0) / 100
      v_freq_min = r.v_freq_min
      v_freq = Min(v_freq_max, SendMessage(h_slider3, %TBM_GETPOS, 0, 0) / 100)

      If Cb.WParam = %monitor_tab.SLIDER1 Or Cb.WParam = %monitor_tab.SLIDER2 Then v_freq_max = 1 / (p_lines / h_freq + (t.v_front_porch + t.v_sync_pulse + t.v_back_porch))
      If Cb.WParam = %monitor_tab.SLIDER1 Or Cb.WParam = %monitor_tab.SLIDER3 Then h_freq_min = p_lines / (1 / Min(v_freq, v_freq_max) - (t.v_front_porch + t.v_sync_pulse + t.v_back_porch))

      h_freq = Max(Min(h_freq, h_freq_max), h_freq_min)
      v_freq = Max(Min(v_freq, v_freq_max), v_freq_min)
      SendMessage(h_slider2, %TBM_SETPOS, 0, Int(h_freq / 10))
      SendMessage(h_slider3, %TBM_SETPOS, 0, Round(v_freq * 100, 0))
      SendMessage(h_slider2, %TBM_SETSEL, 1, Mak(Long, Round(Max(r.h_freq_min, h_freq_min) / 10, 0), Round(Min(r.h_freq_max, h_freq_max) / 10, 0)))
      SendMessage(h_slider3, %TBM_SETSEL, 1, Mak(Long, Round(Max(r.v_freq_min, v_freq_min) * 100, 0), Round(Min(r.v_freq_max, v_freq_max) * 100, 0)))

      Control Set Text Cb.Hndl, %monitor_tab.LABEL10 + 5, Using$("  ####", p_lines)
      Control Set Text Cb.Hndl, %monitor_tab.LABEL10 + 7, Using$("##.###", h_freq / 1000)
      Control Set Text Cb.Hndl, %monitor_tab.LABEL10 + 9, Using$("###.##", v_freq)

      Graphic Attach Cb.Hndl, %monitor_tab.CHART1
      t.h_freq_min = h_freq
      t.v_freq_min = v_freq
      timing_chart_from_monitor_range(t)

    Case Else
      Exit Function
  End Select

  Function = 1
End Function

'============================================================
'  settings_videocard_proc
'============================================================

CallBack Function settings_videocard_proc() As Long

  Static vmm As APP_DATA Ptr
  Static options As APP_OPTIONS Ptr
  Static h_root As Long
  Static max_modes_auto, min_pclock_auto As Long
  Static edid_from_modelist As Long
  Static csync_enabled As Long
  Local i, j As Long
  Local file_name As AsciiZ * 256

  Select Case As Long CbMsg

    Case %WM_InitDialog

      Dialog Get User GetParent(Cb.Hndl), 1 To vmm
      Dialog Get User GetParent(Cb.Hndl), 2 To h_root
      options = VarPtr(@vmm.options)

      Local x, y As Long
      x = %SETTINGS_BORDER: y = %SETTINGS_BORDER
      Control Add Frame,    Cb.Hndl, %videocard_tab.FRAME1, "Video card", x, y, 608, 178, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL1, "Device:", x + 8, y + 22, 48, 18
      Control Add ComboBox, Cb.Hndl, %videocard_tab.COMBO1,, x + 64, y + 18, 528, 160, %CBS_DropDownList Or %WS_TabStop Or %WS_VScroll
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL2, "Driver:", x + 8, y + 48, 48, 18
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL3, "", x + 64, y + 48, 160, 18
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL6, "Method:", x + 8, y + 72, 48, 18
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL7, "", x + 64, y + 72, 160, 18
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL4, "Max. number of modes:", x + 8, y + 96, 120, 18
      Control Add CheckBox, Cb.Hndl, %videocard_tab.CHECK1, "Auto", x + 16, y + 120, 48, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add TextBox,  Cb.Hndl, %videocard_tab.TEXTBOX1, "", x + 72, y + 118, 48, 18
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL5, "Minimum dotclock (MHz):", x + 8 + 160, y + 96, 120, 18
      Control Add CheckBox, Cb.Hndl, %videocard_tab.CHECK2, "Auto", x + 16 + 160, y + 120, 48, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add TextBox,  Cb.Hndl, %videocard_tab.TEXTBOX2, "", x + 72 + 160, y + 118, 48, 18
      Control Add CheckBox, Cb.Hndl, %videocard_tab.CHECK3, "Extend desktop automatically on device restart", x + 16, y + 148, 240, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Button,   Cb.Hndl, %videocard_tab.BUTTON5, "Import modes from driver", x + 433, y + 60, 160, 24
      Control Add Button,   Cb.Hndl, %videocard_tab.BUTTON2, "Import modes from file...", x + 433, y + 86, 160, 24
      Control Add Button,   Cb.Hndl, %videocard_tab.BUTTON3, "Export modes to file...", x + 433, y + 112, 160, 24
      Control Add Button,   Cb.Hndl, %videocard_tab.BUTTON4, "Delete all modes from driver", x + 433, y + 138, 160, 24

      y += 182
      Control Add Frame,    Cb.Hndl, %videocard_tab.FRAME2, "EDID emulation (AMD HD 5xxx and newer)", x, y, 608, 80, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL8, "Output:", x + 8, y + 34, 48, 18
      Control Add ComboBox, Cb.Hndl, %videocard_tab.COMBO2,, x + 64, y + 30, 280, 160, %CBS_DropDownList Or %WS_TabStop Or %WS_VScroll
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL9, "Emulation:", x + 372, y + 34, 48, 18
      Control Add Button,   Cb.Hndl, %videocard_tab.BUTTON1, "", x + 433, y + 28, 160, 24
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL10, "", x + 433, y, 160, 18, %SS_NoWordWrap
      Control Set Color     Cb.Hndl, %videocard_tab.LABEL10, %rgb_Blue, -1&
      Control Add CheckBox, Cb.Hndl, %videocard_tab.CHECK4, "Add modes from mode list", x + 433, y + 60, 160, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop

      y += 84
      Control Add Frame,    Cb.Hndl, %videocard_tab.FRAME3, "Composite sync", x, y, 608, 54, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Button,   Cb.Hndl, %videocard_tab.BUTTON6, "", x + 433, y + 18, 160, 24
      Control Add Label,    Cb.Hndl, %videocard_tab.LABEL11, "For legacy cards (pre-HD 5xxx), after enabling c-sync you must set both sync polarities to positive (1) in your monitor preset "_
                                                            +"and regenerate and install all video modes.", x + 10, y + 18, 412, 32
      max_modes_auto = IIf(@options.mode_db.total_modes = "auto", 1, 0)
      min_pclock_auto = IIf(@options.modeline.s_pclock_min = "auto", 1, 0)

    Case %WM_MONITOR_PRESET_UPDATE
      Control Set Text Cb.Hndl, %videocard_tab.LABEL10, Using$("(current preset is &)", @options.monitor.m_name)

    Case %WM_OPTIONS_FROM_DIALOG
      Local datav As Long
      Local txtv As String
      ComboBox Get Select Cb.Hndl, %videocard_tab.COMBO1 To datav
      @options.display.device_key = display_get_device_key_by_index(datav - 1)
      Control Get Text Cb.Hndl, %videocard_tab.TEXTBOX1 To txtv
      @options.mode_db.total_modes = IIf$(max_modes_auto, "auto", txtv)
      Control Get Text Cb.Hndl, %videocard_tab.TEXTBOX2 To txtv
      @options.modeline.s_pclock_min = IIf$(min_pclock_auto, "auto", txtv)
      @options.modeline.pclock_min = Val(@options.modeline.s_pclock_min) * 1000000
      Control Get Check Cb.Hndl, %videocard_tab.CHECK3 To @options.display.auto_extend_desktop
      Control Get Check Cb.Hndl, %videocard_tab.CHECK4 To @options.edid.from_modelist

    Case %WM_OPTIONS_TO_DIALOG
      j = display_get_device_num()
      ComboBox Reset Cb.Hndl, %videocard_tab.COMBO1
      For i = 0 To j
        ComboBox Add Cb.Hndl, %videocard_tab.COMBO1, display_get_device_long_name_by_index(i)
        If display_get_device_key_by_index(i) = @options.display.device_key Then ComboBox Select Cb.Hndl, %videocard_tab.COMBO1, i + 1
      Next
      Control Set Text Cb.Hndl, %videocard_tab.LABEL7, custom_video_get_method_name()
      Control Set Text Cb.Hndl, %videocard_tab.LABEL3, custom_video_get_driver_name()
      Control Set Color Cb.Hndl, %videocard_tab.LABEL3, IIf(@vmm.driver_compatible, %rgb_LimeGreen, %Black), -1&
      Control ReDraw Cb.Hndl, %videocard_tab.LABEL3
      Control Set Check Cb.Hndl, %videocard_tab.CHECK1, max_modes_auto
      Control Set Check Cb.Hndl, %videocard_tab.CHECK2, min_pclock_auto
      Control Set Check Cb.Hndl, %videocard_tab.CHECK3, @options.display.auto_extend_desktop
      Control Set Check Cb.Hndl, %videocard_tab.CHECK4, @options.edid.from_modelist
      Control Set Text Cb.Hndl, %videocard_tab.TEXTBOX1, IIf$(max_modes_auto, Str$(custom_video_get_max_modes()), @options.mode_db.total_modes)
      Control Set Text Cb.Hndl, %videocard_tab.TEXTBOX2, IIf$(min_pclock_auto, Using$("#.##", custom_video_get_min_dotclock()), @options.modeline.s_pclock_min)
      If max_modes_auto Then Control Disable Cb.Hndl, %videocard_tab.TEXTBOX1 Else Control Enable Cb.Hndl, %videocard_tab.TEXTBOX1
      If min_pclock_auto Then Control Disable Cb.Hndl, %videocard_tab.TEXTBOX2 Else Control Enable Cb.Hndl, %videocard_tab.TEXTBOX2
      csync_enabled = custom_video_csync_read()
      If @vmm.driver_compatible Then
        Control Enable Cb.Hndl, %videocard_tab.BUTTON6
        Control Set Text Cb.Hndl, %videocard_tab.BUTTON6, IIf$(csync_enabled, "Disable", "Enable") + " composite sync"
        Control Set Text Cb.Hndl, %videocard_tab.FRAME3, "Composite sync (" + display_get_device_name_from_key(@options.display.device_key) + ")"
      Else
        Control Disable Cb.Hndl, %videocard_tab.BUTTON6
      End If
      SendMessage(Cb.Hndl, %WM_EDID_EMULATION_UPDATE, 0, 0)

    Case %WM_EDID_EMULATION_UPDATE
      If @vmm.driver_compatible Then
        Control Enable Cb.Hndl, %videocard_tab.LABEL8
        Control Enable Cb.Hndl, %videocard_tab.COMBO2
        Control Enable Cb.Hndl, %videocard_tab.LABEL9
        Control Enable Cb.Hndl, %videocard_tab.BUTTON1

        Local edid_select As Long
        ComboBox Get Select Cb.Hndl, %videocard_tab.COMBO2 To edid_select
        If edid_select = 0 Then edid_select = 1
        ComboBox Reset Cb.Hndl, %videocard_tab.COMBO2

        Local edid As EDID_BLOCK
        Local edid_emulation_enabled As Long
        Local monitor_name, connector_label As String

        i = 0
        connector_label = ""
        While custom_video_get_connectors(i, connector_label)
          Incr i
          edid_emulation_enabled = custom_video_edid_emulation_read(Parse$(connector_label, "-", 1), edid)
          monitor_name = IIf$(edid_emulation_enabled, "enabled - " + edid_get_monitor_name(edid), "disabled")
          ComboBox Add Cb.Hndl, %videocard_tab.COMBO2, connector_label + " - " + monitor_name
          If edid_select = i Then
            ComboBox Select Cb.Hndl, %videocard_tab.COMBO2, edid_select
            Control Set Text Cb.Hndl, %videocard_tab.BUTTON1, IIf$(edid_emulation_enabled, "Disable", "Enable") + " EDID emulation"
            Control Set User Cb.Hndl, %videocard_tab.BUTTON1, 1, edid_emulation_enabled
          End If
          connector_label = ""
        Wend
      Else
        Control Disable Cb.Hndl, %videocard_tab.LABEL8
        Control Disable Cb.Hndl, %videocard_tab.COMBO2
        Control Disable Cb.Hndl, %videocard_tab.LABEL9
        Control Disable Cb.Hndl, %videocard_tab.BUTTON1
      End If

    Case %WM_HARD_RESET
      display_wait_hardware_change(GetParent(Cb.Hndl))
      command_execute(@vmm, $CMD_DISPLAY, $DI_INIT, @options.display.device_key)
      SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

    Case %WM_Command
      Select Case As Long Cb.Ctl

        Case %videocard_tab.CHECK1
          max_modes_auto Xor= 1
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %videocard_tab.CHECK2
          min_pclock_auto Xor= 1
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %videocard_tab.CHECK4
          edid_from_modelist Xor= 1
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %videocard_tab.COMBO1
          If Hi(Word, Cb.WParam) = %CBN_SelChange Then
            SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
            command_execute(@vmm, $CMD_DISPLAY, $DI_INIT, @options.display.device_key)
            SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)
          End If

        Case %videocard_tab.COMBO2
          If Hi(Word, Cb.WParam) = %CBN_SelChange Then
            SendMessage(Cb.Hndl, %WM_EDID_EMULATION_UPDATE, 0, 0)
          End If

        Case %videocard_tab.BUTTON1
          Control Disable Cb.Hndl, %videocard_tab.BUTTON1
          Control Get User Cb.Hndl, %videocard_tab.BUTTON1, 1 To edid_emulation_enabled
          Control Get Text Cb.Hndl, %videocard_tab.COMBO2 To connector_label
          command_execute(@vmm, $CMD_EDID, IIf$(edid_emulation_enabled, $ED_STOP, $ED_START), Parse$(connector_label, "-", 1))
          SendMessage(Cb.Hndl, %WM_HARD_RESET, 0, 0)

        Case %videocard_tab.BUTTON5
          command_execute(@vmm, $CMD_MODELIST, $ML_IMPORT, "")

        Case %videocard_tab.BUTTON2
          Display Openfile Cb.Hndl,,, "Import mode list from file", "", ".txt" + Chr$(0) + "*.txt" + Chr$(0), "", "", %OFN_FileMustExist Or %OFN_PathMustExist Or %OFN_NoChangeDir Or %OFN_EnableSizing To file_name
          If file_name <> "" Then command_execute(@vmm, $CMD_MODELIST, $ML_IMPORT, file_name)

        Case %videocard_tab.BUTTON3
          Display Savefile Cb.Hndl,,, "Export mode list as", "", ".txt" + Chr$(0) + "*.txt" + Chr$(0), "", "", %OFN_OverWritePrompt Or %OFN_PathMustExist Or %OFN_NoChangeDir Or %OFN_EnableSizing To file_name
          If file_name <> "" Then command_execute(@vmm, $CMD_MODELIST, $ML_EXPORT, file_name + IIf$(PathName$(Extn, file_name) = "", ".txt", ""))

        Case %videocard_tab.BUTTON4
          Local result As Long
          result = MsgBox ("All existing custom modes will be deleted from the driver." + $CrLf + $CrLf + "Do you want to continue?" + $CrLf, %MB_OkCancel Or %MB_IconWarning, $APP_NAME)
          If result = %IdOk Then
            command_execute(@vmm, $CMD_MODELIST, $ML_UNINSTALL)
            If custom_video_get_method() = %CUSTOM_VIDEO_TIMING_ATI_LEGACY Then SendMessage(Cb.Hndl, %WM_HARD_RESET, 0, 0)
          End If

       Case %videocard_tab.BUTTON6
          Control Disable Cb.Hndl, %videocard_tab.BUTTON6
          command_execute(@vmm, $CMD_CSYNC, IIf$(csync_enabled, $CS_DISABLE, $CS_ENABLE))
          SendMessage(Cb.Hndl, %WM_HARD_RESET, 0, 0)

      End Select

    Case Else
      Exit Function
  End Select

  Function = 1
End Function

'============================================================
'  settings_user_modes_proc
'============================================================

CallBack Function settings_user_modes_proc() As Long

  Static vmm As APP_DATA Ptr
  Static options As APP_OPTIONS Ptr

  Select Case As Long CbMsg

    Case %WM_InitDialog

      Dialog Get User GetParent(Cb.Hndl), 1 To vmm
      options = VarPtr(@vmm.options)

      Local x, y, col_width As Long
      x = %SETTINGS_BORDER: y = %SETTINGS_BORDER
      col_width = (%SETTINGS_WIDTH - %SETTINGS_BORDER * 2) / 2
      Control Add Frame,    Cb.Hndl, %custom_tab.FRAME1, "User video mode list processing", x, y, col_width, 96, %WS_Child Or %WS_Visible Or %BS_Groupbox Or %WS_TabStop, %WS_Ex_Transparent
      Control Add CheckBox, Cb.Hndl, %custom_tab.CHECK1, "Get video modes from user list", x + 8, y + 24, 180, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add TextBox,  Cb.Hndl, %custom_tab.TEXTBOX3, "", x + 8, y + 42, 295, 18
      Control Add Button,   Cb.Hndl, %custom_tab.BUTTON1, "Browse...", x + 240, y + 62, 64, 24, %WS_TabStop
      Control Add Button,   Cb.Hndl, %custom_tab.BUTTON2, "Edit...", x + 168, y + 62, 64, 24, %WS_TabStop

      y += 104
      Control Add Frame,    Cb.Hndl, %custom_tab.FRAME2, "User video mode table options", x, y, col_width, 96, %WS_Child Or %WS_Visible Or %BS_Groupbox Or %WS_TabStop, %WS_Ex_Transparent
      Control Add Label,    Cb.Hndl, %custom_tab.LABEL1, "Mode table method:", x + 136, y + 30, 120, 18
      Control Add ComboBox, Cb.Hndl, %custom_tab.COMBO1,, x + 240, y + 26, 64, 160, %CBS_DropDownList Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %custom_tab.LABEL2, "X-res mininum:", x + 8, y + 30, 72, 18
      Control Add TextBox,  Cb.Hndl, %custom_tab.TEXTBOX1, "", x + 88, y + 26, 32, 18
      Control Add Label,    Cb.Hndl, %custom_tab.LABEL3, "Y-res minimum:", x + 8, y + 56, 72, 18
      Control Add TextBox,  Cb.Hndl, %custom_tab.TEXTBOX2, "", x + 88, y + 52, 32, 18
      Control Add Label,    Cb.Hndl, %custom_tab.LABEL4, "Y-res round to:", x + 136, y + 56, 120, 18
      Control Add ComboBox, Cb.Hndl, %custom_tab.COMBO2,, x + 240, y + 52, 64, 160, %CBS_DropDownList Or %WS_TabStop
      ComboBox Add Cb.Hndl, %custom_tab.COMBO1, "static"
      ComboBox Add Cb.Hndl, %custom_tab.COMBO1, "dynamic"
      ComboBox Add Cb.Hndl, %custom_tab.COMBO1, "magic"
      Local i, j As Long
      For i = 0 To 4
        j = 1 : Shift Left j, i
        ComboBox Add Cb.Hndl, %custom_tab.COMBO2, Using$("# line", j) + IIf$(j > 1, "s", "")
        If @options.mode_db.y_res_round_user = j Then ComboBox Select Cb.Hndl, %custom_tab.COMBO2, i + 1
      Next

      x = %SETTINGS_BORDER: y = %SETTINGS_BORDER
      Control Add TextBox,  Cb.Hndl, %mame_tab.TEXTBOX4, Resource$(RcData, 512), col_width + %SETTINGS_BORDER * 3, y + 8, 290, 310, %ES_MultiLine Or %ES_AutoVScroll Or %ES_ReadOnly Or %WS_VScroll

    Case %WM_OPTIONS_FROM_DIALOG
      Local datav As Long
      Local txtv As String
      Control Get Check Cb.Hndl, %custom_tab.CHECK1 To @options.user.list_user_modes
      Control Get Text Cb.Hndl, %custom_tab.TEXTBOX3 To @options.user.mode_list
      Control Get Text Cb.Hndl, %custom_tab.TEXTBOX1 To txtv
      @options.mode_db.x_res_min_user = Val ( txtv )
      Control Get Text Cb.Hndl, %custom_tab.TEXTBOX2 To txtv
      @options.mode_db.y_res_min_user = Val ( txtv )
      ComboBox Get Select Cb.Hndl, %custom_tab.COMBO2 To datav
      @options.mode_db.y_res_round_user = 2 ^ (datav - 1)
      ComboBox Get Select Cb.Hndl, %custom_tab.COMBO1 To datav
      @options.mode_db.mode_table_method_user = datav - 1

    Case %WM_OPTIONS_TO_DIALOG
      Control Set Text Cb.Hndl, %custom_tab.TEXTBOX3, @options.user.mode_list
      Control Set Text Cb.Hndl, %custom_tab.TEXTBOX1, Str$(@options.mode_db.x_res_min_user)
      Control Set Text Cb.Hndl, %custom_tab.TEXTBOX2, Str$(@options.mode_db.y_res_min_user)
      ComboBox Select Cb.Hndl, %custom_tab.COMBO1, @options.mode_db.mode_table_method_user + 1
      Control Set Check Cb.Hndl, %custom_tab.CHECK1, @options.user.list_user_modes
      If @options.user.list_user_modes Then
        Control Enable Cb.Hndl, %custom_tab.BUTTON1
        Control Enable Cb.Hndl, %custom_tab.BUTTON2
        Control Enable Cb.Hndl, %custom_tab.TEXTBOX3
      Else
        Control Disable Cb.Hndl, %custom_tab.BUTTON1
        Control Disable Cb.Hndl, %custom_tab.BUTTON2
        Control Disable Cb.Hndl, %custom_tab.TEXTBOX3
      End If

    Case %WM_Command
      Select Case As Long Cb.Ctl

        Case %custom_tab.BUTTON1
          Local user_path As String
          Display Openfile Cb.Hndl,,, "Select user mode list file", "", "ini files" + Chr$(0) + "*.ini" + Chr$(0), "", "", %OFN_FileMustExist Or %OFN_PathMustExist Or %OFN_NoChangeDir Or %OFN_EnableSizing To user_path
          If user_path <> "" Then Control Set Text Cb.Hndl, %custom_tab.TEXTBOX3, user_path
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %custom_tab.BUTTON2
          edit_file(GetParent(Cb.Hndl), @options.user.mode_list)

        Case %custom_tab.CHECK1
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

      End Select

    Case Else
      Exit Function
  End Select

  Function = 1
End Function

'============================================================
'  settings_mame_proc
'============================================================

CallBack Function settings_mame_proc() As Long

  Static vmm As APP_DATA Ptr
  Static options As APP_OPTIONS Ptr

  Select Case As Long CbMsg

    Case %WM_InitDialog

      Dialog Get User GetParent(Cb.Hndl), 1 To vmm
      options = VarPtr(@vmm.options)

      Local x, y, col_width As Long
      x = %SETTINGS_BORDER : y = %SETTINGS_BORDER
      col_width = (%SETTINGS_WIDTH - %SETTINGS_BORDER * 2) / 2
      Control Add Frame,    Cb.Hndl, %mame_tab.FRAME1,  "MAME", x, y, col_width, 92, %WS_Child Or %WS_Visible Or %BS_Groupbox Or %WS_TabStop, %WS_Ex_Transparent
      Control Add Label,    Cb.Hndl, %mame_tab.LABEL5,  "MAME executable file path:", x + 8, y + 24, 170, 18
      Control Add TextBox,  Cb.Hndl, %mame_tab.TEXTBOX1,"", x + 8, y + 42, 295, 18
      Control Add CheckBox, Cb.Hndl, %mame_tab.CHECK4,  "Export monitor settings to GroovyMAME", x + 28, y + 68, 210, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Button,   Cb.Hndl, %mame_tab.BUTTON1, "Browse...", x + 240, y + 62, 64, 24, %WS_TabStop

      y + = 100
      Control Add Frame,    Cb.Hndl, %mame_tab.FRAME3,  "XML list processing", x, y, (%SETTINGS_WIDTH - %SETTINGS_BORDER * 2)/2, 136, %WS_Child Or %WS_Visible Or %BS_Groupbox Or %WS_TabStop, %WS_Ex_Transparent
      Control Add CheckBox, Cb.Hndl, %mame_tab.CHECK1,  "Get video modes from MAME XML", x + 8, y + 20, 248, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add CheckBox, Cb.Hndl, %mame_tab.CHECK2,  "Generate XML from MAME executable", x + 8, y + 40, 200, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %mame_tab.LABEL6,  "MAME favourites file path:", x + 8, y + 66, 170, 18
      Control Add TextBox,  Cb.Hndl, %mame_tab.TEXTBOX4,"", x + 8, y + 86, 295, 18
      Control Add CheckBox, Cb.Hndl, %mame_tab.CHECK3,  "Only list favourites", x + 28, y + 112, 160, 16, %WS_Child Or %WS_Visible Or %BS_AutoCheckbox Or %WS_Group Or %WS_TabStop
      Control Add Button,   Cb.Hndl, %mame_tab.BUTTON2, "Browse...", x + 240, y + 106, 64, 24, %WS_TabStop
      Control Add Button,   Cb.Hndl, %mame_tab.BUTTON3, "Edit...", x + 240, y + 60, 64, 24, %WS_TabStop

      y += 144
      Control Add Frame,    Cb.Hndl, %mame_tab.FRAME2, "XML video mode table options", x, y, (%SETTINGS_WIDTH - %SETTINGS_BORDER * 2)/2, 76, %WS_Child Or %WS_Visible Or %BS_Groupbox Or %WS_TabStop, %WS_Ex_Transparent
      Control Add Label,    Cb.Hndl, %mame_tab.LABEL1, "Mode table method:", x + 136, y + 22, 120, 18
      Control Add ComboBox, Cb.Hndl, %mame_tab.COMBO2,, x + 240, y + 18, 64, 160, %CBS_DropDownList Or %WS_TabStop
      Control Add Label,    Cb.Hndl, %mame_tab.LABEL2, "X-res mininum:", x + 8, y + 22, 72, 18
      Control Add TextBox,  Cb.Hndl, %mame_tab.TEXTBOX2, "", x + 88, y + 18, 32, 18
      Control Add Label,    Cb.Hndl, %mame_tab.LABEL3, "Y-res minimum:", x + 8, y + 48, 72, 18
      Control Add TextBox,  Cb.Hndl, %mame_tab.TEXTBOX3, "", x + 88, y + 44, 32, 18
      Control Add Label,    Cb.Hndl, %mame_tab.LABEL4, "Y-res round to:", x + 136, y + 48, 120, 18
      Control Add ComboBox, Cb.Hndl, %mame_tab.COMBO1,, x + 240, y + 44, 64, 160, %CBS_DropDownList Or %WS_TabStop
      ComboBox Add Cb.Hndl, %mame_tab.COMBO2, "static"
      ComboBox Add Cb.Hndl, %mame_tab.COMBO2, "dynamic"
      ComboBox Add Cb.Hndl, %mame_tab.COMBO2, "magic"
      Local i, j As Long
      For i = 0 To 4
        j = 1 : Shift Left j, i
        ComboBox Add Cb.Hndl, %mame_tab.COMBO1, Using$("# line", j) + IIf$(j > 1, "s", "")
        If @options.mode_db.y_res_round_xml = j Then ComboBox Select Cb.Hndl, %mame_tab.COMBO1, i + 1
      Next

      x = %SETTINGS_BORDER : y = %SETTINGS_BORDER
      Control Add TextBox,  Cb.Hndl, %mame_tab.TEXTBOX5, Resource$(RcData, 512), col_width + %SETTINGS_BORDER * 3, y + 8, 290, 310, %ES_MultiLine Or %ES_AutoVScroll Or %ES_ReadOnly Or %WS_VScroll

    Case %WM_OPTIONS_FROM_DIALOG
      Local datav As Long
      Local txtv As String
      Control Get Check Cb.Hndl, %mame_tab.CHECK1 To @options.mame.list_xml_modes
      Control Get Check Cb.Hndl, %mame_tab.CHECK2 To @options.mame.generate_xml
      Control Get Check Cb.Hndl, %mame_tab.CHECK3 To @options.mame.only_list_favourites
      Control Get Check Cb.Hndl, %mame_tab.CHECK4 To @options.mame.export_settings
      Control Get Text Cb.Hndl, %mame_tab.TEXTBOX1 To @options.mame.exe_path
      Control Get Text Cb.Hndl, %mame_tab.TEXTBOX4 To @options.mame.favourites
      Control Get Text Cb.Hndl, %mame_tab.TEXTBOX2 To txtv
      @options.mode_db.x_res_min_xml = Val ( txtv )
      Control Get Text Cb.Hndl, %mame_tab.TEXTBOX3 To txtv
      @options.mode_db.y_res_min_xml = Val ( txtv )
      ComboBox Get Select Cb.Hndl, %mame_tab.COMBO1 To datav
      @options.mode_db.y_res_round_xml = 2 ^ (datav - 1)
      ComboBox Get Select Cb.Hndl, %mame_tab.COMBO2 To datav
      @options.mode_db.mode_table_method_xml = datav - 1

    Case %WM_OPTIONS_TO_DIALOG
      Control Set Text Cb.Hndl, %mame_tab.TEXTBOX1, @options.mame.exe_path
      Control Set Text Cb.Hndl, %mame_tab.TEXTBOX4, @options.mame.favourites
      Control Set Text Cb.Hndl, %mame_tab.TEXTBOX2, Str$(@options.mode_db.x_res_min_xml)
      Control Set Text Cb.Hndl, %mame_tab.TEXTBOX3, Str$(@options.mode_db.y_res_min_xml)
      ComboBox Select Cb.Hndl, %mame_tab.COMBO2, @options.mode_db.mode_table_method_xml + 1
      Control Set Check Cb.Hndl, %mame_tab.CHECK1, @options.mame.list_xml_modes
      Control Set Check Cb.Hndl, %mame_tab.CHECK2, @options.mame.generate_xml
      Control Set Check Cb.Hndl, %mame_tab.CHECK3, @options.mame.only_list_favourites
      Control Set Check Cb.Hndl, %mame_tab.CHECK4, @options.mame.export_settings
      If @options.mame.list_xml_modes Then
        Control Enable Cb.Hndl, %mame_tab.CHECK2
        Control Enable Cb.Hndl, %mame_tab.CHECK3
        Control Enable Cb.Hndl, %mame_tab.TEXTBOX4
        Control Enable Cb.Hndl, %mame_tab.BUTTON2
        Control Enable Cb.Hndl, %mame_tab.BUTTON3
        Control Enable Cb.Hndl, %mame_tab.LABEL6
      Else
        Control Disable Cb.Hndl, %mame_tab.CHECK2
        Control Disable Cb.Hndl, %mame_tab.CHECK3
        Control Disable Cb.Hndl, %mame_tab.TEXTBOX4
        Control Disable Cb.Hndl, %mame_tab.BUTTON2
        Control Disable Cb.Hndl, %mame_tab.BUTTON3
        Control Disable Cb.Hndl, %mame_tab.LABEL6
      End If

    Case %WM_Command
      Select Case As Long Cb.Ctl

        Case %mame_tab.CHECK1, %mame_tab.CHECK2, %mame_tab.CHECK3
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %mame_tab.BUTTON1
          Local mame_path As String
          Display Openfile Cb.Hndl,,, "Select MAME executable file", "", "exe files" + Chr$(0) + "*.exe" + Chr$(0), "", "", %OFN_FileMustExist Or %OFN_PathMustExist Or %OFN_NoChangeDir Or %OFN_EnableSizing To mame_path
          If mame_path <> "" Then Control Set Text Cb.Hndl, %mame_tab.TEXTBOX1, mame_path
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %mame_tab.BUTTON2
          Local favourites_path As String
          Display Openfile Cb.Hndl,,, "Select MAME favourite list file", "", "ini files" + Chr$(0) + "*.ini" + Chr$(0), "", "", %OFN_FileMustExist Or %OFN_PathMustExist Or %OFN_NoChangeDir Or %OFN_EnableSizing To favourites_path
          If favourites_path <> "" Then Control Set Text Cb.Hndl, %mame_tab.TEXTBOX4, favourites_path
          SendMessage(Cb.Hndl, %WM_OPTIONS_FROM_DIALOG, 0, 0)
          SendMessage(Cb.Hndl, %WM_OPTIONS_TO_DIALOG, 0, 0)

        Case %mame_tab.BUTTON3
          edit_file(GetParent(Cb.Hndl), @options.mame.favourites)

      End Select

    Case Else
      Exit Function
  End Select

  Function = 1
End Function

'============================================================
'  edit_file
'============================================================

Function edit_file(h_parent As Long, file_name As AsciiZ * 256) As Long

  Local h_dummy As Long
  Dialog New Pixels, h_parent, "Editing " + file_name,,, 160, 48, %WS_Overlapped, To h_dummy
  Control Add Label, h_dummy, 0, "Close Notepad when done...", 8, 16, 144, 16
  Dialog Set User h_dummy, 1, VarPtr(file_name)

  Local h_thread As Long
  Thread Create edit_file_wt(VarPtr(h_dummy)) To h_thread
  Dialog Show Modal h_dummy

End Function

Thread Function edit_file_wt(ByVal h_dummy As Long Ptr) As Long

  Local file_name As AsciiZ Ptr * 256
  Dialog Get User @h_dummy, 1 To file_name

  Local system_directory As AsciiZ * 256
  GetSystemDirectory(system_directory, SizeOf(system_directory))

  Local nresult As Long
  nresult = launch_command(system_directory + "\notepad.exe", @file_name + "", "")
  Dialog Send @h_dummy, %WM_SYSCOMMAND, %SC_Close, 0

 Function = nresult
End Function
