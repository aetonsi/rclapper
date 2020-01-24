@echo off & setlocal & setlocal enabledelayedexpansion

rem ====== setup
if not exist %windir%\System32\timeout.exe (
	echo Dependency not met: timeout.exe not found
	exit /b 1
)
set BREAK=/NOBREAK

rem ====== parsing args
:parseArgs
if "%~1" EQU "--help" (
	title %~nx0 %*
	call:fn_help
	exit /b 0
)
if "%~1" EQU "--notitle" (
	set NOTITLE=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--noecho" (
	set NOECHO=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--skipfirst" (
	set SKIPFIRST=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--allowbreak" (
	set BREAK=
	shift
	goto :parseArgs
)

rem ====== main function
set minutes=%~1
if not defined minutes (
	echo %%1: argument not valid
	call:fn_help
	exit /b 1
)
set /a minutes=minutes*1

FOR /L %%i IN (1,1,!minutes!) DO (
	if not defined SKIPFIRST (
		if not defined NOTITLE title Waiting !minutes! minutes...
		if not defined NOECHO echo Waiting !minutes! minutes...
	) ELSE (
		set "SKIPFIRST="
	)
	timeout /t 60 !BREAK!>nul
	set /a minutes=minutes-1
)

exit /b 0

rem ====== functions

:fn_help
	echo %~nx0
	echo DESCRIPTION:
	echo waits X minutes, echoing and changing the console title every single minute.
	echo depends on timeout.exe.
	echo.
	echo ARGS INFO:
	echo [--help]: this info
	echo [--notitle]: doesn't change the console title
	echo [--noecho]: doesn't echo to stdout
	echo [--skipfirst]: skips the first echo and title
	echo [--allowbreak]: allows breaking the single minutes wait by pressing any key (removes timeout.exe /NOBREAK argument)
	echo %%1: minutes to wait
goto:eof