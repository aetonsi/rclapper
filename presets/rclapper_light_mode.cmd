@echo off
pushd "%~dp0"

call ..\rclapper --config-switches="%CD%\..\config\switches_light.txt"

popd