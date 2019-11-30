'==============================================================================
'
'  Render library
'  render_dddraw.inc
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function ddraw_init(hWnd As Long, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long, display_name As String) Common As Long
Declare Function ddraw_exit() Common As Long
Declare Function create_surface_from_bitmap(file_name As AsciiZ) Common As Long
Declare Function ddraw_create_surface(m_width As Long, m_height As Long) Common As Long
Declare Function ddraw_blit_to_back_buffer(surface_idx As Long, s_rect As RECT, d_rect As RECT) Common As Long
Declare Function ddraw_get_dc(surface_idx As Long) Common As Long
Declare Function ddraw_get_back_buffer_dc() Common As Long
Declare Function ddraw_release_dc(surface_idx As Long, hdc As Long) Common As Long
Declare Function ddraw_release_back_buffer_dc(hdc As Long) Common As Long
Declare Function ddraw_is_ready() Common As Long
Declare Function ddraw_flip Common As Long
#EndIf
