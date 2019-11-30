
'============================================================
'  Functions
'============================================================

Declare Function command_line_init(h_dialog As Long, idc_prompt As Long, idc_command As Long, x As Long, y As Long, c_width As Long, c_height As Long, prompt As String) Common As Long
Declare Function command_line_resize(x As Long, y As Long, c_width As Long, c_height As Long) Common As Long
Declare Function command_line_set_focus() Common As Long
