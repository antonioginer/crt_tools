'===========================================================
'  ATI/AMD ADL helper library
'  by Calamity - 2015-2019
'===========================================================

#Compile SLL
#Dim All
#Include Once "win32api.inc"
#Include "modeline.inc"
#Include "edid.inc"
#Include "util.inc"
#Include "log_console.inc"

%ADL_OK = 0
%ADL_ERR = -1
%ADL_MAX_PATH = 256
%MAX_TIMING_OVERRIDES = 256
%LOG = 0

%ADL_CONNECTOR_TYPE_UNKNOWN              = 0
%ADL_CONNECTOR_TYPE_VGA                  = 1
%ADL_CONNECTOR_TYPE_DVI_D                = 2
%ADL_CONNECTOR_TYPE_DVI_I                = 3
%ADL_CONNECTOR_TYPE_ATICVDONGLE_NA       = 4
%ADL_CONNECTOR_TYPE_ATICVDONGLE_JP       = 5
%ADL_CONNECTOR_TYPE_ATICVDONGLE_NONI2C   = 6
%ADL_CONNECTOR_TYPE_ATICVDONGLE_NONI2C_D = 7
%ADL_CONNECTOR_TYPE_HDMI_TYPE_A          = 8
%ADL_CONNECTOR_TYPE_HDMI_TYPE_B          = 9
%ADL_CONNECTOR_TYPE_DISPLAYPORT          = 10
%ADL_CONNECTOR_TYPE_EDP                  = 11
%ADL_CONNECTOR_TYPE_MINI_DISPLAYPORT     = 12
%ADL_CONNECTOR_TYPE_VIRTUAL              = 13

'ADL_DISPLAY_INFO.iDisplayConnector
%ADL_DISPLAY_CONTYPE_UNKNOWN                 = 0
%ADL_DISPLAY_CONTYPE_VGA                     = 1
%ADL_DISPLAY_CONTYPE_DVI_D                   = 2
%ADL_DISPLAY_CONTYPE_DVI_I                   = 3
%ADL_DISPLAY_CONTYPE_ATICVDONGLE_NTSC        = 4
%ADL_DISPLAY_CONTYPE_ATICVDONGLE_JPN         = 5
%ADL_DISPLAY_CONTYPE_ATICVDONGLE_NONI2C_JPN  = 6
%ADL_DISPLAY_CONTYPE_ATICVDONGLE_NONI2C_NTSC = 7
%ADL_DISPLAY_CONTYPE_PROPRIETARY             = 8
%ADL_DISPLAY_CONTYPE_HDMI_TYPE_A             = 10
%ADL_DISPLAY_CONTYPE_HDMI_TYPE_B             = 11
%ADL_DISPLAY_CONTYPE_SVIDEO                  = 12
%ADL_DISPLAY_CONTYPE_COMPOSITE               = 13
%ADL_DISPLAY_CONTYPE_RCA_3COMPONENT          = 14
%ADL_DISPLAY_CONTYPE_DISPLAYPORT             = 15
%ADL_DISPLAY_CONTYPE_EDP                     = 16
%ADL_DISPLAY_CONTYPE_WIRELESSDISPLAY         = 17

'ADL_DETAILED_TIMING.sTimingFlags
%ADL_DL_TIMINGFLAG_DOUBLE_SCAN               = &h0001
%ADL_DL_TIMINGFLAG_INTERLACED                = &h0002
%ADL_DL_TIMINGFLAG_H_SYNC_POLARITY           = &h0004
%ADL_DL_TIMINGFLAG_V_SYNC_POLARITY           = &h0008

'ADL_DISPLAY_MODE_INFO.iTimingStandard
%ADL_DL_MODETIMING_STANDARD_CVT              = &h00000001 ' CVT Standard
%ADL_DL_MODETIMING_STANDARD_GTF              = &h00000002 ' GFT Standard
%ADL_DL_MODETIMING_STANDARD_DMT              = &h00000004 ' DMT Standard
%ADL_DL_MODETIMING_STANDARD_CUSTOM           = &h00000008 ' User-defined standard
%ADL_DL_MODETIMING_STANDARD_DRIVER_DEFAULT   = &h00000010 ' Remove Mode from overriden list
%ADL_DL_MODETIMING_STANDARD_CVT_RB           = &h00000020 ' CVT-RB Standard

%ADL_QUERY_REAL_DATA     = 0
%ADL_QUERY_EMULATED_DATA = 1
%ADL_QUERY_CURRENT_DATA  = 2

Type ADAPTER_INFO
  iSize As Long
  iAdapterIndex As Long
  strUDID As String * %ADL_MAX_PATH
  iBusNumber As Long
  iDeviceNumber As Long
  iFunctionNumber As Long
  iVendorID As Long
  strAdapterName As String * %ADL_MAX_PATH
  strDisplayName As String * %ADL_MAX_PATH
  iPresent As Long
  iExist As Long
  strDriverPath As String * %ADL_MAX_PATH
  strDriverPathExt As String * %ADL_MAX_PATH
  strPNPString As String * %ADL_MAX_PATH
  iOSDisplayIndex As Long
End Type

Type ADL_DISPLAY_ID
  iDisplayLogicalIndex As Long
  iDisplayPhysicalIndex As Long
  iDisplayLogicalAdapterIndex As Long
  iDisplayPhysicalAdapterIndex As Long
