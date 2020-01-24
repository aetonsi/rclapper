@echo off
powershell "$datetime=Get-Date -format 'yyyy-MM-dd,HH.mm.ss';write-host $datetime"