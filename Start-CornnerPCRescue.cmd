@echo off
setlocal
set "ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%Start-CornnerPCRescue.ps1" %*
exit /b %ERRORLEVEL%
