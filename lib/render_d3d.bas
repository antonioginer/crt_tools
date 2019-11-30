'==============================================================================
'
'  Render library
'  render_d3d.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

%DDRAW_MAX_OBJECTS = 32

#Compile SLL
#Include "win32api.inc"
#Include "d3dx9.inc"
#Include "log_console.inc"

%D3D_MAX_OBJECTS = 32

'============================================================
'  globals
'============================================================

Global m_hwnd As Long
Global m_pD3D As IDirect3D9Ex
Global m_pD3DDevice As IDirect3DDevice9Ex
Global m_d3ddm As D3DDISPLAYMODE
Global m_d3dpp As D3DPRESENT_PARAMETERS
Global m_back_buffer As IDirect3DSurface9

Declare Function display_get_device_handle(ByVal device_name As String) Common As Long

'============================================================
'  d3d_init
'============================================================

Function d3d_init(hWnd As Long, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long, display_name As String) Common As Long

  Local hr As Long
  m_hwnd = hWnd

  ReDim m_surface(%D3D_MAX_OBJECTS) As Global IDirect3DSurface9

  If m_bpp < 16 Then clog "16-bit color or higher required." : Exit Function

  ' Creates an IDirect3D9 object and returns an interface to it
  Direct3DCreate9Ex(%D3D_SDK_VERSION, m_pD3D)
  If IsNothing(m_pD3D) Then clog "Direct3DCreate9 error." : Exit Function

  Local adapter As Long
  adapter = d3d_adapter_from_display(display_name)

  ' Retrieves the current display mode of the adapter
  hr = m_pD3D.GetAdapterDisplayMode(adapter, m_d3ddm)
  If FAILED(hr) Then clog "IDirect3D9::GetAdapterDisplayMode failed : " + Hex$(hr) : Exit Function

  hr = m_pD3D.CheckDeviceFormat(adapter, %D3DDEVTYPE_HAL, m_d3ddm.Format, %D3DUSAGE_DYNAMIC, %D3DRTYPE_SURFACE, %D3DFMT_X8R8G8B8)
  If FAILED(hr) Then
     If hr = %D3DERR_NOTAVAILABLE Then clog "We need at least a 16-bit z-buffer!" : Exit Function
  End If

  ' Do we support hardware vertex processing? if so, use it. If not, downgrade to software.
  Local dCaps As D3DCAPS9
  If FAILED(m_pD3D.GetDeviceCaps(adapter, %D3DDEVTYPE_HAL, dCaps)) Then clog "GetDeviceCaps error." : Exit Function

  Local dwBehaviorFlags As Dword
  dwBehaviorFlags = IIf(dCaps.VertexProcessingCaps, %D3DCREATE_HARDWARE_VERTEXPROCESSING, %D3DCREATE_SOFTWARE_VERTEXPROCESSING)

  ' Creates a device to represent the display adapter
  m_d3dpp.BackBufferWidth        = m_width
  m_d3dpp.BackBufferHeight       = m_height
  m_d3dpp.BackBufferFormat       = m_d3ddm.Format
  m_d3dpp.BackBufferCount        = 1
  m_d3dpp.MultiSampleType        = %D3DMULTISAMPLE_NONE
  m_d3dpp.SwapEffect             = %D3DSWAPEFFECT_DISCARD
  m_d3dpp.hDeviceWindow          = hWnd
  m_d3dpp.Windowed               = %FALSE
  m_d3dpp.EnableAutoDepthStencil = %FALSE
  m_d3dpp.AutoDepthStencilFormat = %D3DFMT_D16
  m_d3dpp.Flags                  = %D3DPRESENTFLAG_UNPRUNEDMODE Or %D3DPRESENTFLAG_LOCKABLE_BACKBUFFER
  m_d3dpp.FullScreen_RefreshRateInHz = m_refresh
  m_d3dpp.PresentationInterval   = %D3DPRESENT_INTERVAL_ONE

  Local m_display_mode As D3DDISPLAYMODEEX
  m_display_mode.Size = SizeOf(D3DDISPLAYMODEEX)
  m_display_mode.Width = m_width
  m_display_mode.Height = m_height
  m_display_mode.RefreshRate = m_refresh
  m_display_mode.Format = m_d3ddm.Format
  m_display_mode.ScanLineOrdering = IIf(m_interlace, %D3DSCANLINEORDERING_INTERLACED, %D3DSCANLINEORDERING_PROGRESSIVE)

  hr = m_pD3D.CreateDeviceEx(adapter, %D3DDEVTYPE_HAL, hwnd, dwBehaviorFlags, m_d3dpp, m_display_mode, m_pD3DDevice)
  If FAILED(hr) Then clog "IDirect3D9::CreateDevice failed: " + Hex$(hr) : Exit Function

  clog Using$("IDirect3D9Ex::CreateDeviceEx #x#@#&", m_width, m_height, m_refresh, IIf$(m_interlace, "i", "p"))

  hr = m_pD3DDevice.GetBackBuffer(0, 0, %D3DBACKBUFFER_TYPE_MONO, m_back_buffer)
  If FAILED(hr) Then clog "IDirect3DDevice9::GetBackBuffer failed: " + Hex$(hr) : Exit Function

  Function = 1
