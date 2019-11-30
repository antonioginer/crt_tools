@echo off
set PB_BINARY="%ProgramFiles(x86)%\PBWin10\bin\PBWin.exe"
set INCLUDE_PATHS=..\lib;"%ProgramFiles(x86)%\PBWin10\Roca"

cd .\lib

call:compile adl_lib
call:compile ati_reg
call:compile command_line
call:compile custom_video
call:compile render_ddraw
call:compile render_d3d
call:compile render
call:compile display
call:compile edid
call:compile log_console
call:compile modeline
call:compile monitor
call:compile pstrip
call:compile util

del *.log
cd ..
echo Library built successfully!
goto:eof

:compile
echo Compiling %~1.bas
%PB_BINARY% /L /Q /I%INCLUDE_PATHS% %~1.bas
findstr /C:"Error" %~1.log
IF NOT ERRORLEVEL 1 (
  pause
  exit
)
goto:eof