End Type

Type ADL_DISPLAY_INFO
  displayID As ADL_DISPLAY_ID
  iDisplayControllerIndex As Long
  strDisplayName As String * %ADL_MAX_PATH
  strDisplayManufacturerName As String * %ADL_MAX_PATH
  iDisplayType As Long
  iDisplayOutputType As Long
  iDisplayConnector As Long
  iDisplayInfoMask As Long
  iDisplayInfoValue As Long
End Type

Type ADL_DISPLAY_MODE
  iPelsHeight As Long
  iPelsWidth As Long
  iBitsPerPel As Long
  iDisplayFrequency As Long
End Type

Type ADL_DETAILED_TIMING
  iSize As Long
  sTimingFlags As Word
  sHTotal As Word
  sHDisplay As Word
  sHSyncStart As Word
  sHSyncWidth As Word
  sVTotal As Word
  sVDisplay As Word
  sVSyncStart As Word
  sVSyncWidth As Word
  sPixelClock As Word
  sHOverscanRight As Word
  sHOverscanLeft As Word
  sVOverscanBottom As Word
  sVOverscanTop As Word
  sOverscan8B As Word
  sOverscanGR As Word
End Type

Type ADL_DISPLAY_MODE_INFO
  iTimingStandard As Long
  iPossibleStandard As Long
  iRefreshRate As Long
  iPelsWidth As Long
  iPelsHeight As Long
  sDetailedTiming As ADL_DETAILED_TIMING
End Type

Type ADL_BRACKET_SLOT_INFO
  iSlotIndex As Long
  iLength As Long
  iWidth As Long
End Type

Type ADL_CONNECTOR_INFO
  iConnectorIndex As Long
  iConnectorId As Long
  iSlotIndex As Long
  iType As Long
  iOffset As Long
  iLength As Long
End Type

Type ADL_MST_RAD
  iLinkNumber As Long
  rad(15) As Byte
End Type

Type ADL_DEVICE_PORT
  iConnectorIndex As Long
  aMSTRad As ADL_MST_RAD
End Type

Type ADL_CONNECTION_PROPERTIES
  iValidProperties As Long
  iBitrate As Long
  iNumberOfLanes As Long
  iColorDepth As Long
  iStereo3DCaps As Long
  iOutputBandwidth As Long
End Type

Type ADL_CONNECTION_DATA
  iConnectionType As Long
  aConnectionProperties As ADL_CONNECTION_PROPERTIES
  iNumberofPorts As Long
  iActiveConnections As Long
  iDataSize As Long
  EdidData(1024) As Byte
End Type

Type ADAPTER_LIST
  m_index As Long
  m_bus As Long
  m_name As AsciiZ * %ADL_MAX_PATH
  m_display_name As AsciiZ * %ADL_MAX_PATH
  m_num_of_displays As Long
  m_display_list As ADL_DISPLAY_INFO Ptr
End Type

Type CONNECTOR_LIST
  m_index As Long
  m_bus As Long
  m_adapter As Long
  m_name As AsciiZ * 32
End Type

'============================================================
'  Globals
'============================================================

  Global h_dll As Long
  Global adapter() As ADAPTER_LIST
  Global connector() As CONNECTOR_LIST
  Global timing_cache() As ADL_DISPLAY_MODE
  Global cat_version As Long
  Global num_of_adapters As Long

'============================================================
'  Declare ADL Functions
'============================================================

Function ADL_Main_Control_Create(ByVal malloc_callback As Long Ptr, iEnumConnectedAdapters As Long) As Long
  Global pfn_ADL_Main_Control_Create As Long
  Local ADL_err As Long
  If pfn_ADL_Main_Control_Create Then Call Dword pfn_ADL_Main_Control_Create Using ADL_Main_Control_Create(malloc_callback, iEnumConnectedAdapters) To ADL_err
  Function = ADL_err
End Function

Function ADL_Main_Control_Destroy() As Long
  Global pfn_ADL_Main_Control_Destroy As Long
  Local ADL_err As Long
  If pfn_ADL_Main_Control_Destroy Then Call Dword pfn_ADL_Main_Control_Destroy Using ADL_Main_Control_Destroy() To ADL_err
  Function = ADL_err
End Function

Function ADL_Adapter_NumberOfAdapters_Get(ByVal lpNumAdapters As Long Ptr) As Long
  Global pfn_ADL_Adapter_NumberOfAdapters_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Adapter_NumberOfAdapters_Get Then Call Dword pfn_ADL_Adapter_NumberOfAdapters_Get Using ADL_Adapter_NumberOfAdapters_Get(lpNumAdapters) To ADL_err
  Function = ADL_err
End Function

Function ADL_Adapter_AdapterInfo_Get(ByVal lpInfo As ADAPTER_INFO Ptr, ByVal iInputSize As Long) As Long
  Global pfn_ADL_Adapter_AdapterInfo_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Adapter_AdapterInfo_Get Then Call Dword pfn_ADL_Adapter_AdapterInfo_Get Using ADL_Adapter_AdapterInfo_Get(lpInfo, iInputSize) To ADL_err
  Function = ADL_err
End Function