End Function

'============================================================
'  d3d_exit
'============================================================

Function d3d_exit() Common As Long

  If IsNothing(m_pD3D) Then Exit Function

  Local i As Long
  For i = UBound(m_surface()) To 0 Step -1
    If IsObject(m_surface(i)) Then m_surface(i) = Nothing
  Next

  m_back_buffer = Nothing
  m_pD3DDevice = Nothing
  m_pD3D = Nothing

  Sleep(50)

  Function = 1
End Function

'============================================================
'  d3d_register_surface
'============================================================

Function d3d_register_surface(surface As IDirect3DSurface9) As Long

  Local i As Long

  While i <= UBound(m_surface())
    If IsNothing(m_surface(i)) Then
      m_surface(i) = surface
      Exit Loop
    End If
    Incr i
  Wend

  Function = i
End Function

'============================================================
'  d3d_create_surface
'============================================================

Function d3d_create_surface(m_width As Long, m_height As Long) Common As Long

  Local hr As Long
  Local surface As IDirect3DSurface9
  hr = m_pD3DDevice.CreateOffscreenPlainSurface(m_width, m_height, m_d3ddm.Format, %D3DPOOL_SYSTEMMEM, surface, ByVal %Null)

  If FAILED(hr) Then clog "IDirect3DDevice9::CreateOffscreenPlainSurface " + Hex$(hr) : Exit Function
  Function = d3d_register_surface(surface)

End Function

'============================================================
'  d3d_blit_to_back_buffer
'============================================================

Function d3d_blit_to_back_buffer(surface_idx As Long, s_rect As RECT, d_rect As RECT) Common As Long

  Local s_surf, d_surf As IDirect3DSurface9
  s_surf = m_surface(surface_idx)
  d_surf = m_back_buffer

  Local hr As Long
  Local d_point As Point
  d_point.x = d_rect.left
  d_point.y = d_rect.top
  hr = m_pD3DDevice.UpdateSurface(s_surf, s_rect, d_surf, d_point)
  If FAILED(hr) Then clog "IDirect3DDevice9::UpdateSurface " + Hex$(hr) : Exit Function

  Function = 1
End Function

'============================================================
'  d3d_get_dc
'============================================================

Function d3d_get_dc(surface_idx As Long) Common As Long

  Local surface As IDirect3DSurface9
  surface = m_surface(surface_idx)

  Local hr, hdc As Long
  hr = surface.GetDC(hdc)
  If FAILED(hr) Then clog "IDirect3DSurface9::GetDC failed: " + Hex$(hr) : Exit Function

  Function = hdc
End Function

'============================================================
'  d3d_get_back_buffer_dc
'============================================================

Function d3d_get_back_buffer_dc() Common As Long

  Local hr As Long
  Local hdc As Long

  hr = m_back_buffer.GetDC(hdc)
  If FAILED(hr) Then clog "IDirect3DSurface9::GetDC failed: " + Hex$(hr) : Exit Function

  Function = hdc
End Function

'============================================================
'  d3d_release_dc
'============================================================

Function d3d_release_dc(surface_idx As Long, hdc As Long) Common As Long

  Local surface As IDirect3DSurface9
  surface = m_surface(surface_idx)

  Local hr As Long
  hr = surface.ReleaseDC(hdc)

  Function = hr
End Function

'============================================================
'  d3d_release_back_buffer_dc
'============================================================

Function d3d_release_back_buffer_dc(hdc As Long) Common As Long

  Local hr As Long
  hr = m_back_buffer.ReleaseDC(hdc)

  Function = hr
End Function

'============================================================
'  d3d_is_ready
'============================================================

Function d3d_is_ready() Common As Long

  If IsNothing(m_pD3DDevice) Then Exit Function

  Local hr As Long
  hr = m_pD3DDevice.TestCooperativeLevel

  If hr = %D3D_OK Then Function = 1 : Exit Function

  ' Something failed, log error code
  clog "IDirect3DDevice9::TestCooperativeLevel: " + Hex$(hr)

  If hr = %D3DERR_DEVICELOST Then Exit Function

  If hr = %D3DERR_DEVICENOTRESET Then m_pD3DDevice.Reset(m_d3dpp)

End Function

'============================================================
'  d3d_flip_waitvsync
'============================================================

Function d3d_flip() Common As Long

  If IsNothing(m_pD3DDevice) Then Exit Function

  Local hr As Long
  hr = m_pD3DDevice.Present(ByVal %NULL, ByVal %NULL, %NULL, ByVal %NULL)

End Function

'============================================================
'  d3d_adapter_from_display
'============================================================

Function d3d_adapter_from_display(display_name As String) As Long

  If IsNothing(m_pD3D) Then Exit Function

  Local h_monitor As Long
  h_monitor = display_get_device_handle(display_name)


  Local i, found As Long
  For i = 0 To m_pD3D.GetAdapterCount()
    If h_monitor = m_pD3D.GetAdapterMonitor(i) Then found = i : Exit For
  Next

  Function = found
End Function
