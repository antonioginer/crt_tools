'==============================================================================
'
'  Render library
'  render_ddraw.bas
'  Copyright (c) 2008-2019 Antonio Giner González
'
'==============================================================================

%DDRAW_MAX_OBJECTS = 32

#Compile SLL
#Include "win32api.inc"
#Include "ddraw.inc"
#Include "log_console.inc"

'============================================================
'  globals
'============================================================

Global exclusive_access_lost As Long
Global m_ddraw As IDirectDraw7
Global m_primary As IDirectDrawSurface7
Global m_back_buffer As IDirectDrawSurface7
Global m_hwnd As Long

Declare Function display_get_device_guid(ByVal device_name As String) Common As String

'============================================================
'  ddraw_init
'============================================================

Function ddraw_init(hWnd As Long, m_width As Long, m_height As Long, m_refresh As Long, m_bpp As Long, m_interlace As Long, display_name As String) Common As Long

  Local hresult As Long
  Local ddsd As DDSURFACEDESC2
  Local dscaps As DDSCAPS2
  m_hwnd = hWnd

  ReDim m_surface(%DDRAW_MAX_OBJECTS) As Global IDirectDrawSurface7

  If m_bpp < 8 Then clog "4-bit modes are not supported " : Exit Function

  Local device_guid As Guid
  device_guid = display_get_device_guid(display_name)

  ' Create the DirectDraw7 interface
  hresult = DirectDrawCreateEx(device_guid, m_ddraw, $IID_IDirectDraw7, ByVal %NULL)
  If hresult <> %DD_OK Then clog "DirectDrawCreateEx error " : Exit Function

  hresult = m_ddraw.SetCooperativeLevel(m_hwnd, %DDSCL_EXCLUSIVE Or %DDSCL_FULLSCREEN)
  If hresult <> %DD_OK Then clog "SetCooperativeLevel error " : Exit Function

  ' Set fullscreen display mode
  hresult = m_ddraw.SetDisplayMode(m_width, m_height, m_bpp, m_refresh, 0)
  clog Using$("IDirectDraw7::SetDisplayMode # # # # #", m_width, m_height, m_bpp, m_refresh, 0)
  If hresult <> %DD_OK Then
    clog "IDirectDraw7::SetDisplayMode error " + Hex$(hresult) + ", retrying without forced refresh rate "
    m_ddraw.SetCooperativeLevel(m_hwnd, %DDSCL_EXCLUSIVE Or %DDSCL_FULLSCREEN)
    hresult = m_ddraw.SetDisplayMode(m_width, m_height, m_bpp, 0, 0)
    If hresult <> %DD_OK Then clog "IDirectDraw7::SetDisplayMode error " + Hex$(hresult) + ", aborting " : Exit Function
  End If

  ' Create the primary surface with 1 back buffer
  Reset ddsd
  ddsd.dwSize = SizeOf(ddsd)
  ddsd.dwFlags = %DDSD_CAPS Or %DDSD_BACKBUFFERCOUNT
  ddsd.ddsCaps.dwCaps = %DDSCAPS_PRIMARYSURFACE Or %DDSCAPS_FLIP Or %DDSCAPS_COMPLEX
  ddsd.dwBackBufferCount = 1
  hresult = m_ddraw.CreateSurface(ddsd, m_primary, ByVal %NULL)
  If hresult <> %DD_OK Then clog "IDirectDraw7::CreateSurface error " + Hex$(hresult) : Exit Function

  ' Get a pointer to the back buffer
  dscaps.dwCaps = %DDSCAPS_BACKBUFFER
  hresult = m_primary.GetAttachedSurface(dscaps, m_back_buffer)
  If hresult <> %DD_OK Then clog "IDirectDraw7::GetAttachedSurface error " + Hex$(hresult) : Exit Function

  'hresult = m_ddraw.FlipToGDISurface

  Function = 1
End Function

'============================================================
'  ddraw_exit
'============================================================

Function ddraw_exit() Common As Long

  If IsNothing(m_ddraw) Then Exit Function

  Local i As Long
  For i = UBound(m_surface()) To 0 Step -1
    If IsObject(m_surface(i)) Then m_surface(i) = Nothing
  Next

  m_back_buffer = Nothing
  m_primary = Nothing

  m_ddraw.SetCooperativeLevel(m_hwnd, %DDSCL_NORMAL)
  m_ddraw = Nothing

  Sleep(50)

  Function = 1
End Function

'============================================================
'  ddraw_register_surface
'============================================================

Function ddraw_register_surface(surface As IDirectDrawSurface7) As Long

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
'  create_surface_from_bitmap
'============================================================

