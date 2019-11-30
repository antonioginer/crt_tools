@echo off
rem call build-lib.bat
set PB_BINARY="%ProgramFiles(x86)%\PBWin10\bin\PBWin.exe"
set INCLUDE_PATHS=..\lib;"%ProgramFiles(x86)%\PBWin10\Roca"

FOR /F "tokens=1,* delims=*" %%i IN (version.txt) DO (set version=%%i)

cd arcade_osd
echo $app_version = "%version%" >version.inc
call:compile arcade_osd

del *.log
echo Build finished successfully!
arcade_osd.exe
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