Function ADL_Display_DisplayInfo_Get(ByVal iAdapterIndex As Long, ByRef lpNumDisplays As Long, ByVal lppInfo As Long Ptr, ByVal iForceDetect As Long) As Long
  Global pfn_ADL_Display_DisplayInfo_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Display_DisplayInfo_Get Then Call Dword pfn_ADL_Display_DisplayInfo_Get Using ADL_Display_DisplayInfo_Get(iAdapterIndex, lpNumDisplays, lppInfo, iForceDetect) To ADL_err
  Function = ADL_err
End Function

Function ADL_Display_ModeTimingOverride_Get(ByVal iAdapterIndex As Long, ByVal iDisplayIndex As Long, ByRef lpModeIn As ADL_DISPLAY_MODE, ByRef lpModeInfoOut As ADL_DISPLAY_MODE_INFO) As Long
  Global pfn_ADL_Display_ModeTimingOverride_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Display_ModeTimingOverride_Get Then Call Dword pfn_ADL_Display_ModeTimingOverride_Get Using ADL_Display_ModeTimingOverride_Get(iAdapterIndex, iDisplayIndex, lpModeIn, lpModeInfoOut) To ADL_err
  Function = ADL_err
End Function

Function ADL_Display_ModeTimingOverride_Set(ByVal iAdapterIndex As Long, ByVal iDisplayIndex As Long, ByRef lpMode As ADL_DISPLAY_MODE_INFO, ByVal iForceUpdate As Long) As Long
  Global pfn_ADL_Display_ModeTimingOverride_Set As Long
  Local ADL_err As Long
  If pfn_ADL_Display_ModeTimingOverride_Set Then Call Dword pfn_ADL_Display_ModeTimingOverride_Set Using ADL_Display_ModeTimingOverride_Set(iAdapterIndex, iDisplayIndex, lpMode, iForceUpdate) To ADL_err
  Function = ADL_err
End Function

Function ADL_Display_ModeTimingOverrideList_Get(ByVal iAdapterIndex As Long, ByVal iDisplayIndex As Long, ByVal iMaxNumOfOverrides As Long, ByRef lpModeInfoList As ADL_DISPLAY_MODE_INFO, ByRef lpNumOfOverrides As Long) As Long
  Global pfn_ADL_Display_ModeTimingOverrideList_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Display_ModeTimingOverrideList_Get Then Call Dword pfn_ADL_Display_ModeTimingOverrideList_Get Using ADL_Display_ModeTimingOverrideList_Get(iAdapterIndex, iDisplayIndex, iMaxNumOfOverrides, lpModeInfoList, lpNumOfOverrides) To ADL_err
  Function = ADL_err
End Function

Function ADL_Adapter_BoardLayout_Get(ByVal iAdapterIndex As Long, ByRef lpValidFlags As Long, ByRef lpNumberSlots As Long, ByVal lppBracketSlot As Long Ptr, ByRef lpNumberConnector As Long, ByVal lppConnector As Long Ptr) As Long
  Global pfn_ADL_Adapter_BoardLayout_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Adapter_BoardLayout_Get Then Call Dword pfn_ADL_Adapter_BoardLayout_Get Using ADL_Adapter_BoardLayout_Get(iAdapterIndex, lpValidFlags, lpNumberSlots, lppBracketSlot, lpNumberConnector, lppConnector) To ADL_err
  Function = ADL_err
End Function

Function ADL_Adapter_ConnectionData_Get(ByVal iAdapterIndex As Long, ByVal devicePort As ADL_DEVICE_PORT, ByVal iQueryType As Long, ByRef ConnectionData As ADL_CONNECTION_DATA) As Long
  Global pfn_ADL_Adapter_ConnectionData_Get As Long
  Local ADL_err As Long
  If pfn_ADL_Adapter_ConnectionData_Get Then Call Dword pfn_ADL_Adapter_ConnectionData_Get Using ADL_Adapter_ConnectionData_Get(iAdapterIndex, devicePort, iQueryType, ConnectionData) To ADL_err
  Function = ADL_err
End Function

Function ADL_Adapter_ConnectionData_Set(ByVal iAdapterIndex As Long, ByVal devicePort As ADL_DEVICE_PORT, ByVal ConnectionData As ADL_CONNECTION_DATA) As Long
  Global pfn_ADL_Adapter_ConnectionData_Set As Long
  Local ADL_err As Long
  If pfn_ADL_Adapter_ConnectionData_Set Then Call Dword pfn_ADL_Adapter_ConnectionData_Set Using ADL_Adapter_ConnectionData_Set(iAdapterIndex, devicePort, ConnectionData) To ADL_err
  Function = ADL_err
End Function

'============================================================
'  ADL_open
'============================================================