Function create_surface_from_bitmap(file_name As AsciiZ) Common As Long

  Local hresult As Long
  Local hbitmap As Long
  Local hdc_bitmap As Long
  Local hdc As Long
  Local bm As Bitmap
  Local surface As IDirectDrawSurface7
  Local ddsd As DDSURFACEDESC2
  Local bmRect As RECT

  If InStr(file_name, ".") Then
    hbitmap = LoadImage(%NULL, file_name, %IMAGE_BITMAP, 0, 0, %LR_LOADFROMFILE Or %LR_CREATEDIBSECTION)
  Else
    hbitmap = LoadImage(GetModuleHandle(""), file_name, %IMAGE_BITMAP, 0, 0, %LR_CREATEDIBSECTION)
  End If

  GetObject(hbitmap, SizeOf(bm), bm )
  hdc_bitmap = CreateCompatibleDC(%NULL)
  SelectObject(hdc_bitmap, hbitmap)

  Reset ddsd
  ddsd.dwSize     = SizeOf(ddsd)
  ddsd.dwFlags    = %DDSD_CAPS Or %DDSD_HEIGHT Or %DDSD_WIDTH
  ddsd.ddsCaps.dwCaps = %DDSCAPS_OFFSCREENPLAIN
  ddsd.dwWidth    = bm.bmWidth
  ddsd.dwHeight   = bm.bmHeight

  Reset bmRect
  bmRect.nRight = bm.bmWidth
  bmRect.nBottom = bm.bmHeight

  hresult = m_ddraw.CreateSurface(ddsd, surface, ByVal %NULL)
  If hresult = %DD_OK Then
    hresult = surface.GetSurfaceDesc(ddsd)
    hresult = surface.GetDC(hdc)
    hresult = StretchBlt(hdc, 0, 0, ddsd.dwWidth, ddsd.dwHeight, hdc_bitmap, 0, 0, bm.bmWidth , bm.bmHeight, %SRCCOPY)
    hresult = surface.ReleaseDC(hdc)
    Function = ddraw_register_surface(surface)
  End If

  DeleteDC(hdc_bitmap)
  DeleteObject(hbitmap)
End Function

'============================================================
'  ddraw_create_surface
'============================================================

Function ddraw_create_surface(m_width As Long, m_height As Long) Common As Long

  Local surface As IDirectDrawSurface7

  Local ddsd As DDSURFACEDESC2
  Reset ddsd
  ddsd.dwSize     = SizeOf(ddsd)
  ddsd.dwFlags    = %DDSD_CAPS Or %DDSD_HEIGHT Or %DDSD_WIDTH
  ddsd.ddsCaps.dwCaps = %DDSCAPS_OFFSCREENPLAIN
  ddsd.dwWidth    = m_width
  ddsd.dwHeight   = m_height

  Local hresult As Long
  hresult = m_ddraw.CreateSurface(ddsd, surface, ByVal %NULL)
  If hresult <> %DD_OK Then clog "IDirectDraw7::CreateSurface error " + Hex$(hresult) : Exit Function

  Function = ddraw_register_surface(surface)
End Function

'============================================================
'  ddraw_blit_to_back_buffer
'============================================================

Function ddraw_blit_to_back_buffer(surface_idx As Long, s_rect As RECT, d_rect As RECT) Common As Long

  Local s_surf, d_surf As IDirectDrawSurface7
  s_surf = m_surface(surface_idx)
  d_surf = m_back_buffer

  Local dbltfx As DDBLTFX
  Reset dbltfx
  dbltfx.dwSize = SizeOf(dbltfx)

  Local hresult As Long
  hresult = d_surf.Blt(d_rect, s_surf, s_rect, %DDBLT_WAIT, dbltfx)

  Function = (hresult = %DD_OK)
End Function

'============================================================
'  ddraw_get_dc
'============================================================

Function ddraw_get_dc(surface_idx As Long) Common As Long

  Local surface As IDirectDrawSurface7
  surface = m_surface(surface_idx)

  Local hresult, hdc As Long
  hresult = surface.GetDC(hdc)
  If hresult <> %DD_OK Then clog "IDirectDraw7::GetDC failed: " + Hex$(hresult) : Exit Function

  Function = hdc
End Function

'============================================================
'  ddraw_get_back_buffer_dc
'============================================================

Function ddraw_get_back_buffer_dc() Common As Long

  Local hresult, hdc As Long
  hresult = m_back_buffer.GetDC(hdc)
  If hresult <> %DD_OK Then clog "IDirectDraw7::GetDC failed: " + Hex$(hresult) : Exit Function

  Function = hdc
End Function

'============================================================
'  ddraw_release_dc
'============================================================

Function ddraw_release_dc(surface_idx As Long, hdc As Long) Common As Long

  Local surface As IDirectDrawSurface7
  surface = m_surface(surface_idx)

  Local hresult As Long
  hresult = surface.ReleaseDC(hdc)
  Function = hresult
End Function

'============================================================
'  ddraw_release_back_buffer_dc
'============================================================

Function ddraw_release_back_buffer_dc(hdc As Long) Common As Long

  Local hresult As Long
  hresult = m_back_buffer.ReleaseDC(hdc)

  Function = hresult
End Function

'============================================================
'  ddraw_is_ready
'============================================================

Function ddraw_is_ready() Common As Long

  If IsNothing(m_ddraw) Then Exit Function

  Local hresult As Long
  hresult = m_ddraw.TestCooperativeLevel
  If hresult <> %DD_OK Then
    clog "IDirectDraw7::TestCooperativeLevel: " + Hex$(hresult)
    exclusive_access_lost =  1
    Exit Function
  End If

  If exclusive_access_lost Then
    hresult = m_ddraw.RestoreAllSurfaces
    If hresult <> %DD_OK Then clog "IDirectDraw7::RestoreAllSurfaces failed: " + Hex$(hresult) : Exit Function
    exclusive_access_lost = 0
  End If

  Function = 1
End Function

'============================================================
'  ddraw_flip_waitvsync
'============================================================

Function ddraw_flip() Common As Long

  Function = m_primary.Flip(ByVal %Null, %DDFLIP_WAIT)

End Function
