<#
.SYNOPSIS
    Interactive Windows gaming preset helper for hardware detection, shader cache cleanup, and optional performance tweaks.

.DESCRIPTION
    CLEANED BY CORNNER: license gate, client-info collection, webhook logging, and outbound web calls are intentionally absent.

    This script can change Windows registry values, power plans, service startup settings, temp files, and network settings
    when presets are applied. Review the functions before running, and run as Administrator only if you trust the tweaks.
#>

[CmdletBinding()]
param (
    [ValidateSet('Menu', 'Balanced', 'Competitive', 'MaxFPS', 'UltimateX', 'Restore')]
    [string]$Preset = 'Menu',

    [switch]$Preview,

    [switch]$NoBanner,

    [string]$StateRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$script:CPUName = 'Unknown CPU'
$script:GPUFullName = 'Unknown GPU'
$script:GPUType = 'UNKNOWN'
$script:IsAdministrator = $false
$script:IsWindows = $false
$script:PreviewMode = [bool]$Preview
$script:StateRoot = $null
$script:LogPath = $null
$script:BackupPath = $null
$script:BackupData = [ordered]@{
    Metadata = [ordered]@{}
    Registry = [ordered]@{}
    Services = [ordered]@{}
    PowerPlan = $null
    TcpGlobal = $null
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($script:LogPath)) {
        return
    }

    try {
        $entry = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        Add-Content -LiteralPath $script:LogPath -Value $entry -Encoding UTF8
    }
    catch {
        # Logging must never block a preset.
    }
}

function Write-Status {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ConsoleColor]$Color = 'White'
    )

    Write-Host $Message -ForegroundColor $Color
    Write-Log $Message
}

function Write-Type {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [int]$Delay = 15,

        [ConsoleColor]$Color = 'Cyan'
    )

    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color

    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char
        Start-Sleep -Milliseconds $Delay
    }

    Write-Host
    Write-Log $Text
    $Host.UI.RawUI.ForegroundColor = $oldColor
}

function Show-Spinner {
    param (
        [string]$Text = 'Processing',
        [int]$Seconds = 2
    )

    $spinner = @('|', '/', '-', '\')
    $end = (Get-Date).AddSeconds($Seconds)
    $i = 0

    while ((Get-Date) -lt $end) {
        Write-Host -NoNewline "`r$Text $($spinner[$i % 4])"
        Start-Sleep -Milliseconds 120
        $i++
    }

    Write-Host ' [READY]'
    Write-Log "$Text [READY]"
}

function Show-HackerBar {
    param (
        [string]$Text = 'Processing',
        [int]$Width = 40
    )

    Write-Status $Text Cyan

    for ($i = 1; $i -le $Width; $i++) {
        $ratio = $i / $Width

        switch ($ratio) {
            { $_ -lt 0.15 } { $color = 'DarkRed'; break }
            { $_ -lt 0.30 } { $color = 'Red'; break }
            { $_ -lt 0.45 } { $color = 'DarkYellow'; break }
            { $_ -lt 0.60 } { $color = 'Yellow'; break }
            { $_ -lt 0.75 } { $color = 'Green'; break }
            default { $color = 'DarkGreen' }
        }

        Write-Host -NoNewline '█' -ForegroundColor $color
        Start-Sleep -Milliseconds (Get-Random -Minimum 20 -Maximum 60)
    }

    Write-Host ' DONE' -ForegroundColor Green
    Write-Log "$Text DONE"
}

function Test-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-IsWindows {
    if ($env:OS -eq 'Windows_NT') {
        return $true
    }

    if ($PSVersionTable.ContainsKey('Platform') -and $PSVersionTable.Platform -eq 'Win32NT') {
        return $true
    }

    return $false
}

function Test-CommandAvailable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Join-OptionalPath {
    param (
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$ChildPath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return $null
    }

    return (Join-Path $BasePath $ChildPath)
}

function Initialize-State {
    param (
        [string]$RequestedStateRoot
    )

    if ([string]::IsNullOrWhiteSpace($RequestedStateRoot)) {
        if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
            $RequestedStateRoot = Join-Path $env:LOCALAPPDATA 'UltimateFPSBoost'
        }
        else {
            $RequestedStateRoot = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.UltimateFPSBoost'
        }
    }

    $script:StateRoot = $RequestedStateRoot
    $logRoot = Join-Path $script:StateRoot 'logs'
    $backupRoot = Join-Path $script:StateRoot 'backups'

    New-Item -Path $logRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:LogPath = Join-Path $logRoot "UltimateFPSBoost-$timestamp.log"
    $script:BackupPath = Join-Path $backupRoot 'last-backup.json'

    $script:BackupData.Metadata = [ordered]@{
        CreatedAt = (Get-Date).ToString('o')
        Preset = $Preset
        Preview = $script:PreviewMode
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        LogPath = $script:LogPath
    }

    Write-Log 'UltimateFPSBoost session initialized.'
}

