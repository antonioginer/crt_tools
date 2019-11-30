echo off

set RELEASE=".\release\"
set VMMAKER=".\vmmaker\"
set DEVUTIL=".\devutil\"
set VMMAKERINI=".\vmmaker\ini\"
set ARCADEOSD=".\arcade_osd\"
set DEVUTIL=".\devutil\"
set ZIP="%ProgramFiles%\7-Zip\"

FOR /F "tokens=1,* delims=*" %%i IN (version.txt) DO (
	set version=%%i
)
IF EXIST "%RELEASE%crt_tools_%version: =_%" rd /s /q %RELEASE%crt_tools_%version: =_%
md %RELEASE%crt_tools_%version: =_%
copy %ARCADEOSD%arcade_osd.exe "%RELEASE%crt_tools_%version: =_%\arcade_osd.exe"
copy %ARCADEOSD%d3dx9_43.dll "%RELEASE%crt_tools_%version: =_%\d3dx9_43.dll"
copy %VMMAKER%vmmaker.exe "%RELEASE%crt_tools_%version: =_%\vmmaker.exe"
copy %DEVUTIL%devutil32.exe %RELEASE%crt_tools_%version: =_%
copy %DEVUTIL%devutil64.exe %RELEASE%crt_tools_%version: =_%
copy %VMMAKERINI%vmm.ini %RELEASE%crt_tools_%version: =_%
copy %VMMAKERINI%monitor.ini %RELEASE%crt_tools_%version: =_%
copy %VMMAKERINI%user_modes.ini %RELEASE%crt_tools_%version: =_%
copy "%VMMAKERINI%user_modes - super.ini" %RELEASE%crt_tools_%version: =_%
copy %VMMAKERINI%mame_favourites.ini %RELEASE%crt_tools_%version: =_%
copy Readme.txt %RELEASE%crt_tools_%version: =_%
%ZIP%7z a -r -sfx7z.sfx %RELEASE%crt_tools_%version: =_%.exe %RELEASE%crt_tools_%version: =_%
pause

