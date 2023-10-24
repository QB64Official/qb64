@echo off
rem This script breaks when the version gets updated.
rem Can someone else work a way around that?
rem This script does not handle failure to make a directory
rem nor a failure to download the curl.cab
rem It also assumes that curl is downloaded to the users Desktop

set DLPAGE=http://skanthak.homepage.t-online.de/download
set CURLVERSION=curl-7.64.1.cab
set LINK=%DLPAGE%/%CURLVERSION%
rem grab the arch. We'll need this to extract files.
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set ARCH=i386|| set ARCH=amd64

rem Check if curl exists
curl --version 2>NUL 1>&2


if %ERRORLEVEL% == 9009 (
rem check if we have it already
    if exist internal\curl\curl.exe goto gotcurl
    mkdir internal\curl >NUL
    echo Fetching %LINK%
    explorer %LINK%
    rem we should wait until the file is downloaded, because explorer returns straight away
:keeptesting
    rem sleep 5 - we need to find something that'll work on XP, as timeout doesn't exist
    rem if not exist "%USERPROFILE%\Desktop\%CURLVERSION%" goto keeptesting
    "%SystemRoot%\system32\expand.exe" "%USERPROFILE%\Desktop\%CURLVERSION%" /F:%ARCH%\* internal\curl
:gotcurl
    rem Add to path
    PATH=%PATH%;%~dp0\internal\curl
) ELSE (
    echo "Found curl, continuing"
)