Function ADL_open(driver_release As String) Common As Long

  If h_dll Then Exit Function
  If UBound(adapter()) <> -1 Then Exit Function

  h_dll = LoadLibrary("atiadlxy.dll")
  If IsFalse h_dll Then Exit Function

  clog "ADL Library found, retrieving functions..."
  pfn_ADL_Main_Control_Create = GetProcAddress(h_dll, "ADL_Main_Control_Create")
  pfn_ADL_Main_Control_Destroy = GetProcAddress(h_dll, "ADL_Main_Control_Destroy")
  pfn_ADL_Adapter_NumberOfAdapters_Get = GetProcAddress(h_dll, "ADL_Adapter_NumberOfAdapters_Get")
  pfn_ADL_Adapter_AdapterInfo_Get = GetProcAddress(h_dll, "ADL_Adapter_AdapterInfo_Get")
  pfn_ADL_Display_DisplayInfo_Get = GetProcAddress(h_dll, "ADL_Display_DisplayInfo_Get")
  pfn_ADL_Display_ModeTimingOverride_Get = GetProcAddress(h_dll, "ADL_Display_ModeTimingOverride_Get")
  pfn_ADL_Display_ModeTimingOverride_Set = GetProcAddress(h_dll, "ADL_Display_ModeTimingOverride_Set")
  pfn_ADL_Display_ModeTimingOverrideList_Get = GetProcAddress(h_dll, "ADL_Display_ModeTimingOverrideList_Get")
  pfn_ADL_Adapter_BoardLayout_Get = GetProcAddress(h_dll, "ADL_Adapter_BoardLayout_Get")
  pfn_ADL_Adapter_ConnectionData_Get = GetProcAddress(h_dll, "ADL_Adapter_ConnectionData_Get")
  pfn_ADL_Adapter_ConnectionData_Set = GetProcAddress(h_dll, "ADL_Adapter_ConnectionData_Set")

  If ADL_Main_Control_Create(CodePtr(ADL_Main_Memory_Alloc), 1) <> %ADL_OK Then exit_error
  If IsFalse enum_displays(h_dll) Then exit_error
  If IsFalse enum_connectors(h_dll) Then exit_error
  cat_version = Val(Parse$(driver_release, ".", 1))

  clog "ADL functions retrieved successfully."
  Function = 1
  Exit Function

exit_error:
  clog "ADL error retrieving functions."
  FreeLibrary(h_dll)

End Function

'============================================================
'  ADL_close
'============================================================

Function ADL_close() Common As Long

  If IsFalse h_dll Then Exit Function

  Local i As Long
  For i = 1 To UBound(adapter()) - LBound(adapter())
    ADL_Main_Memory_Free(adapter(i).m_display_list)
  Next

  Local ADL_Err As Long
  ADL_Err = ADL_Main_Control_Destroy()

  FreeLibrary(h_dll)
  h_dll = 0
  Erase adapter()
  Erase connector()

  Function = ADL_Err
End Function

'============================================================
'  ADL_Main_Memory_Alloc
'============================================================

Function ADL_Main_Memory_Alloc(ByVal iSize As Long) As Dword
  Function = HeapAlloc(GetProcessHeap(), %HEAP_ZERO_MEMORY Or %HEAP_GENERATE_EXCEPTIONS, iSize)
End Function

'============================================================
'  ADL_Main_Memory_Free
'============================================================

Function ADL_Main_Memory_Free(ByVal lpBuffer As Long Ptr) As Dword
  If IsFalse lpBuffer Then Exit Function
  Function = HeapFree(getProcessHeap(), 0, @lpBuffer)
End Function

'============================================================
'  enum_displays
'============================================================

Function enum_displays(h_dll As Long) As Long

  If ADL_Adapter_NumberOfAdapters_Get(VarPtr(num_of_adapters)) <> %ADL_OK Then Exit Function

  Dim adapter_info_list(num_of_adapters) As Global ADAPTER_INFO
  If ADL_Adapter_AdapterInfo_Get(VarPtr(adapter_info_list(0)), SizeOf(ADAPTER_INFO) * num_of_adapters) <> %ADL_OK Then Exit Function

  Dim adapter(num_of_adapters) As Global ADAPTER_LIST
  Local i As Long
  For i = 0 To num_of_adapters - 1
    adapter(i).m_index = adapter_info_list(i).iAdapterIndex
    adapter(i).m_bus = adapter_info_list(i).iBusNumber
    adapter(i).m_name = Trim$(adapter_info_list(i).strAdapterName, Any $Spc + Chr$(0))
    adapter(i).m_display_name = Trim$(adapter_info_list(i).strDisplayName, Any $Spc + Chr$(0))
    adapter(i).m_num_of_displays = 0
    adapter(i).m_display_list = 0

    Local result As Long
    result = ADL_Display_DisplayInfo_Get(adapter(i).m_index, adapter(i).m_num_of_displays, VarPtr(adapter(i).m_display_list), 1)
    #If %LOG
      clog Using$("adapter(#).m_index #", i, adapter(i).m_index)
      clog Using$("adapter(#).m_bus #", i, adapter(i).m_bus)
      clog Using$("adapter(#).m_name &", i, adapter(i).m_name)
      clog Using$("adapter(#).m_display_name &", i, adapter(i).m_display_name)
      clog Using$("adapter(#).m_num_of_displays #", i, adapter(i).m_num_of_displays)
    #EndIf
    If result <> %ADL_OK Then Iterate For
  Next
  Function = 1
End Function

'============================================================
'  enum_connectors_from_adapter
'============================================================

