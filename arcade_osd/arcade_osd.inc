'==============================================================================
'  Arcade OSD
'  Custom video editor
'
'  Author: Antonio Giner González
'  Date:   January 2019
'
'  arcade_osd.inc
'==============================================================================

#Include Once "..\lib\monitor.inc"
#Include Once "..\lib\modeline.inc"
#Include Once "..\lib\display.inc"
#Include Once "..\lib\custom_video.inc"
#Include Once "..\lib\log_console.inc"
#Include Once "..\lib\util.inc"
#Include "version.inc"

'============================================================
'  Constants
'============================================================

$APP_CLASS = "Arcade OSD"
$APP_TITLE = "Arcade OSD"

%DOT_CLOCK_MAX = 10000
%HTOT_MAX = 2560
%VTOT_MAX = 1600
%MODES_MAX = 4 * 1024
%MAXIMUM_LONG  = &h7FFFFFFF


%MENU_HEADER_MAX = 3
%MENU_OPTION_MAX = 4 * 1024
%MENU_HELP_MAX = 2

%NULL = 0

' OSD size
%OSD_HEIGHT = 16
%OSD_WIDTH = 40
%OSD_SIZE = 0
%OSD_SIZE_AND_CENTER = 1

' Colors
%DBLUE = &h550000
%LBLUE = &hA50000

' Debug
%DEBUG_CONSOLE = 1000
%DEBUG_WIDTH = 640
%DEBUG_HEIGHT = 480

' Common
%DISABLED = 0
%ENABLED = 1
%NONE = 0
%RESET = 128
%REDRAW = 129
%REFRESH = 130
%RESIZE = 131
%RESIZE_CENTER = 132
%M_VFREQ = 134
%TEST = 135
%SAVE = 136
%FULLSCREEN_TURN_ON = 137
%FULLSCREEN_TURN_OFF = 138

' Menu index
%START_MENU = 1
%MAIN_MENU = 2
%EDIT_MENU = 3
%EDIT_START = 4
%HORZ_GEOMETRY = 5
%VERT_GEOMETRY = 6
%EDIT_MODELINE = 7
%PAGE_UP = 8
%PAGE_DOWN = 9
%DESKTOP_MODE = 10

' Start menu
%ATTACH_CURRENT = 50
%SWITCH_MONITOR = 51
%LOCK_UNSUPPORTEDMODES = 52
%LOCK_UNSUPPORTED_SET = 53
%GET_MODE_FROM_CLIPBOARD = 54
%SET_MODE_FROM_CLIPBOARD = 55

' Edit menu
%MODE_N = 100
%MODE_N_DEC = 101
%MODE_N_INC = 102
%RETURN_TO_MAIN = 103
%SET_DESKTOP_MODE = 104
%COPY_MODE_TO_CLIPBOARD = 106
%EXIT = 120

' Horizontal geometry
%H_CENTER = 200
%H_CENTER_DEC = 201
%H_CENTER_INC = 202
%H_AMP = 203
%H_AMP_DEC = 204
%H_AMP_INC = 205
%H_ACT = 206
%H_ACT_DEC = 207
%H_ACT_INC = 208
%H_F_PORCH = 209
%H_F_PORCH_DEC = 210
%H_F_PORCH_INC = 211
%H_SYNC = 212
%H_SYNC_DEC = 213
%H_SYNC_INC = 214
%H_B_PORCH = 215
%H_B_PORCH_DEC = 216
%H_B_PORCH_INC = 217
%H_BLANK = 218

' Vertical geometry
%V_CENTER = 300
%V_CENTER_DEC = 301
%V_CENTER_INC = 302
%V_AMP = 303
%V_AMP_DEC = 304
%V_AMP_INC = 305
%V_ACT = 306
%V_ACT_DEC = 307
%V_ACT_INC = 308
%V_F_PORCH = 309
%V_F_PORCH_DEC = 310
%V_F_PORCH_INC = 311
%V_SYNC = 312
%V_SYNC_DEC = 313
%V_SYNC_INC = 314
%V_B_PORCH = 315
%V_B_PORCH_DEC = 316
%V_B_PORCH_INC = 317
%V_BLANK = 318

' Edit modeline
%DOTCLOCK = 400
%DOTCLOCK_DEC = 401
%DOTCLOCK_INC = 402
%H_RES = 403
%H_RES_DEC = 404
%H_RES_INC = 405
%H_R_START = 406
%H_R_START_DEC = 407
%H_R_START_INC = 408
%H_R_END = 409
%H_R_END_DEC = 410
%H_R_END_INC = 411
%H_TOTAL = 412
%H_TOTAL_DEC = 413
%H_TOTAL_INC = 414
%V_RES = 415
%V_RES_DEC = 416
%V_RES_INC = 417
%V_R_START= 418
%V_R_START_DEC = 419
%V_R_START_INC = 420
%V_R_END = 421
%V_R_END_DEC = 422
%V_R_END_INC = 423
%V_TOTAL = 424
%V_TOTAL_DEC = 425
%V_TOTAL_INC = 426
%INTERLACED = 427
%INTERLACED_SET = 428
%LOCK_VFREQ = 429
%LOCK_VFREQ_SET = 430
%H_SYNC_POL = 431
%V_SYNC_POL = 432
%H_SYNC_POL_SET = 433
%V_SYNC_POL_SET = 434

' Desktop Mode
%SAVE_DESKTOP_MODE = 500
%RESTORE_DESKTOP_MODE = 502

Type MENU_DEF
  header_count As Long
  option_count As Long
  help_count As Long
  cursor_line As Long
  current_line As Long
  color_option(%MENU_OPTION_MAX) As Long
  option_command_ok(%MENU_OPTION_MAX) As Long
  option_command_left(%MENU_OPTION_MAX) As Long
  option_command_right(%MENU_OPTION_MAX) As Long
  option_command_back(%MENU_OPTION_MAX) As Long
  header_line(%MENU_HEADER_MAX) As AsciiZ * %OSD_WIDTH + 1
  option_line(%MENU_OPTION_MAX) As AsciiZ * %OSD_WIDTH + 1
  help_line(%MENU_HELP_MAX) As AsciiZ * %OSD_WIDTH + 1
End Type

Type OSD_DEF
  hwnd As Long
  h_debug As Long
  xpos As Long
  ypos As Long
  xsize As Long
  ysize As Long
  win_version As Long
  fullscreen As Long
  fullscreen_edit_mode As Long
  debug_enabled As Long
  lock_vfreq As Long
  lock_unsupported_modes As Long
  input_focus As Long
  test_state As Long
  custom_video As Long
  show_credits As Long
  mode_idx As Long
  mode_count As Long
  custom_mode_count As Long
  width As Long
  font_height As Long
  font_width As Long
  font_face As AsciiZ * 32
  current_menu As Long
  line_count As Long
  line_shown As Long
  line_color_f(%OSD_HEIGHT) As Long
  line_color_b(%OSD_HEIGHT) As Long
  line_text(%OSD_HEIGHT) As AsciiZ * 256
  display_area As RECT
  menu_display As AsciiZ * 32
  target_display As AsciiZ * 32
  method_string As AsciiZ * 32
  pattern_buffer As Long
  measured_vfreq As Double
  current_mode As MODELINE
  backup_mode As MODELINE
  driver_mode As MODELINE
  previous_state As MODELINE
  clipboard_mode As MODELINE
  video_mode(%MODES_MAX) As MODELINE
End Type
