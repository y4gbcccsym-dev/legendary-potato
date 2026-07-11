@echo off
setlocal
set "ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%Install-CornnerPCRescue.ps1" %*
exit /b %ERRORLEVEL%
