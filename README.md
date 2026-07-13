# Cornner Desktop Studio

Cornner Desktop Studio is a safe .NET 8 WPF desktop control center for Windows. It is designed around MVVM, dependency injection, structured results, preview-before-apply workflows, local-only logging, and non-destructive Windows integration.

> **Important:** run commands from this repository folder, not from `C:\Users\<you>` or another directory. In PowerShell, first run `cd <path-to-this-repository>` or use `build.cmd`, which automatically changes to the repository root.

## Features

- Single-window modern WPF shell with side navigation.
- Dashboard, Desktop Profiles, Wallpaper, Widgets, App Dock, Window Layouts, Desktop Organizer, Taskbar, Startup, Backup & Restore, Activity Log, and Settings sections.
- Midnight-first theme resources with dark readable cards and cyan accent.
- Thai and English localization service.
- Default profiles: Gaming, Clean, Work, Streaming, and Custom.
- Preview, validate, apply, verify, backup, restore, partial success, and unsupported result states.
- Safe infrastructure services for app data folders, shortcut validation, wallpaper format validation, Windows capability checks, and window layout bounds validation.

## System Requirements

- Windows 10/11 for WPF runtime usage.
- .NET 8 SDK to build from source.
- No administrator permission is required for normal startup.




## If you cannot build locally

Use GitHub Actions instead of building on your own PC:

1. Open the repository page on GitHub.
2. Go to **Actions**.
3. Run **Build Cornner Desktop Studio Windows EXE**.
4. Download the `CornnerDesktopStudio-win-x64` artifact after the workflow finishes.
5. Open `CornnerDesktopStudio.exe` from the downloaded artifact folder.

The workflow builds on `windows-latest`, runs restore/build/test/publish, verifies that `CornnerDesktopStudio.exe` exists, and uploads the whole `publish/win-x64` folder.

## Easiest option / วิธีง่ายที่สุด

If you are not comfortable with PowerShell commands, open the downloaded/extracted project folder and double-click `START_HERE.cmd`. A Thai step-by-step guide is available in [`START_HERE_TH.md`](START_HERE_TH.md).

## If PowerShell says the project or build script is missing

You are not in the repository folder yet. `C:\path\to\legendary-potato` in examples is a placeholder, not a real path to type literally. See [`WINDOWS_BUILD_GUIDE.md`](WINDOWS_BUILD_GUIDE.md) for step-by-step download, folder verification, build, publish, and EXE launch instructions.

## Quick Build on Windows

From the repository root:

```powershell
.\build.cmd
```

Or from any directory, pass the full path to the script:

```powershell
C:\path\to\legendary-potato\build.cmd
```

The script runs restore, build, test, publish, and verifies `publish\win-x64\CornnerDesktopStudio.exe`.

## Manual Build

```powershell
cd C:\path\to\legendary-potato
dotnet restore .\CornnerDesktopStudio.sln
dotnet build .\CornnerDesktopStudio.sln -c Release
```

## Run

```powershell
dotnet run --project .\src\CornnerDesktopStudio.App\CornnerDesktopStudio.App.csproj
```

## Test

```powershell
dotnet test .\CornnerDesktopStudio.sln -c Release
```

## Publish

```powershell
dotnet publish .\src\CornnerDesktopStudio.App\CornnerDesktopStudio.App.csproj -c Release -r win-x64 --self-contained true -o .\publish\win-x64
```

Expected executable path:

```text
publish\win-x64\CornnerDesktopStudio.exe
```

## Data Folder

Runtime data is stored under:

```text
%LOCALAPPDATA%\CornnerDesktopStudio\
```

Required subfolders are `Config`, `Profiles`, `Backups`, `Logs`, `Cache`, `Wallpapers`, and `Exports`.

## Safety Model

The app does not patch Explorer, replace the shell, inject DLLs, disable Defender, store credentials, create drivers, create kernel services, hide processes, or send telemetry. System changes must go through preview and backup-aware apply workflows.

## Known Limitations

This repository currently contains a safe MVP scaffold. Advanced live wallpaper embedding, full widget overlay windows, real taskbar mutation, and real window repositioning require Windows runtime validation and are intentionally constrained behind safe services.