function Invoke-CommandSafely {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    try {
        & $ScriptBlock
    }
    catch {
        Write-Status "[!] $FailureMessage`: $_" Red
    }
}

function Invoke-AdminCommandSafely {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$ActionName,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not $script:IsAdministrator) {
        Write-Status "[!] Skipping $ActionName because Administrator rights are required." Yellow
        return
    }

    Invoke-CommandSafely -ScriptBlock $ScriptBlock -FailureMessage $FailureMessage
}

function Invoke-TweakAction {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    if ($script:PreviewMode) {
        Write-Status "[PREVIEW] Would apply: $Description" DarkCyan
        return
    }

    Write-Log "Applying: $Description"
    & $ScriptBlock
}

function Get-GpuVendorPriority {
    param (
        [string]$Name
    )

    if ($Name -match 'NVIDIA') {
        return 4
    }
    if ($Name -match 'AMD|Radeon') {
        return 3
    }
    if ($Name -match 'Intel') {
        return 2
    }

    return 1
}

function Select-PreferredGpu {
    param (
        [object[]]$GpuList
    )

    $usableGpus = @(
        $GpuList | Where-Object {
            $_ -and $_.Name -and $_.Name -notmatch 'Microsoft Basic|Remote Display|Virtual Display|Parsec|RDP'
        }
    )

    if (-not $usableGpus) {
        $usableGpus = @($GpuList | Where-Object { $_ -and $_.Name })
    }

    return $usableGpus |
        Sort-Object `
            @{ Expression = { Get-GpuVendorPriority -Name $_.Name }; Descending = $true },
            @{ Expression = { if ($_.AdapterRAM) { [uint64]$_.AdapterRAM } else { 0 } }; Descending = $true } |
        Select-Object -First 1
}

function Backup-RegistryValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $key = "$Path|$Name"
    if ($script:BackupData.Registry.Contains($key)) {
        return
    }

    $entry = [ordered]@{
        Path = $Path
        Name = $Name
        PathExists = $false
        ValueExists = $false
        Value = $null
    }

    if (Test-Path -LiteralPath $Path) {
        $entry.PathExists = $true
        try {
            $property = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
            $entry.ValueExists = $true
            $entry.Value = $property.$Name
        }
        catch {
            $entry.ValueExists = $false
        }
    }

    $script:BackupData.Registry[$key] = $entry
}

function Set-RegistryDword {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint32]$Value
    )

    Backup-RegistryValue -Path $Path -Name $Name
    Invoke-TweakAction -Description "Set registry DWORD $Path\$Name to $Value" -ScriptBlock {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
    }
}

function Restore-RegistryValues {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Backup
    )

    foreach ($entry in $Backup.Registry.PSObject.Properties.Value) {
        Invoke-TweakAction -Description "Restore registry value $($entry.Path)\$($entry.Name)" -ScriptBlock {
            if ($entry.ValueExists) {
                if (-not (Test-Path -LiteralPath $entry.Path)) {
                    New-Item -Path $entry.Path -Force | Out-Null
                }
                New-ItemProperty -Path $entry.Path -Name $entry.Name -PropertyType DWord -Value ([uint32]$entry.Value) -Force | Out-Null
            }
            elseif ($entry.PathExists -and (Test-Path -LiteralPath $entry.Path)) {
                Remove-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
            }
        }
    }
}

function Backup-PowerPlan {
    if ($script:BackupData.PowerPlan -or -not (Test-CommandAvailable -Name 'powercfg')) {
        return
    }

    try {
        $activeScheme = powercfg /getactivescheme
        $guid = [regex]::Match($activeScheme, '[0-9a-fA-F-]{36}').Value
        $script:BackupData.PowerPlan = [ordered]@{
            ActiveSchemeRaw = $activeScheme
            ActiveSchemeGuid = $guid
        }
    }
    catch {
        Write-Status "[!] Could not back up active power plan: $_" DarkYellow
    }
}

function Restore-PowerPlan {
    param (
        [object]$Backup
    )

    if (-not $Backup.PowerPlan -or [string]::IsNullOrWhiteSpace($Backup.PowerPlan.ActiveSchemeGuid)) {
        return
    }

    Invoke-AdminCommandSafely -ActionName 'power plan restore' -FailureMessage 'Could not restore power plan' -ScriptBlock {
        if (-not (Test-CommandAvailable -Name 'powercfg')) {
            Write-Status '[!] powercfg was not found. Skipping power plan restore.' Yellow
            return
        }

        Invoke-TweakAction -Description "Restore active power plan $($Backup.PowerPlan.ActiveSchemeGuid)" -ScriptBlock {
            powercfg -setactive $Backup.PowerPlan.ActiveSchemeGuid
        }
    }
}

function Backup-ServiceState {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($script:BackupData.Services.Contains($Name)) {
        return
    }

    $service = Get-CimInstance Win32_Service -Filter "Name='$Name'" -ErrorAction SilentlyContinue
    if (-not $service) {
        return
    }

    $script:BackupData.Services[$Name] = [ordered]@{
        Name = $Name
        StartMode = $service.StartMode
        State = $service.State
    }
}

function Restore-ServiceStates {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Backup
    )

    foreach ($entry in $Backup.Services.PSObject.Properties.Value) {
        Invoke-AdminCommandSafely -ActionName "service restore for $($entry.Name)" -FailureMessage "Could not restore service $($entry.Name)" -ScriptBlock {
            $startupType = switch ($entry.StartMode) {
                'Auto' { 'Automatic' }
                'Manual' { 'Manual' }
                'Disabled' { 'Disabled' }
                default { 'Manual' }
            }

            Invoke-TweakAction -Description "Restore service $($entry.Name) startup to $startupType" -ScriptBlock {
                Set-Service -Name $entry.Name -StartupType $startupType -ErrorAction Stop
            }

            if ($entry.State -eq 'Running') {
                Invoke-TweakAction -Description "Restart service $($entry.Name) if it was previously running" -ScriptBlock {
                    Start-Service -Name $entry.Name -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function Backup-TcpGlobal {
    if ($script:BackupData.TcpGlobal -or -not (Test-CommandAvailable -Name 'netsh')) {
        return
    }

    try {
        $output = netsh int tcp show global | Out-String
        $parsed = [ordered]@{}
        $patterns = @{
            AutoTuning = 'Receive Window Auto-Tuning Level\s*:\s*(\S+)'
            Rss = 'Receive-Side Scaling State\s*:\s*(\S+)'
            Ecn = 'ECN Capability\s*:\s*(\S+)'
            Timestamps = 'RFC 1323 Timestamps\s*:\s*(\S+)'
        }

        foreach ($name in $patterns.Keys) {
            $match = [regex]::Match($output, $patterns[$name])
            if ($match.Success) {
                $parsed[$name] = $match.Groups[1].Value
            }
        }

        $script:BackupData.TcpGlobal = [ordered]@{
            Raw = $output
            Parsed = $parsed
        }
    }
    catch {
        Write-Status "[!] Could not back up TCP global settings: $_" DarkYellow
    }
}

function Restore-TcpGlobal {
    param (
        [object]$Backup
    )

    if (-not $Backup.TcpGlobal -or -not $Backup.TcpGlobal.Parsed) {
        return
    }

    Invoke-AdminCommandSafely -ActionName 'TCP global restore' -FailureMessage 'Could not restore TCP global settings' -ScriptBlock {
        if (-not (Test-CommandAvailable -Name 'netsh')) {
            Write-Status '[!] netsh was not found. Skipping TCP restore.' Yellow
            return
        }

        $parsed = $Backup.TcpGlobal.Parsed
        if ($parsed.AutoTuning) {
            Invoke-TweakAction -Description "Restore TCP autotuninglevel to $($parsed.AutoTuning)" -ScriptBlock {
                netsh int tcp set global autotuninglevel=$($parsed.AutoTuning) | Out-Null
            }
        }
        if ($parsed.Rss) {
            Invoke-TweakAction -Description "Restore TCP RSS to $($parsed.Rss)" -ScriptBlock {
                netsh int tcp set global rss=$($parsed.Rss) | Out-Null
            }
        }
        if ($parsed.Ecn) {
            Invoke-TweakAction -Description "Restore TCP ECN to $($parsed.Ecn)" -ScriptBlock {
                netsh int tcp set global ecncapability=$($parsed.Ecn) | Out-Null
            }
        }
        if ($parsed.Timestamps) {
            Invoke-TweakAction -Description "Restore TCP timestamps to $($parsed.Timestamps)" -ScriptBlock {
                netsh int tcp set global timestamps=$($parsed.Timestamps) | Out-Null
            }
        }
    }
}

function Save-BackupData {
    if ($script:PreviewMode) {
        Write-Status '[PREVIEW] Backup data was collected in memory but not written.' DarkCyan
        return
    }

    try {
        $script:BackupData.Metadata.CompletedAt = (Get-Date).ToString('o')
        $script:BackupData | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $script:BackupPath -Encoding UTF8
        Write-Status "[OK] Backup saved to $script:BackupPath" Green
    }
    catch {
        Write-Status "[!] Could not save backup data: $_" Red
    }
}

function Restore-LastBackup {
    if (-not (Test-Path -LiteralPath $script:BackupPath)) {
        Write-Status "[!] No backup found at $script:BackupPath" Yellow
        return
    }

    try {
        $backup = Get-Content -LiteralPath $script:BackupPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Status "[!] Could not read backup: $_" Red
        return
    }

    Write-Status "[+] Restoring backup from $script:BackupPath" Cyan
    Restore-RegistryValues -Backup $backup
    Restore-ServiceStates -Backup $backup
    Restore-PowerPlan -Backup $backup
    Restore-TcpGlobal -Backup $backup
    Write-Status '[OK] Restore completed. Reboot if Windows requests it or if service/network state does not update immediately.' Green
}

function Remove-DirectoryContents {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return
    }

    if ($script:PreviewMode) {
        Write-Status "[PREVIEW] Would clear contents of $Path" DarkCyan
        return
    }

    try {
        Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop |
            Remove-Item -Recurse -Force -ErrorAction Stop
        Write-Log "Cleared contents of $Path"
    }
    catch {
        Write-Status "Could not remove cache contents from $Path`: $_" DarkYellow
    }
}