Function ADL_enum_connectors_from_adapter(index As Long, connector_label As String) Common As Long

  Local first_adapter As Long
  For first_adapter = 0 To num_of_adapters
    If adapter(first_adapter).m_num_of_displays <> 0 Then Exit For
  Next

  Dim display_list(adapter(first_adapter).m_num_of_displays) As ADL_DISPLAY_INFO At adapter(first_adapter).m_display_list
  Local i, j As Long
  For j = 0 To adapter(first_adapter).m_num_of_displays - 1
    Local is_valid_connector, is_analog As Long
    Local connector_type As String
    is_valid_connector = 1
    is_analog = 0

    Select Case display_list(j).iDisplayConnector
      Case %ADL_DISPLAY_CONTYPE_VGA
        connector_type = "VGA"
        is_analog = 1
      Case %ADL_DISPLAY_CONTYPE_DVI_D
        connector_type = "DVI-D"
      Case %ADL_DISPLAY_CONTYPE_DVI_I
        connector_type = "DVI-I"
      Case %ADL_DISPLAY_CONTYPE_HDMI_TYPE_A
        connector_type = "HDMI-A"
      Case %ADL_DISPLAY_CONTYPE_HDMI_TYPE_B
        connector_type = "HDMI-B"
      'case %ADL_DISPLAY_CONTYPE_DISPLAYPORT
      '  connector_type = "DP"
      Case Else
        is_valid_connector = 0
    End Select

    If connector_label <> "" Then
      If display_list(j).displayID.iDisplayLogicalIndex = Val(Parse$(connector_label, "_", 2)) Then
        connector_label = LCase$(Parse$(connector_type, "-", 1))
        Function = 1
        Exit Function
      End If

    ElseIf is_valid_connector Then
      If index = i Then
        connector_label = Using$(IIf$(is_analog, "Analog__", "Digital__") + "#", display_list(j).displayID.iDisplayLogicalIndex) + "-" + connector_type
        Function = 1
        Exit Function
      End If
      Incr i
    End If

    #If %LOG
      clog Using$("logical__adapter__index: # logical__index: # physical__index: #, display__connector: #", display_list(j).displayID.iDisplayLogicalAdapterIndex,_
       display_list(j).displayID.iDisplayLogicalIndex, display_list(j).displayID.iDisplayPhysicalIndex, display_list(j).iDisplayConnector)
    #EndIf
  Next
End Function

'============================================================
'  enum_connectors
'============================================================

Function enum_connectors(h_dll As Long) As Long

  Local num_of_adapters As Long
  num_of_adapters = UBound(adapter()) - LBound(adapter())
  If IsFalse num_of_adapters Then Exit Function

  Local c_count As Long

  Local i, j, k As Long
  For i = 0 To num_of_adapters - 1
    Local valid_flags, num_of_slots, num_of_connectors As Long
    Local bracket_slot_info As ADL_BRACKET_SLOT_INFO Ptr
    Local connector_info As ADL_CONNECTOR_INFO Ptr
    If ADL_Adapter_BoardLayout_Get(adapter(i).m_index, valid_flags, num_of_slots, VarPtr(bracket_slot_info), num_of_connectors, VarPtr(connector_info)) <> %ADL_OK Then Iterate For

    Dim connector(num_of_connectors) As Global CONNECTOR_LIST
    Dim connector_info_list(num_of_connectors) As ADL_CONNECTOR_INFO At connector_info

    For j = 0 To num_of_connectors - 1
      Local c_found As Long
      For k = 0 To c_count
        If connector(k).m_index = connector_info_list(j).iConnectorIndex And connector(k).m_bus = adapter(i).m_bus Then c_found = 1 : Exit For
      Next
      If c_found = 0 Then
        connector(c_count).m_index = connector_info_list(j).iConnectorIndex
        connector(c_count).m_bus = adapter(i).m_bus
        connector(c_count).m_adapter = adapter(i).m_index
        Local m_name As String
        Select Case connector_info_list(j).iType
          Case %ADL_CONNECTOR_TYPE_UNKNOWN              : m_name = "Unknown"
          Case %ADL_CONNECTOR_TYPE_VGA                  : m_name = "VGA"
          Case %ADL_CONNECTOR_TYPE_DVI_D                : m_name = "DVI-D"
          Case %ADL_CONNECTOR_TYPE_DVI_I                : m_name = "DVI-I"
          Case %ADL_CONNECTOR_TYPE_ATICVDONGLE_NA       : m_name = "ATI CV Dongle NA"
          Case %ADL_CONNECTOR_TYPE_ATICVDONGLE_JP       : m_name = "ATI CV Dongle JP"
          Case %ADL_CONNECTOR_TYPE_ATICVDONGLE_NONI2C   : m_name = "ATI CV Dongle NONI2C"
          Case %ADL_CONNECTOR_TYPE_ATICVDONGLE_NONI2C_D : m_name = "ATI CV Dongle NONI2C_D"
          Case %ADL_CONNECTOR_TYPE_HDMI_TYPE_A          : m_name = "HDMI-A"
          Case %ADL_CONNECTOR_TYPE_HDMI_TYPE_B          : m_name = "HDMI-B"
          Case %ADL_CONNECTOR_TYPE_DISPLAYPORT          : m_name = "DisplayPort"
          Case %ADL_CONNECTOR_TYPE_EDP                  : m_name = "EDP"
          Case %ADL_CONNECTOR_TYPE_MINI_DISPLAYPORT     : m_name = "Mini DisplayPort"
          Case %ADL_CONNECTOR_TYPE_VIRTUAL              : m_name = "Virtual"
        End Select
        connector(c_count).m_name = m_name
        clog Using$("Connector # " + $Tab + "&", connector(c_count).m_index, connector(c_count).m_name)
        Incr c_count
      End If
    Next
  Next

  Function = 1
