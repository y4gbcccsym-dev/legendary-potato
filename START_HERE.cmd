@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Cornner Desktop Studio - Build Helper

echo.
echo ============================================================
echo  Cornner Desktop Studio - One Click Build Helper
echo ============================================================
echo.
echo This file must be inside the project folder next to:
echo   CornnerDesktopStudio.sln
echo   build.cmd
echo.

if not exist "%~dp0CornnerDesktopStudio.sln" (
  echo ERROR: CornnerDesktopStudio.sln was not found next to START_HERE.cmd.
  echo You are not running this from the extracted/cloned repository folder.
  echo.
  echo Please download or extract the repository first, then double-click START_HERE.cmd
  echo from the folder that contains CornnerDesktopStudio.sln.
  echo.
  pause
  exit /b 1
)

where dotnet >nul 2>nul
if errorlevel 1 (
  echo ERROR: .NET 8 SDK was not found.
  echo.
  echo Install the .NET 8 SDK from Microsoft, reopen this folder,
  echo then double-click START_HERE.cmd again.
  echo.
  echo Download page:
  echo   https://dotnet.microsoft.com/download/dotnet/8.0
  echo.
  pause
  exit /b 1
)

echo Found project folder:
echo   %~dp0
echo.
echo Found dotnet:
dotnet --version

echo.
echo Starting restore, build, test, publish...
echo.
call "%~dp0build.cmd"
if errorlevel 1 (
  echo.
  echo Build failed. Read the error above.
  echo.
  pause
  exit /b 1
)

echo.
echo Build completed successfully.
echo EXE path:
echo   %~dp0publish\win-x64\CornnerDesktopStudio.exe
echo.
if exist "%~dp0publish\win-x64\CornnerDesktopStudio.exe" (
  echo Opening publish folder...
  explorer "%~dp0publish\win-x64"
)
pause