function Show-ProgramBanner {
    Clear-Host
    Write-Type '>>> ULTIMATE X <<<' 10 Green
    Write-Type 'High Performance Engine Initializing...' 12 Cyan
    Show-HackerBar 'Loading core modules'
    Start-Sleep -Milliseconds 300
}

function Detect-HardwareInfo {
    if (-not $script:IsWindows) {
        Write-Status '[!] Hardware detection is only supported on Windows. Skipping scan.' Yellow
        return
    }

    Write-Type 'Scanning system hardware...' 12 Cyan
    Show-HackerBar 'Detecting CPU'
    Show-HackerBar 'Detecting GPU'

    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpu -and $cpu.Name) {
            $script:CPUName = $cpu.Name.Trim()
        }
    }
    catch {
        $script:CPUName = 'Unknown CPU'
    }

    Write-Status "CPU Detected: $script:CPUName" Green

    try {
        $gpuList = Get-CimInstance Win32_VideoController -ErrorAction Stop
    }
    catch {
        Write-Status "[!] GPU detection failed: $_" DarkYellow
        $gpuList = @()
    }

    $gpu = Select-PreferredGpu -GpuList $gpuList

    if ($gpu -and $gpu.Name) {
        $script:GPUFullName = $gpu.Name.Trim()
    }
    else {
        $script:GPUFullName = 'Unknown GPU'
    }

    Write-Status "GPU Detected: $script:GPUFullName" Green

    if ($script:GPUFullName -match 'NVIDIA') {
        $script:GPUType = 'NVIDIA'
    }
    elseif ($script:GPUFullName -match 'AMD|Radeon') {
        $script:GPUType = 'AMD'
    }
    elseif ($script:GPUFullName -match 'Intel') {
        $script:GPUType = 'Intel'
    }
    else {
        $script:GPUType = 'UNKNOWN'
    }

    Write-Status "GPU Type: $script:GPUType" Yellow
}