End Function

'============================================================
'  ADL_add_edid
'============================================================

Function ADL_add_edid(c_index As Long, edid As EDID_BLOCK) As Long

  Local num_of_connectors As Long
  num_of_connectors = UBound(connector()) - LBound(connector())
  If IsFalse num_of_connectors Then Exit Function

  Local device_port As ADL_DEVICE_PORT
  Local connection_data As ADL_CONNECTION_DATA
  Local connection_properties As ADL_CONNECTION_PROPERTIES

  clog Using$("adapter:# connector:#", connector(c_index).m_adapter, connector(c_index).m_index)

  device_port.iConnectorIndex = connector(c_index).m_index
  connection_properties.iValidProperties = &h10
  connection_properties.iColorDepth = 2
  connection_data.iConnectionType = 3
  connection_data.iNumberofPorts = 1
  connection_data.iActiveConnections = 1
  connection_data.iDataSize = SizeOf(EDID_BLOCK)
  Local edid_dest As EDID_BLOCK Ptr
  edid_dest = VarPtr(connection_data.EdidData(0))
  @edid_dest = edid
  If ADL_Adapter_ConnectionData_Set(connector(c_index).m_adapter, device_port, connection_data) <> %ADL_OK Then MsgBox "error"

End Function

'============================================================
'  get_device_mapping_from_display_name
'============================================================

Function get_device_mapping_from_display_name(target_display As String, adapter_index As Long, display_index As Long) As Long

  Local num_of_adapters As Long
  num_of_adapters = UBound(adapter()) - LBound(adapter())
  If IsFalse num_of_adapters Then Exit Function

  Local i, j As Long
  For i = 0 To num_of_adapters - 1
    If target_display <> adapter(i).m_display_name Then Iterate For
    Dim display_list(adapter(i).m_num_of_displays) As ADL_DISPLAY_INFO At adapter(i).m_display_list
    For j = 0 To adapter(i).m_num_of_displays - 1
      If adapter(i).m_index = display_list(j).displayID.iDisplayLogicalAdapterIndex Then
        adapter_index = adapter(i).m_index
        display_index = display_list(j).displayID.iDisplayLogicalIndex
        Function = 1
        Exit Function
      End If
    Next
  Next

End Function

'============================================================
'  ADL_display_mode_info_to_modeline
'============================================================

Function ADL_display_mode_info_to_modeline(dmi As ADL_DISPLAY_MODE_INFO, m As MODELINE) As Long

  If IsFalse dmi.sDetailedTiming.sHTotal Then Exit Function

  Local dt As ADL_DETAILED_TIMING
  dt = dmi.sDetailedTiming

  If dt.sHTotal = 0 Then Exit Function

  m.htotal    = dt.sHTotal
  m.hactive   = dt.sHDisplay
  m.hbegin    = dt.sHSyncStart
  m.hend      = dt.sHSyncWidth + m.hbegin
  m.vtotal    = dt.sVTotal
  m.vactive   = dt.sVDisplay
  m.vbegin    = dt.sVSyncStart
  m.vend      = dt.sVSyncWidth + m.vbegin
  m.interlace = IIf((dt.sTimingFlags And %ADL_DL_TIMINGFLAG_INTERLACED), 1, 0)
  m.doublescan = IIf((dt.sTimingFlags And %ADL_DL_TIMINGFLAG_DOUBLE_SCAN), 1, 0)
  m.hsync     = IIf((dt.sTimingFlags And %ADL_DL_TIMINGFLAG_H_SYNC_POLARITY), 1, 0) Xor invert_pol(1)
  m.vsync     = IIf((dt.sTimingFlags And %ADL_DL_TIMINGFLAG_V_SYNC_POLARITY), 1, 0) Xor invert_pol(1)
  m.pclock    = dt.sPixelClock * 10000

  m.height  = IIf(m.height, m.height, dmi.iPelsHeight)
  m.width   = IIf(m.width, m.width, dmi.iPelsWidth)
  m.bpp     = IIf(m.bpp, m.bpp, 32)
  m.refresh = IIf(m.refresh, m.refresh, dmi.iRefreshRate / interlace_factor(m.interlace, 0))
  modeline_compute_frequency(m)

  Function = 1
End Function

'============================================================
'  ADL_get_modeline_list
'============================================================

Function ADL_get_modeline_list(target_display As String, m() As MODELINE) Common As Long

  Local adapter_index, display_index As Long
  Local num_of_overrides As Long

  If IsFalse get_device_mapping_from_display_name(target_display, adapter_index, display_index) Then Exit Function

  Dim timing_cache(%MAX_TIMING_OVERRIDES) As Global ADL_DISPLAY_MODE_INFO
  If ADL_Display_ModeTimingOverrideList_Get(adapter_index, display_index, %MAX_TIMING_OVERRIDES, ByVal VarPtr(timing_cache(0)), num_of_overrides) <> %ADL_OK Then Exit Function

  Local i As Long
  While timing_cache(i).iPelsHeight
    ADL_display_mode_info_to_modeline(timing_cache(i), m(i))
    Incr i
  Wend

  Function = num_of_overrides
End Function

'============================================================
'  ADL_delete_modeline_list
'============================================================

