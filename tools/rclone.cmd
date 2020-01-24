@echo off
setlocal
pushd "%~dp0"

set "RCLONE_BIN=call rclone.exe"
set "RCLONE_CONFIG=rclone.config.ini"


if not exist %RCLONE_CONFIG% echo.>%RCLONE_CONFIG%
%RCLONE_BIN% --config=%RCLONE_CONFIG% %*


popd
exit /b %ERRORLEVEL%