function Disable-GameBar {
    Write-Status '[+] Disabling Game Bar and capture delay...' Cyan
    Invoke-CommandSafely -FailureMessage 'Failed to modify registry for Game Bar' -ScriptBlock {
        Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0
        Set-RegistryDword -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0
        Set-RegistryDword -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'ShowGameBar' -Value 0
        Set-RegistryDword -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1
        Set-RegistryDword -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1
        Write-Status '[OK] Game Bar capture disabled and Game Mode kept enabled.' Green
    }
}

function Set-UltimatePerformance {
    Write-Status '[+] Enabling Ultimate Performance Mode...' Cyan
    Invoke-AdminCommandSafely -ActionName 'Ultimate Performance power plan' -FailureMessage 'Could not set power plan' -ScriptBlock {
        if (-not (Test-CommandAvailable -Name 'powercfg')) {
            Write-Status '[!] powercfg was not found. Skipping power plan tweak.' Yellow
            return
        }

        Backup-PowerPlan
        $ultimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
        $availablePlans = powercfg /list

        Invoke-TweakAction -Description 'Create Ultimate Performance power plan when missing' -ScriptBlock {
            if ($availablePlans -notmatch $ultimateGuid) {
                powercfg -duplicatescheme $ultimateGuid | Out-Null
            }
        }

        Invoke-TweakAction -Description 'Activate Ultimate Performance power plan' -ScriptBlock {
            powercfg -setactive $ultimateGuid
        }

        Write-Status '[OK] Ultimate Performance activated.' Green
    }
}