Function ADL_delete_modeline_list(target_display As String) Common As Long

  Dim m(%MAX_TIMING_OVERRIDES) As MODELINE
  Local num_of_overrides As Long

  num_of_overrides = ADL_get_modeline_list(target_display, m())

  Local i As Long
  For i = 0 To num_of_overrides - 1
    ADL_set_modeline(target_display, m(i), %MODELINE_DELETE Or IIf(i < num_of_overrides - 1, 0, %MODELINE_UPDATE_LIST))
  Next

End Function

'============================================================
'  ADL_set_modeline_list
'============================================================

Function ADL_set_modeline_list(target_display As String, m() As MODELINE) Common As Long

  Local i As Long

  ADL_delete_modeline_list(target_display)

  While m(i).width
    If IsFalse ADL_set_modeline(target_display, m(i), %MODELINE_CREATE Or IIf(m(i+1).width, 0, %MODELINE_UPDATE_LIST)) Then clog Using$("Mode & rejected by driver.", modeline_print(m(i), %MS_LABEL))
    Incr i
  Wend

  Function = i
End Function

'============================================================
'  ADL_get_modeline_from_cache
'============================================================

Function ADL_get_modeline_from_cache(target_display As String, m As MODELINE) Common As Long

  Local adapter_index, display_index As Long
  Static adapter_index_prev, display_index_prev As Long
  Static already_initialized As Long
  Local num_of_overrides As Long

  If IsFalse get_device_mapping_from_display_name(target_display, adapter_index, display_index) Then Exit Function

  ' Only retrieve the whole list timing overrides the first time it's run or when we're targeting a new display
  If (IsFalse already_initialized) Or adapter_index <> adapter_index_prev Or display_index <> display_index_prev Then
    Dim timing_cache(%MAX_TIMING_OVERRIDES) As Global ADL_DISPLAY_MODE_INFO
    If ADL_Display_ModeTimingOverrideList_Get(adapter_index, display_index, %MAX_TIMING_OVERRIDES, ByVal VarPtr(timing_cache(0)), num_of_overrides) <> %ADL_OK Then Exit Function
    already_initialized = 1
    adapter_index_prev = adapter_index
    display_index_prev = display_index
  End If

  Local i As Long
  While timing_cache(i).iPelsHeight
    If timing_cache(i).iPelsHeight = m.height And timing_cache(i).iPelsWidth = m.width And timing_cache(i).iRefreshRate = m.refresh * IIf(m.interlace, 2, 1) Then
      ADL_display_mode_info_to_modeline(timing_cache(i), m)
      GoTo found
    End If
    Incr i
  Wend
  Exit Function

found:
  Function = 1
End Function

'============================================================
'  ADL_get_modeline
'============================================================

Function ADL_get_modeline(target_display As String, m As MODELINE) Common As Long

  Local adapter_index, display_index As Long
  Local mode_in As ADL_DISPLAY_MODE
  Local mode_info_out As ADL_DISPLAY_MODE_INFO
  Local m_temp As MODELINE
  m_temp = m

  'MODELINE to ADL_DISPLAY_MODE
  mode_in.iPelsHeight       = m.height
  mode_in.iPelsWidth        = m.width
  mode_in.iBitsPerPel       = m.bpp
  mode_in.iDisplayFrequency =  m.refresh * interlace_factor(m.interlace, 1)

  If IsFalse get_device_mapping_from_display_name(target_display, adapter_index, display_index) Then Exit Function

  If ADL_Display_ModeTimingOverride_Get(adapter_index, display_index, mode_in, mode_info_out) <> %ADL_OK Then Exit Function
  If ADL_display_mode_info_to_modeline(mode_info_out, m_temp) Then
    If m_temp.interlace = m.interlace Then
      m = m_temp
      Function = 1
    End If
  End If
End Function

'============================================================
'  ADL_set_modeline
'============================================================

Function ADL_set_modeline(target_display As String, m As MODELINE, update_mode As Long) Common As Long

  Local adapter_index, display_index As Long
  Local mode_info As ADL_DISPLAY_MODE_INFO
  Local dt As ADL_DETAILED_TIMING Ptr

  'MODELINE to ADL_DISPLAY_MODE_INFO
  mode_info.iTimingStandard   = IIf((update_mode And %MODELINE_DELETE), %ADL_DL_MODETIMING_STANDARD_DRIVER_DEFAULT, %ADL_DL_MODETIMING_STANDARD_CUSTOM)
  mode_info.iPossibleStandard = 0
  mode_info.iRefreshRate      = m.refresh * interlace_factor(m.interlace, 0)
  mode_info.iPelsWidth        = m.width
  mode_info.iPelsHeight       = m.height

  'MODELINE ADL_DETAILED_TIMING
  dt = VarPtr(mode_info.sDetailedTiming)
  @dt.sTimingFlags     = IIf(m.interlace, %ADL_DL_TIMINGFLAG_INTERLACED, 0) Or _
                         IIf(m.doublescan, %ADL_DL_TIMINGFLAG_DOUBLE_SCAN, 0) Or _
                         IIf(m.hsync Xor invert_pol(0), %ADL_DL_TIMINGFLAG_H_SYNC_POLARITY, 0) Or _
                         IIf(m.vsync Xor invert_pol(0), %ADL_DL_TIMINGFLAG_V_SYNC_POLARITY, 0)
  @dt.sHTotal          = m.htotal
  @dt.sHDisplay        = m.hactive
  @dt.sHSyncStart      = m.hbegin
  @dt.sHSyncWidth      = m.hend - m.hbegin
  @dt.sVTotal          = m.vtotal
  @dt.sVDisplay        = m.vactive
  @dt.sVSyncStart      = m.vbegin
  @dt.sVSyncWidth      = m.vend - m.vbegin
  @dt.sPixelClock      = m.pclock / 10000
  @dt.sHOverscanRight  = 0
  @dt.sHOverscanLeft   = 0
  @dt.sVOverscanBottom = 0
  @dt.sVOverscanTop    = 0

  If IsFalse get_device_mapping_from_display_name(target_display, adapter_index, display_index) Then Exit Function
  If ADL_Display_ModeTimingOverride_Set(adapter_index, display_index, mode_info, IIf((update_mode And %MODELINE_UPDATE_LIST), 1, 0)) <> %ADL_OK Then clog "error" : Exit Function
  If (update_mode And %MODELINE_UPDATE) Then ADL_get_modeline(target_display, m)

  Function = 1
