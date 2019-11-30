@echo off
rem call build-lib.bat
set PB_BINARY="%ProgramFiles(x86)%\PBWin10\bin\PBWin.exe"
set INCLUDE_PATHS=..\lib;"%ProgramFiles(x86)%\PBWin10\Roca"

FOR /F "tokens=1,* delims=*" %%i IN (version.txt) DO (set version=%%i)

cd vmmaker
echo $app_version = "%version%" >version.inc

call:compile ati_inf
call:compile command_vmm
call:compile gui
call:compile gui_settings
call:compile mame
call:compile mode_db
call:compile user
call:compile options
call:compile timing_chart
call:compile vmmaker

del *.log
echo Build finished successfully!
vmmaker.exe
exit

:compile
echo Compiling %~1.bas
%PB_BINARY% /L /Q /I%INCLUDE_PATHS% %~1.bas
findstr /C:"Error" %~1.log
IF NOT ERRORLEVEL 1 (
  pause
  exit
)
goto:eof

