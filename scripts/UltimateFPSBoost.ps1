# FiveM Competitive PvP Optimizer
# Safe Windows-side optimization for FiveM PvP. No cheats, macros, memory edits,
# anti-cheat bypasses, exploit tweaks, or game file modifications.

[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Restore,
    [switch]$ClearFiveMCache,
    [switch]$ClearNvidiaShaderCache,
    [switch]$Status,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:BackupDir = Join-Path $Script:BaseDir 'backups'
$Script:LogDir = Join-Path $Script:BaseDir 'logs'
$Script:RestoreFile = Join-Path $Script:BackupDir 'restore-state.json'
$Script:LogFile = Join-Path $Script:LogDir ("optimizer-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$Script:RunStamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Initialize-Workspace {
    foreach ($path in @($Script:BackupDir, $Script:LogDir)) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')]
        [string]$Level = 'INFO'
    )

    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    $color = switch ($Level) {
        'OK' { 'Green' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color
    Add-Content -LiteralPath $Script:LogFile -Value $line -Encoding UTF8
}

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Please run PowerShell as Administrator.'
    }
}

function ConvertTo-RegExePath {
    param([Parameter(Mandatory)][string]$RegistryPath)

    if ($RegistryPath -like 'HKCU:\*') {
        return $RegistryPath -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
    }
    if ($RegistryPath -like 'HKLM:\*') {
        return $RegistryPath -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\'
    }
    throw "Unsupported registry hive: $RegistryPath"
}

function Load-RestoreState {
    if (-not (Test-Path -LiteralPath $Script:RestoreFile)) {
        return [ordered]@{
            Version = 1
            CreatedAt = (Get-Date).ToString('o')
            Registry = @()
            PowerPlan = $null
            Notes = @()
        }
    }

    $json = Get-Content -LiteralPath $Script:RestoreFile -Raw -Encoding UTF8
    $state = $json | ConvertFrom-Json
    return [ordered]@{
        Version = $state.Version
        CreatedAt = $state.CreatedAt
        Registry = @($state.Registry)
        PowerPlan = $state.PowerPlan
        Notes = @($state.Notes)
    }
}

function Save-RestoreState {
    param([Parameter(Mandatory)]$State)

    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Script:RestoreFile -Encoding UTF8
}

function Get-RegistryValueSnapshot {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    $exists = Test-Path -LiteralPath $Path
    $valueExists = $false
    $value = $null
    $kind = 'DWord'

    if ($exists) {
        try {
            $item = Get-Item -LiteralPath $Path
            $valueNames = @($item.GetValueNames())
            $valueExists = $valueNames -contains $Name
            if ($valueExists) {
                $value = $item.GetValue($Name)
                $kind = $item.GetValueKind($Name).ToString()
            }
        }
        catch {
            Write-Log "Unable to read registry value $Path\$Name : $($_.Exception.Message)" 'WARN'
        }
    }

    [ordered]@{
        Path = $Path
        Name = $Name
        PathExisted = $exists
        ValueExisted = $valueExists
        Value = $value
        Kind = $kind
    }
}

function Backup-RegistryKey {
    param([Parameter(Mandatory)][string]$Path)

    $safeName = ($Path -replace '[:\\/\s]+', '_').Trim('_')
    $target = Join-Path $Script:BackupDir ("{0}-{1}.reg" -f $Script:RunStamp, $safeName)
    $regPath = ConvertTo-RegExePath -RegistryPath $Path
    $result = & reg.exe export $regPath $target /y 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Registry backup exported: $target" 'OK'
    }
    else {
        Write-Log "Registry export skipped/failed for $regPath : $result" 'WARN'
    }
}