function Disable-BackgroundApps {
    Write-Status '[+] Disabling Background Apps...' Cyan
    Invoke-CommandSafely -FailureMessage 'Failed to disable background apps' -ScriptBlock {
        Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -Name 'GlobalUserDisabled' -Value 1
        Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BackgroundAppGlobalToggle' -Value 0
        Write-Status '[OK] Background apps disabled.' Green
    }
}

function Disable-Services {
    Write-Status '[+] Disabling SysMain service...' Cyan
    Invoke-AdminCommandSafely -ActionName 'SysMain service tuning' -FailureMessage 'Failed to stop/disable SysMain' -ScriptBlock {
        $service = Get-Service 'SysMain' -ErrorAction SilentlyContinue
        if (-not $service) {
            Write-Status '[!] SysMain service not found. Skipping.' Yellow
            return
        }

        Backup-ServiceState -Name 'SysMain'
        Invoke-TweakAction -Description 'Stop SysMain service' -ScriptBlock {
            if ($service.Status -ne 'Stopped') {
                Stop-Service 'SysMain' -Force -ErrorAction SilentlyContinue
            }
        }

        Invoke-TweakAction -Description 'Disable SysMain startup' -ScriptBlock {
            Set-Service 'SysMain' -StartupType Disabled
        }

        Write-Status '[OK] SysMain disabled.' Green
    }
}

