@echo off & setlocal & setlocal enabledelayedexpansion & pushd "%~dp0" & set "__FILE__=%~f0" & set "__FILE__BASENAME__=%~nx0"
call :fn_title

rem ====== setup
chcp 65001 >nul
set "CONFIG_RCLONE=config\rclone.config.ini"
set "CONFIG_JOBS=config\jobs.txt"
set "CONFIG_REMOTES=config\remotes.txt"
set "CONFIG_SWITCHES=config\switches.txt"
set "CONFIG_EXCLUDE=config\exclude.txt"
set "CONFIG_MINUTES=60"
set "PASSWORD_COMMAND="

set "TOOL_TEE=tee"
set "TOOL_RCLONE=call rclone.exe"
set "TOOL_WAIT=call tools\wait"
set "TOOL_GETDATETIME=call tools\getDateTime"

FOR /F "tokens=* USEBACKQ" %%F IN (`"%TOOL_GETDATETIME%"`) DO SET "DT=%%~F"
set "LOG_FILE="logs\log_%DT%.log""



rem ====== args parsing
:parseArgs
if "%~1" EQU "--help" (
	call:fn_help
	goto :ending
)
if "%~1" EQU "--teeing" (
	set TEEING=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--nolog" (
	set NOLOG=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--config-rclone" (
	set "CONFIG_RCLONE=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--config-jobs" (
	set "CONFIG_JOBS=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--config-remotes" (
	set "CONFIG_REMOTES=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--config-switches" (
	set "CONFIG_SWITCHES=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--config-exclude" (
	set "CONFIG_EXCLUDE=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--config-minutes" (
	set "CONFIG_MINUTES=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--password-command" (
	set "PASSWORD_COMMAND=%~2"
	shift
	shift
	goto :parseArgs
)


if not exist "%CONFIG_RCLONE%" echo.>"%CONFIG_RCLONE%"
if not exist "%CONFIG_JOBS%" echo.>"%CONFIG_JOBS%"
if not exist "%CONFIG_REMOTES%" echo.>"%CONFIG_REMOTES%"
if not exist "%CONFIG_SWITCHES%" (
	if exist "%CONFIG_SWITCHES%.sample" (
		type "%CONFIG_SWITCHES%.sample">"%CONFIG_SWITCHES%"
	) ELSE (
		echo.>"%CONFIG_SWITCHES%"
	)
)
if not exist "%CONFIG_EXCLUDE%" (
	if exist "%CONFIG_EXCLUDE%.sample" (
		type "%CONFIG_EXCLUDE%.sample">"%CONFIG_EXCLUDE%"
	) ELSE (
		echo.>"%CONFIG_EXCLUDE%"
	)
)

echo Parsed args:
echo CONFIG_RCLONE    = %CONFIG_RCLONE%
echo CONFIG_JOBS      = %CONFIG_JOBS%
echo CONFIG_REMOTES   = %CONFIG_REMOTES%
echo CONFIG_SWITCHES  = %CONFIG_SWITCHES%
echo CONFIG_EXCLUDE   = %CONFIG_EXCLUDE%
echo CONFIG_MINUTES   = %CONFIG_MINUTES%
echo PASSWORD_COMMAND = %PASSWORD_COMMAND%


rem ====== main function
if not defined NOLOG (
	if not defined TEEING (
		where /q tee
		IF ERRORLEVEL 1 (
			set NOTEE=1
		)
		if defined NOTEE (
			if exist tools\tee* (
				set TOOL_TEE=tools\tee
				set NOTEE=
			)
		)
		if defined NOTEE (
			echo TEE NOT FOUND, NO LOGGING
			echo.
		) ELSE (
			echo logging to !LOG_FILE!...
			echo.
			call "!__FILE__!" --teeing %* 2>&1 | !TOOL_TEE! --append !LOG_FILE!
			goto :ending
		)
	)
)

for /F "usebackq tokens=*" %%A in ("%CONFIG_SWITCHES%") do set "SWITCHES=!SWITCHES! %%A"
for /F "usebackq tokens=*" %%A in ("%CONFIG_EXCLUDE%") do set "SWITCHES_EXCLUDE=!SWITCHES_EXCLUDE! %%A"

if defined PASSWORD_COMMAND (
	FOR /F "tokens=* USEBACKQ" %%F IN (`%PASSWORD_COMMAND%`) DO SET "RCLONE_CONFIG_PASS=%%F"
)

:redo
call :fn_title
echo ====================================
echo (re) STARTED @ %DT%
echo ====================================
echo.
echo.
echo Starting in 10 seconds...
timeout /t 10
echo.

for /F "delims=| tokens=1,2,3,4 usebackq" %%A in ("%CONFIG_JOBS%") do (
	for /F "tokens=* usebackq" %%R in ("%CONFIG_REMOTES%") do (
		rem %%A=local dir
		rem %%C=remote prefix [optional]
		rem %%R=remote name
		rem %%D=remote suffix [optional]
		rem %%B=remote dir

		echo.&echo.&echo.&echo.

		set "cmd1=!TOOL_RCLONE! --config=%CONFIG_RCLONE% dedupe --dedupe-mode rename --by-hash %%~C%%~R%%~D:%%B"
		set "cmd2=!TOOL_RCLONE! --config=%CONFIG_RCLONE% dedupe --dedupe-mode rename %%~C%%~R%%~D:%%B"
		set "cmd3=!TOOL_RCLONE! --config=%CONFIG_RCLONE% sync !SWITCHES_EXCLUDE! !SWITCHES! %%A %%~C%%~R%%~D:%%B"

		echo ====================================
		echo !cmd1!
		echo ====================================
		!cmd1!
		echo ====================================
		echo !cmd2!
		echo ====================================
		!cmd2!
		echo ====================================
		echo !cmd3!
		echo ====================================
		!cmd3!

		echo.&echo.&echo.&echo.
	)
)


%TOOL_WAIT% --allowbreak %CONFIG_MINUTES%
echo.

goto:redo


rem ====== ending (should never be reached since the main function loops)
:ending
SET "RCLONE_CONFIG_PASS="
popd
pause
exit /b %errorlevel%



:fn_help
	echo. !__FILE__BASENAME__!
	echo.
	echo. === DESCRIPTION ===
	echo. rclone wrapper for continuous syncing to multiple remotes.
	echo. supports multiple sync jobs.
	echo. supports conditionally using crypt/alternative remotes by prefixing/suffixing the remote name (eg. if you have both a "mega" and a "mega_crypt" remotes you can choose to sync to any of the two by suffixing with "_crypt").
	echo. supports logging with tee (not included), if it's present in the system's PATH, current directory or ./tools/ directory.
	echo.
	echo. === POSSIBLE ARGS ===
	echo. --nolog = disables logging to ./logs/ folder
	echo. --config-rclone ^<path^> = sets config file path; this is the file which is generated and manipulated via `rclone config`; defaults to "config\jobs.txt"
	echo. --config-jobs ^<path^> = sets CONFIG_JOBS=^<path^>; this is the file containing the list of jobs to be run against all remotes; defaults to "config\jobs.txt"
	echo.       CONFIG_JOBS structure: for each line, ^<SOURCE^>^|^<DEST^>[^|^<REMOTE PREFIX^>][^|^<REMOTE SUFFIX^>]
	echo.       example: this will sync c:\documents to all of my ^<remote^>/documents, then it will sync c:\secret_documents to all of my crypt_^<remote^>/secret_documents.
	echo.           c:\documents^|/documents
	echo.           c:\secret_documents^|/secret_documents^|crypt_
	echo. --config-remotes ^<path^> = sets CONFIG_REMOTES=^<path^>; this is the file containing the list of the remotes against which to run jobs; defaults to "config\remotes.txt"
	echo.       CONFIG_REMOTES structure: 1 remote per line
	echo.       example: this will run each sync job (from CONFIG_JOBS) to my "googledrive", "dropbox" AND "mega" remotes.
	echo.           googledrive
	echo.           dropbox
	echo.           mega
	echo. --config-switches ^<path^> = sets CONFIG_SWITCHES=^<path^>; this file contains multiple rows with switches for the rclone sync command; defaults to "config\switches.txt"
	echo. --config-exclude ^<path^> = sets CONFIG_EXCLUDE=^<path^>; this file contains multiple rows with "--exclude" (or similar) switches for the rclone sync command; defaults to "config\exclude.txt"
	echo. --config-minutes ^<path^> = sets CONFIG_MINUTES=^<number^>; number of minutes to wait between each loop; defaults to 60.
	echo. --password-command ^<path or command^> = command or file to execute to retrieve the password of the rclone config.ini file. Will be run just once, at the beginning of execution; the command must output the password; do not pass this argument for unencrypted rclone config files.
	echo.
goto:eof

:fn_title
	title %__FILE__BASENAME__%
	title %__FILE__BASENAME__% %* 2>nul
goto:eof