function Set-SafeRegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('DWord', 'String')]
        [string]$Type = 'DWord',
        [Parameter(Mandatory)]$State
    )

    Backup-RegistryKey -Path $Path
    $snapshot = Get-RegistryValueSnapshot -Path $Path -Name $Name
    $alreadySaved = @($State.Registry | Where-Object { $_.Path -eq $Path -and $_.Name -eq $Name }).Count -gt 0
    if (-not $alreadySaved) {
        $State.Registry += [pscustomobject]$snapshot
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Write-Log "Set registry $Path\$Name = $Value ($Type)" 'OK'
}

function Restore-RegistryValues {
    param([Parameter(Mandatory)]$State)

    foreach ($entry in @($State.Registry)) {
        try {
            if (-not $entry.PathExisted) {
                if (Test-Path -LiteralPath $entry.Path) {
                    Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                    $item = Get-Item -LiteralPath $entry.Path -ErrorAction SilentlyContinue
                    if ($item -and @($item.GetValueNames()).Count -eq 0 -and @($item.GetSubKeyNames()).Count -eq 0) {
                        Remove-Item -LiteralPath $entry.Path -Force
                        Write-Log "Removed empty registry key created by optimizer: $($entry.Path)" 'OK'
                    }
                    else {
                        Write-Log "Removed registry value created by optimizer: $($entry.Path)\$($entry.Name)" 'OK'
                    }
                }
                continue
            }

            if (-not (Test-Path -LiteralPath $entry.Path)) {
                New-Item -Path $entry.Path -Force | Out-Null
            }

            if ($entry.ValueExisted) {
                New-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -PropertyType $entry.Kind -Force | Out-Null
                Write-Log "Restored registry $($entry.Path)\$($entry.Name)" 'OK'
            }
            else {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                Write-Log "Removed registry value created by optimizer: $($entry.Path)\$($entry.Name)" 'OK'
            }
        }
        catch {
            Write-Log "Restore failed for $($entry.Path)\$($entry.Name): $($_.Exception.Message)" 'ERROR'
        }
    }
}

function Disable-BackgroundCapture {
    param([Parameter(Mandatory)]$State)

    Write-Log 'Disabling Xbox/Game DVR capture features that can add overhead.' 'INFO'
    Set-SafeRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Type DWord -State $State
    Set-SafeRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Type DWord -State $State
    Set-SafeRegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1 -Type DWord -State $State
    Set-SafeRegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -Type DWord -State $State
}

function Set-NagleForActiveAdapters {
    param([Parameter(Mandatory)]$State)

    $activeAdapters = Get-NetAdapter -Physical -ErrorAction Stop |
        Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -eq $true }

    if (-not $activeAdapters) {
        Write-Log 'No active physical network adapter found. Skipping Nagle registry tuning.' 'WARN'
        return
    }

    $interfacesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
    $ipConfigs = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4Address }

    foreach ($config in $ipConfigs) {
        $adapter = $activeAdapters | Where-Object { $_.InterfaceIndex -eq $config.InterfaceIndex } | Select-Object -First 1
        if (-not $adapter) {
            continue
        }
        $rawGuid = [string]((Get-NetAdapter -InterfaceIndex $adapter.InterfaceIndex).InterfaceGuid)
        $adapterGuid = $rawGuid.Trim('{}')
        $pathCandidates = @(
            (Join-Path $interfacesRoot "{$adapterGuid}"),
            (Join-Path $interfacesRoot $adapterGuid)
        )
        $path = $pathCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $path) {
            Write-Log "TCP interface registry key not found for adapter: $($adapter.Name). Skipping Nagle tuning." 'WARN'
            continue
        }
        Write-Log "Applying low-latency TCP ACK settings to active adapter: $($adapter.Name) ($($config.IPv4Address.IPAddress))" 'INFO'
        Set-SafeRegistryValue -Path $path -Name 'TcpAckFrequency' -Value 1 -Type DWord -State $State
        Set-SafeRegistryValue -Path $path -Name 'TCPNoDelay' -Value 1 -Type DWord -State $State
    }
}

function Get-ActivePowerPlanGuid {
    $output = & powercfg /getactivescheme
    if ($output -match '([0-9a-fA-F-]{36})') {
        return $Matches[1]
    }
    return $null
}