function Clear-Temp {
    Write-Status '[+] Clearing Temp Files...' Cyan
    Invoke-CommandSafely -FailureMessage 'Temp clear failed' -ScriptBlock {
        if ($env:TEMP) {
            Remove-DirectoryContents -Path $env:TEMP
        }

        if ($script:IsAdministrator -and $env:WINDIR) {
            Remove-DirectoryContents -Path (Join-OptionalPath -BasePath $env:WINDIR -ChildPath 'Temp')
        }

        Write-Status '[OK] Temp cleared.' Green
    }
}

function Network-Optimize {
    Write-Status '[+] Applying network optimizations...' Cyan
    Invoke-AdminCommandSafely -ActionName 'network optimizations' -FailureMessage 'Network tweak failed' -ScriptBlock {
        if (-not (Test-CommandAvailable -Name 'netsh')) {
            Write-Status '[!] netsh was not found. Skipping network tweaks.' Yellow
            return
        }

        Backup-TcpGlobal
        Invoke-TweakAction -Description 'Set TCP autotuninglevel to normal' -ScriptBlock { netsh int tcp set global autotuninglevel=normal | Out-Null }
        Invoke-TweakAction -Description 'Enable TCP RSS' -ScriptBlock { netsh int tcp set global rss=enabled | Out-Null }
        Invoke-TweakAction -Description 'Disable TCP ECN capability' -ScriptBlock { netsh int tcp set global ecncapability=disabled | Out-Null }
        Invoke-TweakAction -Description 'Disable TCP timestamps' -ScriptBlock { netsh int tcp set global timestamps=disabled | Out-Null }
        Write-Status '[OK] Network tweaks applied.' Green
    }
}

function Clear-CommonShaderCache {
    $paths = @(
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'D3DSCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'Microsoft\DirectX Shader Cache')
    ) | Where-Object { $_ }

    foreach ($path in $paths) {
        Remove-DirectoryContents -Path $path
    }
}

function Clear-NvidiaShaderCache {
    if ($script:GPUType -ne 'NVIDIA') {
        Write-Status '[!] NVIDIA not detected. Skipping NVIDIA shader cache clear.' Yellow
        return
    }

    Write-Status '[+] Clearing NVIDIA Shader Cache...' Cyan
    $paths = @(
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'NVIDIA\DXCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'NVIDIA\GLCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'NVIDIA\ComputeCache')
    )

    if ($env:ProgramData) {
        $paths += (Join-OptionalPath -BasePath $env:ProgramData -ChildPath 'NVIDIA Corporation\NV_Cache')
    }

    foreach ($path in ($paths | Where-Object { $_ })) {
        Remove-DirectoryContents -Path $path
    }

    Clear-CommonShaderCache
    Write-Status '[OK] NVIDIA Shader Cache Cleared!' Green
}

