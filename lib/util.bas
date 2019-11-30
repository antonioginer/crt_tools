'============================================================
'  Utility library
'  util.bas
'============================================================

#Compile SLL
#Dim All
#Include "win32api.inc"

'============================================================
'  os_version
'============================================================

Function os_version() Common As Long

  Local lpVersionInfo As OSVERSIONINFO

  lpVersionInfo.dwOSVersionInfoSize = SizeOf(lpVersionInfo)
  GetVersionEx (lpVersionInfo)

  Function = lpVersionInfo.dwMajorVersion
End Function

'============================================================
'  is_user_admin
'============================================================

Function is_user_admin() Common As Long

  Local b As Long
  Local NtAuthority As SID_IDENTIFIER_AUTHORITY
  Local AdministratorsGroup As Long

  NtAuthority.value(5) = 5 '%SECURITY_NT_AUTHORITY

  b = AllocateAndInitializeSid(NtAuthority, 2, %SECURITY_BUILTIN_DOMAIN_RID, %DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, AdministratorsGroup)
  If b And IsFalse CheckTokenMembership(%NULL, ByVal AdministratorsGroup, b) Then Function = %FALSE Else Function = %TRUE
  FreeSid(ByVal AdministratorsGroup)

End Function

'============================================================
'  is_elevated
'============================================================

Function is_elevated() Common As Long

  Local htoken As Long
  Function = %FALSE

  If IsFalse OpenProcessToken(GetCurrentProcess(), %TOKEN_QUERY, htoken) Then Exit Function

  Local te As TOKEN_ELEVATION
  Local dw_return_length As Dword

  If GetTokenInformation(htoken, %TokenElevation, te, SizeOf(te), dw_return_length) Then
    If dw_return_length = SizeOf(te) And te.TokenIsElevated Then Function = %TRUE
  End If

  CloseHandle(htoken)

End Function

'============================================================
'  is_64
'============================================================

Function is_64() Common As Long

  Local ptr_function As Long
  Local is_wow64 As Long

  ptr_function = GetProcAddress(GetModuleHandle("KERNEL32.DLL"), "IsWow64Process")
  If IsFalse ptr_function Then Exit Function

  Call Dword ptr_function Using IsWow64Process(GetCurrentProcess(), is_wow64)
  Function = is_wow64
End Function

'============================================================
'  is_already_running
'============================================================

Function is_already_running(app_name As AsciiZ) Common As Long

  Local h_mutex As Long
  h_mutex = CreateMutex(ByVal %Null, 0, app_name)
  If IsFalse h_mutex Then Exit Function
  If GetLastError() = %ERROR_ALREADY_EXISTS Then Function = 1

End Function

'============================================================
'  dir_exists
'============================================================

Function dir_exists(ByVal dir_path As String) Common As Long

  On Error GoTo error_handler
  Function = GetAttr(dir_path) And %SubDir

error_handler:
End Function

'============================================================
'  file_exists
'============================================================

Function file_exists(ByVal file_path As String) Common As Long

  On Error GoTo error_handler
  Local temp As Long
  temp = GetAttr(file_path)
  Function = 1

error_handler:
End Function

'============================================================
'  file_to_string
'============================================================

Function file_to_string(ByVal file_name As String, Optional ByVal file_pos As Long, Optional ByVal bytes_to_read As Long) Common As String

  Local file_number As Long
  Local contents As String

  file_number = FreeFile

  Open file_name For Binary As file_number Base = 0
  Seek file_number, file_pos
  Get$ file_number, IIf(bytes_to_read, bytes_to_read, Lof(file_number) - file_pos), contents
  Close file_number

  Function = contents
End Function

'============================================================
'  file_compare
'============================================================

Function file_compare(ByVal file_a As String, ByVal file_b As String) Common As Long

  Local a, b As Long
  Local a_contents, b_contents As WString

  a = FreeFile
  b = FreeFile
  Open file_a For Binary As a
  Open file_b For Binary As b
  Get$ a, 1024 * 1024, a_contents
  Get$ b, 1024 * 1024, b_contents
  If a_contents = b_contents Then Function = 1

End Function

'============================================================
'  launch_command
'============================================================

Function launch_command(exe_file As String, params As String, redirect_output As String) Common As Dword

  Local si As STARTUPINFO
  Local pi As PROCESS_INFORMATION
  Local i_ret As Long
  Local exit_code As Dword
  Local h_out, h_out_sys As Long

  si.cb = SizeOf(si)
  si.dwFlags = %STARTF_USESTDHANDLES

  If redirect_output <> "" Then
    h_out = FreeFile
    Open redirect_output For Output As h_out
    h_out_sys = FileAttr(h_out, 2)
    si.hStdInput = getStdHandle (%STD_INPUT_HANDLE)
    si.hStdError = getStdHandle (%STD_ERROR_HANDLE)
    si.hStdOutput= h_out_sys
  End If

  i_ret = CreateProcess(Trim$(exe_file), $Dq + Trim$(exe_file) + $Dq + $Spc + params, ByVal %NULL, ByVal %NULL, ByVal %TRUE, ByVal %NULL, ByVal %NULL, ByVal %NULL, si, pi)

  If IsTrue i_ret Then
    WaitForSingleObject(pi.hProcess, %INFINITE)
    GetExitCodeProcess(pi.hProcess, exit_code)
    CloseHandle(pi.hProcess)
    CloseHandle(pi.hThread)
    Function = exit_code
  Else
    MsgBox system_error_message_text(GetLastError()), %MB_Ok Or %MB_IconError, "Error"
    Function = -1
  End If

  If h_out Then Close h_out

