@rem This batch script has been updated to download and get the latest copy of mingw binaries from:
@rem https://github.com/niXman/mingw-builds-binaries/releases
@rem So the filenames in 'url' variable should be updated to the latest stable builds as and when they are available
@rem
@rem This also grabs a copy of 7-Zip command line extraction utility from https://www.7-zip.org/a/7zr.exe
@rem to extact the 7z mingw binary archive
@rem
@rem Both files are downloaded using 'curl'. Once downloaded, the archive is extracted to the correct location
@rem and then both the archive and 7zr.exe are deleted
@rem
@rem Copyright (c) 2022, Samuel Gomes
@rem https://github.com/a740g
@rem
@echo off

rem Enable cmd extensions and exit if not present
setlocal enableextensions
if errorlevel 1 (
    echo Error: Command Prompt extensions not available!
    goto end
)

echo QB64 Setup
echo.

rem Change to the correct drive letter
%~d0

rem Change to the correct path
cd %~dp0

del /q /s internal\c\libqb\*.o >nul 2>nul
del /q /s internal\c\libqb\*.a >nul 2>nul
del /q /s internal\c\parts\*.o >nul 2>nul
del /q /s internal\c\parts\*.a >nul 2>nul
del /q /s internal\temp\*.* >nul 2>nul

rem Check if the C++ compiler is there and skip downloading if it exists
if exist internal\c\c_compiler\bin\c++.exe goto skipccompsetup

rem Create the c_compiler directory that should contain the MINGW binaries
mkdir internal\c\c_compiler

rem Check the processor type and then set the MINGW variable to correct MINGW filename

rem reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set MINGW=mingw32 || set MINGW=mingw64
rem 
rem rem Set the correct file to download based on processor type
rem if "%MINGW%"=="mingw64" (
rem 	set url="https://github.com/niXman/mingw-builds-binaries/releases/download/12.2.0-rt_v10-rev0/x86_64-12.2.0-release-win32-seh-rt_v10-rev0.7z"
rem ) else (
rem 	set url="https://github.com/niXman/mingw-builds-binaries/releases/download/12.2.0-rt_v10-rev0/i686-12.2.0-release-win32-sjlj-rt_v10-rev0.7z"
rem )

reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && goto chose32 || goto choose

:choose
if not exist %SystemRoot%\system32\choice.exe (
    set /p errorlevel="Install (1) 64-bit or (2) 32-bit MINGW? "
) else (
    choice /c 12 /M "Install (1) 64-bit or (2) 32-bit MINGW? "
)
if errorlevel 1 goto chose64
goto chose32

:chose32
set url="https://github.com/niXman/mingw-builds-binaries/releases/download/12.2.0-rt_v10-rev0/i686-12.2.0-release-win32-sjlj-rt_v10-rev0.7z"
set MINGW=mingw32
goto chosen

:chose64
set url="https://github.com/niXman/mingw-builds-binaries/releases/download/12.2.0-rt_v10-rev0/x86_64-12.2.0-release-win32-seh-rt_v10-rev0.7z"
set MINGW=mingw64
goto chosen

:chosen

echo Downloading %url%...
curl -L %url% -o temp.7z

echo Testing for 7zip
7z >NUL 2>&1

if ERRORLEVEL 9009 (

    echo Downloading 7zr.exe...
	rem Check for XP (either 32-bit or 64-bit)
	ver | findstr /R /C:"Version 5.[12]"
	if errorlevel 0 (
        curl -Lk https://www.7-zip.org/a/7zr.exe -o 7zr.exe
    ) else (
        curl -L https://www.7-zip.org/a/7zr.exe -o 7zr.exe
	)

    echo Extracting C++ Compiler...
    7zr.exe x temp.7z -y
) else (
    echo Extracting C++ Compiler...
    7z x temp.7z -y
)

echo Moving C++ compiler...
for /f %%a in ('dir %MINGW% /b') do move /y "%MINGW%\%%a" internal\c\c_compiler\

echo Cleaning up..
rd %MINGW%
if exist 7zr.exe del 7zr.exe

del temp.7z

:skipccompsetup

echo Building library 'LibQB'
cd internal/c/libqb/os/win
if exist libqb_setup.o del libqb_setup.o
call setup_build.bat
cd ../../../../..

echo Building library 'FreeType'
cd internal/c/parts/video/font/ttf/os/win
if exist src.o del src.o
call setup_build.bat
cd ../../../../../../../..

echo Building library 'Core:FreeGLUT'
cd internal/c/parts/core/os/win
if exist src.a del src.a
call setup_build.bat
cd ../../../../../..

echo Building 'QB64'
copy internal\source\*.* internal\temp\ >nul
copy source\qb64.ico internal\temp\ >nul
copy source\icon.rc internal\temp\ >nul
cd internal\c
c_compiler\bin\windres.exe -i ..\temp\icon.rc -o ..\temp\icon.o
c_compiler\bin\g++ -mconsole -s -Wfatal-errors -w -Wall qbx.cpp libqb\os\win\libqb_setup.o ..\temp\icon.o -D DEPENDENCY_LOADFONT  parts\video\font\ttf\os\win\src.o -D DEPENDENCY_SOCKETS -D DEPENDENCY_NO_PRINTER -D DEPENDENCY_ICON -D DEPENDENCY_NO_SCREENIMAGE parts\core\os\win\src.a -lopengl32 -lglu32   -mwindows -static-libgcc -static-libstdc++ -D GLEW_STATIC -D FREEGLUT_STATIC     -lws2_32 -lwinmm -lgdi32 -o "..\..\qb64.exe"
cd ..\..

echo.
echo Launching 'QB64'
qb64

echo.
pause

:end
endlocal
