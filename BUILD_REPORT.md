# Build Report

Date: 2026-07-13

## Environment

- Repository path: `/workspace/legendary-potato`
- Container OS: Ubuntu 24.04
- `dotnet` SDK: unavailable in this container (`dotnet: command not found`)
- Network/package install attempts were blocked by HTTP 403 responses from the configured proxy/repositories.

## What changed after user feedback

The previous command examples assumed the shell was already inside the repository. The README now explicitly instructs users to `cd` into the repository and provides `build.cmd` plus `scripts/build.ps1`, both of which resolve the repository root automatically before running `dotnet`.


## Follow-up after repeated PowerShell path errors

A dedicated `WINDOWS_BUILD_GUIDE.md` was added because the failures came from running commands in `C:\Users\12` and from typing the placeholder `C:\path\to\legendary-potato` literally. The guide explains that the repository must be downloaded or cloned first, then verifies the correct folder with `Get-ChildItem .\CornnerDesktopStudio.sln, .\build.cmd, .\src\CornnerDesktopStudio.App\CornnerDesktopStudio.App.csproj` before running `build.cmd`.

## Results in this container

- Restore: attempted, failed because .NET SDK is unavailable.
- Build: attempted, failed because .NET SDK is unavailable.
- Tests: attempted, failed because .NET SDK is unavailable.
- Publish: attempted, failed because .NET SDK is unavailable.
- EXE verification: not possible because publish could not be run without .NET SDK.

## Required command on Windows with .NET 8 SDK

From the repository root:

```powershell
.\build.cmd
```

Manual equivalent:

```powershell
cd C:\path\to\legendary-potato
dotnet restore .\CornnerDesktopStudio.sln
dotnet build .\CornnerDesktopStudio.sln -c Release
dotnet test .\CornnerDesktopStudio.sln -c Release
dotnet publish .\src\CornnerDesktopStudio.App\CornnerDesktopStudio.App.csproj -c Release -r win-x64 --self-contained true -o .\publish\win-x64
Test-Path .\publish\win-x64\CornnerDesktopStudio.exe
```
