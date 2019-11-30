'==============================================================================
'
'  Render library
'  render.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

#Compile SLL
#Dim All

#Include Once "win32api.inc"
#Include "render.inc"
#Include "render_ddraw.inc"
#Include "render_d3d.inc"
#Include "modeline.inc"
#Include "display.inc"
#Include "util.inc"
#Include "log_console.inc"

%USE_D3D9EX = 1

'============================================================
'  Globals
'============================================================

Global device_name As String
Global render_method As Long
Global render_method_name As String
Global win_version As Long

'============================================================
'  render_get_default_options
'============================================================

Function render_get_default_options(options As RENDER_OPTIONS) Common As Long

  options.render_api = "ddraw"

End Function

'============================================================
'  render_init
'============================================================

Function render_init(hwnd As Long, ByVal device_name As String,  m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long) Common As Long

  ' Reset previous information
  render_method = 0

  win_version = os_version()

  If %USE_D3D9EX And win_version > 5 And d3d_init(hwnd, m_width, m_height, m_refresh, m_bpp, m_interlace, device_name) Then
    render_method = %render_api.D3D9
    render_method_name = "Direct3D9Ex"

  Else
    ' DirectDraw hack for W7
    If win_version > 5 Then display_set_desktop_mode(device_name, m_width, m_height, m_refresh, m_bpp, m_interlace, %CDS_TEST Or %CDS_UPDATEREGISTRY)

    If ddraw_init(hwnd, m_width, m_height, m_refresh, m_bpp, m_interlace, device_name) Then
      render_method = %render_api.DDRAW
      render_method_name = "DirectDraw"
    End If

    ' DirectDraw hack for W7
    If win_version > 5 Then display_restore_desktop_mode(device_name, %CDS_TEST Or %CDS_UPDATEREGISTRY)

  End If

  clog "Render started on " + device_name + " using " + render_method_name

  Function = render_method
End Function

'============================================================
'  render_exit
'============================================================

Function render_exit() Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_exit()
      Case %render_api.D3D9
          Function = d3d_exit()
  End Select

End Function

'============================================================
'  render_get_method
'============================================================

Function render_get_method() Common As Long
  Function = render_method
End Function

'============================================================
'  render_get_method_name
'============================================================

Function render_get_method_name() Common As String
  Function = render_method_name
End Function

'============================================================
'  render_create_bitmap
'============================================================

Function render_create_bitmap(b_width As Long, b_height As Long) Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_create_surface(b_width, b_height)
      Case %render_api.D3D9
          Function = d3d_create_surface(b_width, b_height)

  End Select

End Function


'============================================================
'  render_get_dc
'============================================================

Function render_get_dc(b_buffer As Long) Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_get_dc(b_buffer)
      Case %render_api.D3D9
          Function = d3d_get_dc(b_buffer)
  End Select

End Function

'============================================================
'  render_release_dc
'============================================================

Function render_release_dc(b_buffer As Long, hdc As Long) Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_release_dc(b_buffer, hdc)
      Case %render_api.D3D9
          Function = d3d_release_dc(b_buffer, hdc)
  End Select

End Function

'============================================================
'  render_release_back_buffer_dc
'============================================================

Function render_release_back_buffer_dc(hdc As Long) Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_release_back_buffer_dc(hdc)
      Case %render_api.D3D9
          Function = d3d_release_back_buffer_dc(hdc)
  End Select

End Function

'============================================================
'  render_is_ready
'============================================================

Function render_is_ready() Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_is_ready()
      Case %render_api.D3D9
          Function = d3d_is_ready()
  End Select

End Function

'============================================================
'  render_get_back_buffer_dc
'============================================================

Function render_get_back_buffer_dc() Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_get_back_buffer_dc()
      Case %render_api.D3D9
          Function = d3d_get_back_buffer_dc()
  End Select

End Function

'============================================================
'  render_blit_to_back_buffer
'============================================================
Function render_blit_to_back_buffer(b_buffer As Long, s_rect As RECT, d_rect As RECT) Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_blit_to_back_buffer(b_buffer, s_rect, d_rect)
      Case %render_api.D3D9
          Function = d3d_blit_to_back_buffer(b_buffer, s_rect, d_rect)
  End Select

End Function

'============================================================
'  render_get_back_buffer_dc
'============================================================

Function render_flip() Common As Long

  Select Case render_method
      Case %render_api.DDRAW
          Function = ddraw_flip()
      Case %render_api.D3D9
          Function = d3d_flip()
  End Select

End Function