function Set-PreferredPowerPlan {
    param([Parameter(Mandatory)]$State)

    if (-not $State.PowerPlan) {
        $State.PowerPlan = Get-ActivePowerPlanGuid
    }

    $ultimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    $highGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    $schemes = (& powercfg /list) -join "`n"

    if ($schemes -notmatch $ultimateGuid) {
        Write-Log 'Ultimate Performance plan not found. Attempting to create it.' 'INFO'
        & powercfg -duplicatescheme $ultimateGuid | Out-Null
        $schemes = (& powercfg /list) -join "`n"
    }

    if ($schemes -match $ultimateGuid) {
        & powercfg /setactive $ultimateGuid
        Write-Log 'Power plan set to Ultimate Performance.' 'OK'
    }
    else {
        & powercfg /setactive $highGuid
        Write-Log 'Ultimate Performance unavailable. Power plan set to High Performance.' 'OK'
    }
}

function Restore-PowerPlan {
    param([Parameter(Mandatory)]$State)

    if ($State.PowerPlan) {
        & powercfg /setactive $State.PowerPlan
        Write-Log "Restored previous power plan: $($State.PowerPlan)" 'OK'
    }
    else {
        Write-Log 'No previous power plan recorded.' 'WARN'
    }
}

function Clear-FiveMCacheSafe {
    $candidates = @(
        Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\data\cache',
        Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\data\server-cache',
        Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\data\server-cache-priv'
    )

    foreach ($path in $candidates) {
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log "FiveM cache path not found: $path" 'WARN'
            continue
        }

        Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                Write-Log "Removed FiveM cache item: $($_.FullName)" 'OK'
            }
            catch {
                Write-Log "Skipped locked FiveM cache item: $($_.FullName)" 'WARN'
            }
        }
    }
}

function Clear-NvidiaShaderCacheSafe {
    $paths = @(
        Join-Path $env:LOCALAPPDATA 'NVIDIA\DXCache',
        Join-Path $env:LOCALAPPDATA 'NVIDIA\GLCache',
        Join-Path $env:LOCALAPPDATA 'NVIDIA Corporation\NV_Cache',
        Join-Path $env:PROGRAMDATA 'NVIDIA Corporation\NV_Cache'
    )

    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log "NVIDIA shader cache path not found: $path" 'WARN'
            continue
        }

        Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                Write-Log "Removed NVIDIA shader cache item: $($_.FullName)" 'OK'
            }
            catch {
                Write-Log "Skipped locked NVIDIA shader cache item: $($_.FullName)" 'WARN'
            }
        }
    }
}