End Function

Function invert_pol(on_read As Long) As Long
  Function = IIf(cat_version <= 12 Or (cat_version >= 15 And on_read), 1, 0)
End Function

Function interlace_factor(interlace As Long, on_read As Long) As Long
  Function = IIf(interlace And (cat_version <= 12 Or (cat_version >= 15 And on_read)), 2, 1)
End Function

'============================================================
'  ADL_csync_read
'============================================================

Function ADL_csync_read(ByVal target_key As String, ByVal target_display As String) Common As Long

  Local csync As String
  csync = get_reg(%HKEY_LOCAL_MACHINE, target_key + ADL_csync_get_key(target_display), "CompositeSync", %REG_BINARY)
  If csync <> "" Then Function = Asc(Mid$(csync, 5))
ADL_get_all_nodes(target_key + ADL_csync_get_key(target_display))
End Function

'============================================================
'  ADL_csync_enable
'============================================================

Function ADL_csync_enable(ByVal target_key As String, ByVal target_display As String) Common As Long

  set_reg(%HKEY_LOCAL_MACHINE, target_key, "DalAllowCompositeSyncAdjustment", %REG_DWORD, Chr$(1))
  set_reg(%HKEY_LOCAL_MACHINE, target_key, "DalAllowHsyncVsyncAdjustment", %REG_DWORD, Chr$(1))

  Local csync, csync_key As String
  csync = Chr$(1, 0, 0, 0, 1, 0, 0, 0)
  csync_key = target_key + ADL_csync_get_key(target_display)

  Local all_nodes As String
  all_nodes = ADL_get_all_nodes(csync_key) + ";CompositeSync;HorizontalSync;VerticalSync" + Chr$(0)
  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, csync_key, "All_nodes", %REG_BINARY, all_nodes) Then Exit Function
  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, csync_key, "CompositeSync", %REG_BINARY, csync) Then Exit Function
  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, csync_key, "HorizontalSync", %REG_BINARY, csync) Then Exit Function
  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, csync_key, "VerticalSync", %REG_BINARY, csync) Then Exit Function

  Function = 1

End Function

'============================================================
'  ADL_csync_disable
'============================================================

Function ADL_csync_disable(ByVal target_key As String, ByVal target_display As String) Common As Long

  Local csync_key As String
  csync_key = target_key + ADL_csync_get_key(target_display)
  If IsFalse set_reg(%HKEY_LOCAL_MACHINE, csync_key, "All_nodes", %REG_BINARY, ADL_get_all_nodes(csync_key) + Chr$(0)) Then Exit Function
  If IsFalse del_reg(%HKEY_LOCAL_MACHINE, csync_key, "CompositeSync") Then Exit Function
  If IsFalse del_reg(%HKEY_LOCAL_MACHINE, csync_key, "HorizontalSync") Then Exit Function
  If IsFalse del_reg(%HKEY_LOCAL_MACHINE, csync_key, "VerticalSync") Then Exit Function

  Function = 1

End Function

'============================================================
'  ADL_csync_get_key
'============================================================

Function ADL_csync_get_key(target_display As String) As String

  Local adapter_index, display_index As Long
  If IsFalse get_device_mapping_from_display_name(target_display, adapter_index, display_index) Then Exit Function
  Function = "\DAL2_DATA__2_0\DisplayPath_" + Using$("#", display_index) +"\Adjustment\"

End Function


'============================================================
'  ADL_get_all_nodes
'============================================================

Function ADL_get_all_nodes(target_key As String) As String

  Local all_nodes As String
  all_nodes = Trim$(get_reg(%HKEY_LOCAL_MACHINE, target_key, "All_nodes", %REG_BINARY), Chr$(0))

  If all_nodes <> "" Then
    Local i, node_count As Long
    node_count = ParseCount(all_nodes, ";")

    ' Remove the sync adjustments
    Dim node(1 To node_count) As String
    Parse all_nodes, node(), ";"
    all_nodes = ""
    For i = 1 To node_count
      If node(i) = "CompositeSync" Or node(i) = "HorizontalSync" Or node(i) = "VerticalSync" Then Iterate For
      all_nodes = all_nodes + node(i) + ";"
    Next
  End If
  Function = RTrim$(all_nodes, ";")

End Function
