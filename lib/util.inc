'============================================================
'  Utility library
'  util.inc
'============================================================

#If Not %Def(%IS_HOST_APP)
Declare Function os_version() Common As Long
Declare Function is_user_admin() Common As Long
Declare Function is_elevated() Common As Long
Declare Function is_64() Common As Long
Declare Function is_already_running(app_name As AsciiZ) Common As Long
Declare Function dir_exists(ByVal dir_path As String) Common As Long
Declare Function file_exists(ByVal file_path As String) Common As Long
Declare Function file_to_string(ByVal file_name As String, Optional ByVal file_pos As Long, Optional ByVal bytes_to_read As Long) Common As String
Declare Function file_compare(ByVal file_a As String, ByVal file_b As String) Common As Long
Declare Function launch_command(exe_file As String, params As String, redirect_output As String) Common As Dword
Declare Function launch_command_elevated(exe_file As AsciiZ, params As AsciiZ, hwnd As Long) Common As Dword
Declare Function system_error_message_text(error_code As Dword) Common As String
Declare Function norm(a As Long, b As Long) Common As Long
Declare Function get_reg (hLocation As Dword, SubKey As String, ValueName As String, lpType As Dword) Common As String
Declare Function set_reg(hLocation As Dword, sSubKeys As String, sValueName As String, dwType As Dword, sData As String) Common As Long
Declare Function del_reg(hLocation As Dword, sSubKeys As String, sValueName As String) Common As Long
#EndIf