function Clear-AMDShaderCache {
    if ($script:GPUType -ne 'AMD') {
        Write-Status '[!] AMD not detected. Skipping AMD shader cache clear.' Yellow
        return
    }

    Write-Status '[+] Clearing AMD Shader Cache...' Cyan
    $paths = @(
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'AMD\DXCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'AMD\GLCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'AMD\VkCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'AMD\DxcCache')
    )

    foreach ($path in ($paths | Where-Object { $_ })) {
        Remove-DirectoryContents -Path $path
    }

    Clear-CommonShaderCache
    Write-Status '[OK] AMD Shader Cache Cleared!' Green
}

function Clear-IntelShaderCache {
    if ($script:GPUType -ne 'Intel') {
        Write-Status '[!] Intel GPU not detected. Skipping Intel shader cache clear.' Yellow
        return
    }

    Write-Status '[+] Clearing Intel Shader Cache...' Cyan
    $paths = @(
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'Intel\ShaderCache'),
        (Join-OptionalPath -BasePath $env:LOCALAPPDATA -ChildPath 'Intel\IGfxCache')
    )

    foreach ($path in ($paths | Where-Object { $_ })) {
        Remove-DirectoryContents -Path $path
    }

    Clear-CommonShaderCache
    Write-Status '[OK] Intel Shader Cache Cleared!' Green
}

function Clear-DetectedShaderCache {
    if ($script:GPUType -eq 'NVIDIA') {
        Clear-NvidiaShaderCache
    }
    elseif ($script:GPUType -eq 'AMD') {
        Clear-AMDShaderCache
    }
    elseif ($script:GPUType -eq 'Intel') {
        Clear-IntelShaderCache
    }
    else {
        Clear-CommonShaderCache
        Write-Status '[!] Unknown GPU type. Cleared common DirectX shader cache only.' Yellow
    }
}

function Preset-Balanced {
    Write-Status "`n[+] Applying Balanced Preset..." Cyan
    Disable-GameBar
    Set-UltimatePerformance
    Clear-DetectedShaderCache
    Write-Status '[OK] Balanced Preset Applied!' Green
}

function Preset-Competitive {
    Write-Status "`n[+] Applying Competitive Preset..." Cyan
    Disable-GameBar
    Disable-BackgroundApps
    Set-UltimatePerformance
    Network-Optimize
    Clear-DetectedShaderCache
    Write-Status '[OK] Competitive Preset Applied!' Green
}

function Preset-MaxFPS {
    Write-Status "`n[+] Applying Max FPS Preset..." Cyan
    Disable-GameBar
    Disable-BackgroundApps
    Disable-Services
    Set-UltimatePerformance
    Clear-Temp
    Network-Optimize
    Clear-DetectedShaderCache
    Write-Status '[OK] Max FPS Preset Applied!' Green
}

function Preset-UltraCompetitive {
    Write-Status "`n[+] Applying ULTRA Competitive Preset X (Lowest Latency)..." Magenta

    Disable-GameBar
    Disable-BackgroundApps
    Disable-Services
    Set-UltimatePerformance
    Clear-DetectedShaderCache

    Invoke-AdminCommandSafely -ActionName 'multimedia responsiveness tweaks' -FailureMessage 'Registry tweak for responsiveness failed' -ScriptBlock {
        Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Value 0
        Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value ([uint32]::MaxValue)
        Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'GPU Priority' -Value 8
        Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Priority' -Value 6
        Write-Status '[OK] Multimedia responsiveness tweaks applied.' Green
    }

    Invoke-AdminCommandSafely -ActionName 'advanced network tweaks' -FailureMessage 'Network advanced tweaks failed' -ScriptBlock {
        if (-not (Test-CommandAvailable -Name 'netsh')) {
            Write-Status '[!] netsh was not found. Skipping advanced network tweaks.' Yellow
            return
        }

        Backup-TcpGlobal
        Invoke-TweakAction -Description 'Set TCP autotuninglevel to normal' -ScriptBlock { netsh int tcp set global autotuninglevel=normal | Out-Null }
        Invoke-TweakAction -Description 'Enable TCP RSS' -ScriptBlock { netsh int tcp set global rss=enabled | Out-Null }
        Invoke-TweakAction -Description 'Disable TCP ECN capability' -ScriptBlock { netsh int tcp set global ecncapability=disabled | Out-Null }
        Invoke-TweakAction -Description 'Disable TCP timestamps' -ScriptBlock { netsh int tcp set global timestamps=disabled | Out-Null }
        Invoke-TweakAction -Description 'Use CTCP congestion provider for internet template' -ScriptBlock { netsh int tcp set supplemental template=internet congestionprovider=ctcp | Out-Null }
        Write-Status '[OK] Advanced network tweaks applied.' Green
    }

    Invoke-AdminCommandSafely -ActionName 'Nagle tweaks' -FailureMessage 'Failed to apply Nagle tweaks' -ScriptBlock {
        $interfaces = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction Stop

        foreach ($interface in $interfaces) {
            $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($interface.PSChildName)"
            Set-RegistryDword -Path $interfacePath -Name 'TcpNoDelay' -Value 1
            Set-RegistryDword -Path $interfacePath -Name 'TcpDelAckTicks' -Value 0
        }

        Write-Status '[OK] Nagle Algorithm disabled for all adapters.' Green
    }

    Write-Status '[ULTRA] X MODE TURNED ON!' Green
}