End Function

'============================================================
'  launch_command_elevated
'============================================================

Function launch_command_elevated(exe_file As AsciiZ, params As AsciiZ, hwnd As Long) Common As Dword

  Local shExInfo As SHELLEXECUTEINFO
  Local exit_code As Dword
  Local verb As StringZ * 16

  verb = "runas"

  shExInfo.cbSize = SizeOf(shExInfo)
  shExInfo.fMask = %SEE_MASK_NOCLOSEPROCESS
  shExInfo.hwnd = hwnd
  shExInfo.lpVerb = VarPtr(verb)
  shExInfo.lpFile = VarPtr(exe_file)
  shExInfo.lpParameters = VarPtr(params)
  shExInfo.lpDirectory = 0
  shExInfo.nShow = %SW_Hide
  shExInfo.hInstApp = 0

  If (ShellExecuteEx(shExInfo)) Then
    WaitForSingleObject(shExInfo.hProcess, %INFINITE)
    GetExitCodeProcess(shExInfo.hProcess, exit_code)
    CloseHandle(shExInfo.hProcess)
    Function = exit_code
  Else
    MsgBox system_error_message_text(GetLastError()), %MB_Ok Or %MB_IconError, "Error"
    Function = -1
  End If

End Function

'============================================================
'  system_error_message_text
'============================================================

Function system_error_message_text(error_code As Dword) Common As String

  Local buffer As StringZ * 255
  Local sText As String

  FormatMessage %FORMAT_MESSAGE_FROM_SYSTEM, ByVal %Null, error_code, %Null, buffer, SizeOf(buffer), ByVal %Null
  sText = Hex$(error_code) + $Spc + buffer
  Function = Trim$( sText )

End Function

'============================================================
'  norm
'============================================================

Function norm(a As Long, b As Long) Common As Long

  Local c, d As Long
  c = a Mod b
  d = Int (a / b)
  If c Then d += 1

  Function = d * b
End Function

'============================================================
'  get_reg
'============================================================

Function get_reg(hLocation As Dword, SubKey As String, ValueName As String, lpType As Dword) Common As String

  Local hKey As Dword
  Local lpValueName As AsciiZ * 1024
  Local lpData As String * (1024 * 3)
  Local lpcbData As Dword

  If hLocation = 0 Then
    hLocation = %HKEY_LOCAL_MACHINE
  End If

  If RegOpenKeyEx(hLocation, Trim$(SubKey, "\"), ByVal %NULL, %KEY_READ, hKey) = %ERROR_SUCCESS Then
    lpValueName = ValueName
    lpcbData = SizeOf (lpData)
    If RegQueryValueEx (hKey, lpValueName, 0, lpType, lpData, lpcbData) = %ERROR_SUCCESS Then Function = Left$ (lpData, lpcbData)
    RegCloseKey hKey
  End If

End Function

'============================================================
'  set_reg
'============================================================

Function set_reg(hLocation As Dword, sSubKeys As String, sValueName As String, dwType As Dword, sData As String) Common As Long

  Local hKey As Dword
  Local zRegName As AsciiZ * 1024
  Local zRegVal As String * 1024
  Local dwSize As Dword

  Local i As Long

  zRegVal = sData
  zRegName = sValueName
  dwSize = Len (sDATA)

  If hLocation = 0 Then
    hLocation = %HKEY_LOCAL_MACHINE
  End If

  If RegCreateKeyEx(hLocation, Trim$(sSubKeys, "\"), 0, "", 0, %KEY_WRITE, ByVal %Null, hKey, ByVal %Null) = %ERROR_SUCCESS Then
    Function = (RegSetValueEx(hKey, zRegName, 0, dwType, zRegVal, dwSize) = %ERROR_SUCCESS)
    RegCloseKey hKey
  End If

End Function

'============================================================
'  del_reg
'============================================================

Function del_reg(hLocation As Dword, sSubKeys As String, sValueName As String) Common As Long

  Local h_key As Long
  Local zRegName As AsciiZ * 1024
  zRegName = sValueName

  If RegOpenKeyEx(%HKEY_LOCAL_MACHINE, Trim$(sSubKeys, "\"), ByVal %Null, %KEY_ALL_ACCESS, h_key) <> %ERROR_SUCCESS Then Exit Function
  If RegDeleteValue(h_key, zRegName) <> %ERROR_SUCCESS Then Exit Function

  Function = 1
End Function
