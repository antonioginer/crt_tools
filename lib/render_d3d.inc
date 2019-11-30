'==============================================================================
'
'  Render library
'  render_d3d.inc
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

'============================================================
'  Functions
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function d3d_init(hWnd As Long, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long, display_name As String) Common As Long
Declare Function d3d_exit() Common As Long
Declare Function d3d_create_surface(m_width As Long, m_height As Long) Common As Long
Declare Function d3d_blit_to_back_buffer(surface_idx As Long, s_rect As RECT, d_rect As RECT) Common As Long
Declare Function d3d_get_dc(surface_idx As Long) Common As Long
Declare Function d3d_get_back_buffer_dc() Common As Long
Declare Function d3d_release_dc(surface_idx As Long, hdc As Long) Common As Long
Declare Function d3d_release_back_buffer_dc(hdc As Long) Common As Long
Declare Function d3d_is_ready() Common As Long
Declare Function d3d_flip Common As Long
#EndIf