function Invoke-PresetByName {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Balanced', 'Competitive', 'MaxFPS', 'UltimateX')]
        [string]$Name
    )

    switch ($Name) {
        'Balanced' { Preset-Balanced }
        'Competitive' { Preset-Competitive }
        'MaxFPS' { Preset-MaxFPS }
        'UltimateX' { Preset-UltraCompetitive }
    }

    Save-BackupData
}

function Preset-Menu {
    while ($true) {
        Clear-Host
        Write-Host '=========== PRESET MENU ===========' -ForegroundColor Cyan
        Write-Host '1) Balanced Preset'
        Write-Host '2) Competitive Preset'
        Write-Host '3) Max FPS Preset'
        Write-Host '4) Ultimate X Mode'
        Write-Host 'R) Restore Last Backup'
        Write-Host 'X) Back'
        Write-Host '-----------------------------------'

        $presetChoice = Read-Host 'Select Preset'
        switch ($presetChoice.ToUpperInvariant()) {
            '1' { Invoke-PresetByName -Name 'Balanced' }
            '2' { Invoke-PresetByName -Name 'Competitive' }
            '3' { Invoke-PresetByName -Name 'MaxFPS' }
            '4' { Invoke-PresetByName -Name 'UltimateX' }
            'R' { Restore-LastBackup }
            'X' { return }
            default { Write-Status '[!] Invalid option!' Red }
        }

        Write-Host "`nPress Enter to continue..."
        Read-Host | Out-Null
    }
}

Initialize-State -RequestedStateRoot $StateRoot
$script:IsWindows = Test-IsWindows
if (-not $script:IsWindows) {
    Write-Status '[!] UltimateFPSBoost is intended for Windows. Presets will be skipped on this operating system.' Red
    return
}

$script:IsAdministrator = Test-IsAdministrator
if (-not $script:IsAdministrator) {
    Write-Status '[!] Not running as Administrator. Power, service, system network, and HKLM tweaks will be skipped.' Yellow
}
if ($script:PreviewMode) {
    Write-Status '[PREVIEW] Preview mode enabled. No registry, service, network, power, temp, or cache changes will be written.' DarkCyan
}

if (-not $NoBanner) {
    Show-ProgramBanner
}
Detect-HardwareInfo

switch ($Preset) {
    'Menu' { Preset-Menu }
    'Restore' { Restore-LastBackup }
    default { Invoke-PresetByName -Name $Preset }
}

Write-Status "`n[+] Exiting UltimateFPSBoost. Log: $script:LogPath" Cyan
Write-Status '[+] Remember to reboot if you changed power plans, services, or network settings.' Cyan
