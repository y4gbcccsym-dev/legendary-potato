# CornnerPCRescue

CornnerPCRescue is a WPF + .NET 8 Windows desktop utility for safe PC health checks, Windows maintenance previews, FiveM/GTA V profile review, network diagnostics, backup/restore manifests, and local reports.

The app is intentionally conservative:

- Preview Mode is the default.
- Real Apply requires an explicit mode change and a backup-first workflow.
- It does not disable Defender or Windows Update.
- It does not delete Prefetch.
- It does not apply risky BCD, HPET, xAPIC, process mitigation, or realtime-priority tweaks.
- It does not include KeyAuth, HWID locking, telemetry, webhooks, or external script downloads.

## Build and run

Open PowerShell in the repository root first. If your prompt shows a folder such as `C:\Users\12>`, change directory to the real folder that contains `CornnerPCRescue.sln` before running dotnet commands.

> Do not copy `C:\path\to\legendary-potato` literally. It is a placeholder. Replace it with the actual folder where you downloaded or cloned this repository.

If you do not know where the repository is, search for the solution file first:

```powershell
Get-ChildItem -Path $env:USERPROFILE -Filter CornnerPCRescue.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5 FullName
```

Then change directory to the folder printed above, for example:

```powershell
cd C:\Users\12\Downloads\legendary-potato
dotnet restore .\CornnerPCRescue.sln
dotnet build .\CornnerPCRescue.sln -c Release
dotnet test .\CornnerPCRescue.sln -c Release
dotnet run --project .\src\CornnerPCRescue\CornnerPCRescue.csproj
```

Or use a launcher from the repository root:

```powershell
.\Start-CornnerPCRescue.ps1
```

Double-click users can run:

```text
Start-CornnerPCRescue.cmd
```

## Install to Desktop on Windows

From the repository root, run:

```powershell
.\Install-CornnerPCRescue.ps1
```

Double-click users can run:

```text
Install-CornnerPCRescue.cmd
```

The installer publishes the app to `artifacts\CornnerPCRescue`, creates `CornnerPCRescue.lnk` on your Desktop, and launches the app automatically. Use `-NoLaunch` if you only want to install the shortcut.

The Release executable is produced at:

```text
src\CornnerPCRescue\bin\Release\net8.0-windows\CornnerPCRescue.exe
```

## Legacy script

The cleaned legacy PowerShell helper remains at `scripts/UltimateFPSBoost.ps1` for reference and manual use.
