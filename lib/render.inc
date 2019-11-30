'==============================================================================
'
'  Render library
'  render.inc
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

'============================================================
'  Constants
'============================================================

Enum render_api
DDRAW      = 1
D3D9       = 2
End Enum

'============================================================
'  Types
'============================================================

Type RENDER_OPTIONS
  render_api As String * 16
End Type

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function render_get_default_options(options As RENDER_OPTIONS) Common As Long
Declare Function render_init(hwnd As Long, ByVal device_name As String, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long) Common As Long
Declare Function render_get_method() Common As Long
Declare Function render_get_method_name() Common As String
Declare Function render_create_bitmap(b_width As Long, b_height As Long) Common As Long
Declare Function render_get_dc(b_buffer As Long) Common As Long
Declare Function render_get_back_buffer_dc() Common As Long
Declare Function render_release_dc(b_buffer As Long, hdc As Long) Common As Long
Declare Function render_release_back_buffer_dc(hdc As Long) Common As Long
Declare Function render_is_ready() Common As Long
Declare Function render_blit_to_back_buffer(b_buffer As Long, s_rect As RECT, d_rect As RECT) Common As Long
Declare Function render_flip() Common As Long
Declare Function render_exit() Common As Long
#EndIf
