# legendary-potato

This repository contains the `PLXULTIMATEX` PowerShell script.

## ULTIMATEXPLUS Performance Engine

`PLXULTIMATEX.ps1` version 1.1.14 is a Windows PowerShell 5.1 script that presents the original single Core Mode menu for applying the ULTIMATEXPLUS performance preset with clearer status output and safer step-by-step reporting.

### What the script does

The preset includes the following optimization actions:

- Verifies the script is running with Administrator privileges.
- Attempts to create a Windows System Restore checkpoint before applying system-level changes.
- Detects CPU and GPU information through CIM/WMI and displays a client/hardware profile.
- Disables Game DVR capture and background app access.
- Applies system responsiveness and power-plan tuning for lower latency.
- Applies PriorityControl, fullscreen optimization, multimedia scheduler, and mouse input registry settings.
- Removes the `useplatformclock` BCDEdit value.
- Applies GPU TDR registry values.
- Clears NVIDIA or AMD shader cache folders when the matching GPU type is detected.
- Sets TCP autotuning to `high`.
- Saves registry key backups under `ProgramData\ULTIMATEXPLUS\Backups\<run-id>` before writing supported registry values.
- Writes a per-run transcript log under `ProgramData\ULTIMATEXPLUS\Logs\<run-id>.log` when transcript capture is available.
- Writes a per-run JSON manifest under `ProgramData\ULTIMATEXPLUS\Reports\<run-id>.json` with step results and timing details.
- Reports per-step success/warning counts without adding extra modes.

> [!IMPORTANT]
> This script changes Windows registry values and boot configuration settings. Review the script before running it and run it only on systems where you understand and accept those changes.

### Usage

1. Open PowerShell as Administrator.
2. Run the script:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\PLXULTIMATEX.ps1
```

3. Choose `1` to activate ULTIMATEXPLUS Core Mode or `X` to exit.
4. Note any restore-point warning plus the backup folder, run-log path, and manifest path printed in the summary if you need to review or restore changes.
5. Reboot Windows after applying the preset.

### Version history

- `1.1.14`: Adds timed step summaries and a JSON run manifest for audit/review after applying the preset.
- `1.1.13`: Tracks detailed per-step status metadata for clearer troubleshooting.
- `1.1.12`: Improves summary output with manifest, backup, and transcript paths.
- `1.1.11`: Strengthens run reporting for restore-checkpoint and backup review.
- `1.1.10`: Adds elapsed-time reporting for each optimization step.
- `1.1.9`: Adds a pre-optimization System Restore checkpoint attempt for safer rollback planning.
- `1.1.8`: Adds system responsiveness tuning, high-performance power-plan activation, and expanded MMCSS game task priorities.
- `1.1.7`: Adds per-run transcript logging while keeping the original single Core Mode workflow.
- `1.1.6`: Adds safer step reporting, registry backups, command validation, and completion fallback handling.
