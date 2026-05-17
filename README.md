# legendary-potato

## UltimateFPSBoost

This repository contains a cleaned PowerShell version of the UltimateFPSBoost helper at `scripts/UltimateFPSBoost.ps1`.

The script keeps local hardware detection, smarter discrete-GPU selection, broader shader-cache cleanup, backup/restore support, preview mode, local-only logging, and the Windows performance preset menu while intentionally omitting license checks, client-info collection, webhook logging, and outbound web calls.

> Warning: applying presets can change Windows registry values, power plans, service startup settings, temp files, and network settings. Review the script before running it, and only run it as Administrator if you trust the tweaks.

### Run

Open PowerShell on Windows from the repository root:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\UltimateFPSBoost.ps1
```

Preview a preset without writing changes:

```powershell
.\scripts\UltimateFPSBoost.ps1 -Preset UltimateX -Preview
```

Run a preset directly without the interactive menu:

```powershell
.\scripts\UltimateFPSBoost.ps1 -Preset Balanced
```

Restore the last backup captured before applying tweaks:

```powershell
.\scripts\UltimateFPSBoost.ps1 -Preset Restore
```

### Presets

- **Balanced Preset**: disables Game Bar capture, keeps Game Mode enabled, enables Ultimate Performance, and clears supported GPU plus common DirectX shader caches with Windows/tool availability checks.
- **Competitive Preset**: adds background app and TCP tuning.
- **Max FPS Preset**: adds SysMain disablement and user/system temp cleanup.
- **Ultimate X Mode**: adds low-latency multimedia, advanced TCP, and Nagle-related registry tweaks while skipping system-level changes when Administrator rights are unavailable.

### Safety features

- **Preview mode**: `-Preview` shows intended writes and cache/temp cleanup without changing registry, services, power plans, network settings, or files.
- **Local backup**: presets save the last registry/service/power/network backup under `%LOCALAPPDATA%\UltimateFPSBoost\backups\last-backup.json` by default.
- **Local log**: each run writes a local log under `%LOCALAPPDATA%\UltimateFPSBoost\logs` by default.
- **No outbound calls**: the script does not perform telemetry, webhooks, downloads, or web API calls.