function Show-SystemStatus {
    Write-Log 'Collecting system status.' 'INFO'

    Write-Host ''
    Write-Host '=== Power Plan ===' -ForegroundColor Cyan
    & powercfg /getactivescheme

    Write-Host ''
    Write-Host '=== Active Network Adapters ===' -ForegroundColor Cyan
    Get-NetIPConfiguration |
        Where-Object { $_.NetAdapter.Status -eq 'Up' } |
        Select-Object InterfaceAlias, InterfaceIndex, @{Name='IPv4';Expression={($_.IPv4Address.IPAddress -join ', ')}} |
        Format-Table -AutoSize

    Write-Host ''
    Write-Host '=== Timer / Clock Info (read-only) ===' -ForegroundColor Cyan
    & bcdedit /enum '{current}' | Select-String -Pattern 'useplatformclock|disabledynamictick|tscsyncpolicy' -SimpleMatch
    Write-Host 'If no lines are shown, no explicit timer override was found.'

    Write-Host ''
    Write-Host '=== NVIDIA GPU Driver ===' -ForegroundColor Cyan
    $gpu = Get-CimInstance Win32_VideoController |
        Where-Object { $_.Name -match 'NVIDIA' } |
        Select-Object Name, DriverVersion, DriverDate
    if ($gpu) {
        $gpu | Format-Table -AutoSize
    }
    else {
        Write-Host 'No NVIDIA GPU detected by Win32_VideoController.' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host "Log file: $Script:LogFile" -ForegroundColor DarkGray
}

function Apply-FiveMPreset {
    param([switch]$SkipPrompt)

    Write-Host ''
    Write-Host 'This preset will disable Xbox/Game DVR capture, set a performance power plan,' -ForegroundColor Yellow
    Write-Host 'and apply safe TCP low-latency ACK settings only to active adapters.' -ForegroundColor Yellow
    Write-Host 'It will not modify FiveM game files, anti-cheat, services, HPET, macros, or memory.' -ForegroundColor Yellow
    if (-not $SkipPrompt) {
        $answer = Read-Host 'Continue? (Y/N)'
        if ($answer -notin @('Y', 'y')) {
            Write-Log 'Apply cancelled by user.' 'WARN'
            return
        }
    }

    $state = Load-RestoreState
    Disable-BackgroundCapture -State $state
    Set-NagleForActiveAdapters -State $state
    Set-PreferredPowerPlan -State $state
    Save-RestoreState -State $state
    Write-Log "Restore state saved: $Script:RestoreFile" 'OK'
    Write-Log 'Apply completed. Restart Windows before judging latency/frametime changes.' 'OK'
}

function Restore-Defaults {
    param([switch]$SkipPrompt)

    if (-not (Test-Path -LiteralPath $Script:RestoreFile)) {
        Write-Log "Restore file not found: $Script:RestoreFile" 'ERROR'
        return
    }

    if (-not $SkipPrompt) {
        $answer = Read-Host 'Restore registry values and previous power plan from backup? (Y/N)'
        if ($answer -notin @('Y', 'y')) {
            Write-Log 'Restore cancelled by user.' 'WARN'
            return
        }
    }

    $state = Load-RestoreState
    Restore-RegistryValues -State $state
    Restore-PowerPlan -State $state
    Write-Log 'Restore completed. Restart Windows to fully apply restored network settings.' 'OK'
}

function Show-Menu {
    while ($true) {
        Write-Host ''
        Write-Host 'FiveM Competitive PvP Optimizer' -ForegroundColor Cyan
        Write-Host '1. Apply FiveM PvP Preset'
        Write-Host '2. Restore Default'
        Write-Host '3. Clear FiveM cache safely'
        Write-Host '4. Clear NVIDIA shader cache safely'
        Write-Host '5. Show system status'
        Write-Host '0. Exit'
        $choice = Read-Host 'Select'

        try {
            switch ($choice) {
                '1' { Apply-FiveMPreset }
                '2' { Restore-Defaults }
                '3' { Clear-FiveMCacheSafe }
                '4' { Clear-NvidiaShaderCacheSafe }
                '5' { Show-SystemStatus }
                '0' { return }
                default { Write-Log 'Invalid menu selection.' 'WARN' }
            }
        }
        catch {
            Write-Log $_.Exception.Message 'ERROR'
        }
    }
}

try {
    Initialize-Workspace
    Write-Log 'FiveM PvP Optimizer started.' 'INFO'

    if ($Apply) { Assert-Administrator; Apply-FiveMPreset -SkipPrompt:$Force; exit }
    if ($Restore) { Assert-Administrator; Restore-Defaults -SkipPrompt:$Force; exit }
    if ($ClearFiveMCache) { Assert-Administrator; Clear-FiveMCacheSafe; exit }
    if ($ClearNvidiaShaderCache) { Assert-Administrator; Clear-NvidiaShaderCacheSafe; exit }
    if ($Status) { Show-SystemStatus; exit }

    Assert-Administrator
    Show-Menu
}
catch {
    try {
        Initialize-Workspace
        Write-Log $_.Exception.Message 'ERROR'
    }
    catch {
        Write-Error $_.Exception.Message
    }
    exit 1
}
