# PLXULTIMATEX!
#requires -version 5.1

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# ULTIMATEXPLUS :: PERFORMANCE ENGINE
# Low Latency | Stable Frametime | Competitive Optimization
# ============================================================

$script:AppName = "ULTIMATEXPLUS"
$script:AppVersion = "1.1.14"
$script:AppliedSteps = 0
$script:FailedSteps = 0
$script:RunId = Get-Date -Format "yyyyMMdd-HHmmss"
$script:BackupRoot = $null
$script:BackedUpRegistryKeys = @{}
$script:LogPath = $null
$script:TranscriptStarted = $false
$script:StepResults = @()
$script:ManifestPath = $null
$script:RestoreCheckpointCreated = $false

# ==========================
# OUTPUT HELPERS
# ==========================
function Write-Type {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [int]$Delay = 10,
        [ConsoleColor]$Color = "Cyan"
    )

    $oldColor = $Host.UI.RawUI.ForegroundColor

    try {
        $Host.UI.RawUI.ForegroundColor = $Color

        foreach ($char in $Text.ToCharArray()) {
            Write-Host -NoNewline $char
            Start-Sleep -Milliseconds $Delay
        }

        Write-Host
    }
    finally {
        $Host.UI.RawUI.ForegroundColor = $oldColor
    }
}

function Write-Status {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [ConsoleColor]$Color = "Cyan"
    )

    Write-Host $Text -ForegroundColor $Color
}

function Write-Section {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "==== $Title ====" -ForegroundColor Cyan
}

# ==========================
# WINDOW TITLE STATE SYSTEM
# ==========================
function Set-AppState {
    param (
        [ValidateSet("READY", "APPLYING", "ACTIVE", "EXIT")]
        [string]$State
    )

    switch ($State) {
        "READY" {
            $host.UI.RawUI.WindowTitle = "$script:AppName | READY"
        }
        "APPLYING" {
            $host.UI.RawUI.WindowTitle = "$script:AppName | APPLYING OPTIMIZATIONS"
        }
        "ACTIVE" {
            $host.UI.RawUI.WindowTitle = "$script:AppName | ACTIVE"
        }
        "EXIT" {
            $host.UI.RawUI.WindowTitle = "$script:AppName | EXITED"
        }
    }
}

# ==========================
# ENTERPRISE SPLASH SCREEN
# ==========================
function Show-SplashEnterprise {
    Clear-Host
    Write-Host "$script:AppName Engine" -ForegroundColor Cyan
    Write-Host "Performance Optimization Suite" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Version   : $script:AppVersion"
    Write-Host "Security  : Administrator"
    Write-Host "Status    : Initializing system components..."
    Write-Host ""
    Start-Sleep -Milliseconds 700
}

# ==========================
# UNIVERSAL ANIMATION
# ==========================
function Show-TechStep {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [int]$Steps = 3,
        [int]$Delay = 220
    )

    Write-Host "[ENGINE] $Text" -NoNewline

    for ($i = 1; $i -le $Steps; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Milliseconds $Delay
    }

    Write-Host " OK" -ForegroundColor Green
}

function Show-ProgressText {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [int]$Delay = 90
    )

    Write-Host "[CORE] $Text" -NoNewline

    foreach ($c in " >>>>>".ToCharArray()) {
        Write-Host $c -NoNewline
        Start-Sleep -Milliseconds $Delay
    }

    Write-Host " DONE" -ForegroundColor Green
}

# ==========================
# EXECUTION HELPERS
# ==========================
function Invoke-NativeCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        & $FilePath @Arguments *> $null
        return ($LASTEXITCODE -eq 0)
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Invoke-OptimizationStep {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host "[ENGINE] $Name..." -NoNewline
    $timer = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $result = & $Action
        $timer.Stop()

        if ($false -eq $result) {
            $script:FailedSteps++
            $script:StepResults += [ordered]@{ Name = $Name; Status = "FAILED"; DurationMs = $timer.ElapsedMilliseconds }
            Write-Host " FAILED" -ForegroundColor Red
            return $false
        }

        $script:AppliedSteps++
        $script:StepResults += [ordered]@{ Name = $Name; Status = "OK"; DurationMs = $timer.ElapsedMilliseconds }
        Write-Host " OK ($($timer.ElapsedMilliseconds) ms)" -ForegroundColor Green
        return $true
    }
    catch {
        $timer.Stop()
        $script:FailedSteps++
        $script:StepResults += [ordered]@{ Name = $Name; Status = "FAILED"; DurationMs = $timer.ElapsedMilliseconds; Error = $_.Exception.Message }
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "        $($_.Exception.Message)" -ForegroundColor DarkYellow
        return $false
    }
}

function Set-RegistryValueSafe {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet("REG_DWORD", "REG_SZ")]
        [string]$Type,
        [Parameter(Mandatory = $true)]
        [string]$Data
    )

    [void](Backup-RegistryKey -Path $Path)

    $ok = Invoke-NativeCommand -FilePath "reg.exe" -Arguments @("add", $Path, "/v", $Name, "/t", $Type, "/d", $Data, "/f")
    return $ok
}

function Remove-CacheContents {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $true
    }

    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    return $true
}

function Initialize-BackupFolder {
    $basePath = if ($env:ProgramData) { $env:ProgramData } else { $env:TEMP }
    $backupPath = Join-Path $basePath "$script:AppName\Backups\$script:RunId"

    New-Item -Path $backupPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    $script:BackupRoot = $backupPath

    Write-Status "[SAFETY] Registry backup folder: $script:BackupRoot" DarkGray
}

function Convert-RegistryPathToFileName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (($Path -replace '[\\/:*?"<>| ]', '_') + '.reg')
}

function Backup-RegistryKey {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not $script:BackupRoot) {
        Initialize-BackupFolder
    }

    if ($script:BackedUpRegistryKeys.ContainsKey($Path)) {
        return $true
    }

    $fileName = Convert-RegistryPathToFileName -Path $Path
    $backupFile = Join-Path $script:BackupRoot $fileName
    [void](Invoke-NativeCommand -FilePath "reg.exe" -Arguments @("export", $Path, $backupFile, "/y"))

    # reg export can fail when a key does not exist yet. Continue because reg add will create it.
    $script:BackedUpRegistryKeys[$Path] = $backupFile
    return $true
}

function Test-RequiredCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        return $true
    }

    Write-Host "        Missing required command: $CommandName" -ForegroundColor DarkYellow
    return $false
}

function Test-RequiredCommands {
    $requiredCommands = @("reg.exe", "bcdedit.exe", "netsh.exe", "powercfg.exe")
    $allAvailable = $true

    foreach ($command in $requiredCommands) {
        if (-not (Test-RequiredCommand -CommandName $command)) {
            $allAvailable = $false
        }
    }

    return $allAvailable
}

function New-SystemRestoreCheckpointSafe {
    $checkpointCommand = Get-Command "Checkpoint-Computer" -ErrorAction SilentlyContinue

    if (-not $checkpointCommand) {
        Write-Host "        System Restore checkpoint command is not available on this Windows edition." -ForegroundColor DarkYellow
        return $false
    }

    try {
        Checkpoint-Computer -Description "$script:AppName $script:RunId" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        $script:RestoreCheckpointCreated = $true
        return $true
    }
    catch {
        Write-Host "        Unable to create restore point: $($_.Exception.Message)" -ForegroundColor DarkYellow
        return $false
    }
}

function Initialize-RunLog {
    $basePath = if ($env:ProgramData) { $env:ProgramData } else { $env:TEMP }
    $logRoot = Join-Path $basePath "$script:AppName\Logs"
    $script:LogPath = Join-Path $logRoot "$script:RunId.log"

    try {
        New-Item -Path $logRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Start-Transcript -Path $script:LogPath -Append -ErrorAction Stop | Out-Null
        $script:TranscriptStarted = $true
        Write-Status "[SAFETY] Run log: $script:LogPath" DarkGray
        return $true
    }
    catch {
        $script:LogPath = $null
        $script:TranscriptStarted = $false
        Write-Host "[WARN] Unable to start run log: $($_.Exception.Message)" -ForegroundColor DarkYellow
        return $false
    }
}

function Stop-RunLog {
    if (-not $script:TranscriptStarted) {
        return
    }

    try {
        Stop-Transcript | Out-Null
    }
    catch {
        Write-Host "[WARN] Unable to stop run log cleanly: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

function Export-RunManifest {
    $basePath = if ($env:ProgramData) { $env:ProgramData } else { $env:TEMP }
    $reportRoot = Join-Path $basePath "$script:AppName\Reports"
    $script:ManifestPath = Join-Path $reportRoot "$script:RunId.json"

    $manifest = [ordered]@{
        AppName                  = $script:AppName
        AppVersion               = $script:AppVersion
        RunId                    = $script:RunId
        CompletedAt              = (Get-Date).ToString("o")
        AppliedSteps             = $script:AppliedSteps
        FailedSteps              = $script:FailedSteps
        RestoreCheckpointCreated = $script:RestoreCheckpointCreated
        BackupRoot               = $script:BackupRoot
        LogPath                  = $script:LogPath
        Steps                    = $script:StepResults
    }

    try {
        New-Item -Path $reportRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
        $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $script:ManifestPath -Encoding UTF8 -ErrorAction Stop
        return $true
    }
    catch {
        $script:ManifestPath = $null
        Write-Host "[WARN] Unable to write run manifest: $($_.Exception.Message)" -ForegroundColor DarkYellow
        return $false
    }
}

function Show-StepSummary {
    if (-not $script:StepResults -or $script:StepResults.Count -eq 0) {
        return
    }

    Write-Host ""
    Write-Host "Step Details:" -ForegroundColor Cyan
    foreach ($step in $script:StepResults) {
        $color = if ($step.Status -eq "OK") { "DarkGreen" } else { "DarkYellow" }
        Write-Host (" - {0,-42} {1,-6} {2,6} ms" -f $step.Name, $step.Status, $step.DurationMs) -ForegroundColor $color
    }
}

# ==========================
# ADMIN PRIVILEGE CHECK
# ==========================
function Check-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Clear-Host
        Write-Host "========================================" -ForegroundColor Red
        Write-Host " $script:AppName :: ADMIN REQUIRED" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "[X] This program must be run as Administrator." -ForegroundColor Yellow
        Write-Host "[!] Please right-click PowerShell and select 'Run as administrator'." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press Enter to exit..."
        Read-Host
        exit 1
    }

    Write-Status "[SECURITY] Privilege Level : ADMIN" Green
}

# ==========================
# THAI REAL-TIME TITLE
# ==========================
function Update-ThaiTimeTitle {
    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById("SE Asia Standard Time")
    $thaiTime = [System.TimeZoneInfo]::ConvertTimeFromUtc(
        (Get-Date).ToUniversalTime(),
        $tz
    )

    $host.UI.RawUI.WindowTitle =
        "$script:AppName | TH {0}" -f $thaiTime.ToString("dd/MM/yyyy HH:mm:ss")
}

# ==========================
# CLIENT INFO
# ==========================
function Get-ClientInfo {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $osCaption = "Unknown"
    $architecture = "x86"

    if ($os -and $os.Caption) {
        $osCaption = $os.Caption
    }

    if ([Environment]::Is64BitOperatingSystem) {
        $architecture = "x64"
    }

    return [ordered]@{
        Username   = $env:USERNAME
        Computer   = $env:COMPUTERNAME
        OS         = $osCaption
        Arch       = $architecture
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Time       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

function Show-ClientInfo {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Info
    )

    Write-Section "CLIENT PROFILE"

    foreach ($item in $Info.GetEnumerator()) {
        Write-Host ("{0,-11}: {1}" -f $item.Key, $item.Value) -ForegroundColor DarkGray
    }
}

# ==========================
# HARDWARE DETECTION
# ==========================
function Detect-HardwareInfo {
    Write-Type "[SYS] Scanning hardware topology..." 5 Cyan

    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1

    $global:CPUName = if ($cpu.Name) { $cpu.Name.Trim() } else { "Unknown CPU" }
    $global:GPUFullName = if ($gpu.Name) { $gpu.Name.Trim() } else { "Unknown GPU" }

    if ($GPUFullName -match "NVIDIA") {
        $global:GPUType = "NVIDIA"
    }
    elseif ($GPUFullName -match "AMD|Radeon") {
        $global:GPUType = "AMD"
    }
    else {
        $global:GPUType = "OTHER"
    }

    Write-Section "HARDWARE PROFILE"
    Write-Host "CPU      : $CPUName" -ForegroundColor Green
    Write-Host "GPU      : $GPUFullName" -ForegroundColor Green
    Write-Host "GPU TYPE : $GPUType" -ForegroundColor Yellow
}

# ==========================
# CORE FUNCTIONS
# ==========================
function Set-PriorityControl {
    $a = Set-RegistryValueSafe "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "ConvertibleSlateMode" "REG_DWORD" "0"
    $b = Set-RegistryValueSafe "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" "REG_DWORD" "22"
    return ($a -and $b)
}

function Disable-GameBar {
    $ok = Set-RegistryValueSafe "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" "REG_DWORD" "0"
    return $ok
}

function Disable-BackgroundApps {
    $ok = Set-RegistryValueSafe "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" "REG_DWORD" "1"
    return $ok
}

function Optimize-SystemResponsiveness {
    $path = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    $a = Set-RegistryValueSafe $path "NetworkThrottlingIndex" "REG_DWORD" "0xffffffff"
    $b = Set-RegistryValueSafe $path "SystemResponsiveness" "REG_DWORD" "0"
    return ($a -and $b)
}

function Enable-PerformancePowerPlan {
    $ultimatePerformanceGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"

    # Duplicate can fail if the Ultimate Performance plan already exists. Continue and try to activate it.
    [void](Invoke-NativeCommand -FilePath "powercfg.exe" -Arguments @("/duplicatescheme", $ultimatePerformanceGuid))

    $ultimateActive = Invoke-NativeCommand -FilePath "powercfg.exe" -Arguments @("/setactive", $ultimatePerformanceGuid)
    if ($ultimateActive) {
        return $true
    }

    # Fallback for Windows editions that do not expose Ultimate Performance.
    return (Invoke-NativeCommand -FilePath "powercfg.exe" -Arguments @("/setactive", "SCHEME_MIN"))
}

function Clear-NvidiaShaderCache {
    if ($GPUType -ne "NVIDIA") { return $true }

    $dx = Remove-CacheContents "$env:LOCALAPPDATA\NVIDIA\DXCache"
    $gl = Remove-CacheContents "$env:LOCALAPPDATA\NVIDIA\GLCache"
    return ($dx -and $gl)
}

function Clear-AMDShaderCache {
    if ($GPUType -ne "AMD") { return $true }

    $ok = Remove-CacheContents "$env:LOCALAPPDATA\AMD\DXCache"
    return $ok
}

# ==========================
# PRESET FUNCTIONS
# ==========================
function Disable-FullscreenOptimizations {
    $a = Set-RegistryValueSafe "HKCU\System\GameConfigStore" "GameDVR_FSEBehavior" "REG_DWORD" "2"
    $b = Set-RegistryValueSafe "HKCU\System\GameConfigStore" "GameDVR_FSEBehaviorMode" "REG_DWORD" "2"
    $c = Set-RegistryValueSafe "HKCU\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" "REG_DWORD" "1"
    return ($a -and $b -and $c)
}

function Optimize-MMCSSTasks {
    $path = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    $a = Set-RegistryValueSafe $path "Scheduling Category" "REG_SZ" "High"
    $b = Set-RegistryValueSafe $path "SFIO Priority" "REG_SZ" "High"
    $c = Set-RegistryValueSafe $path "Background Only" "REG_SZ" "False"
    $d = Set-RegistryValueSafe $path "GPU Priority" "REG_DWORD" "8"
    $e = Set-RegistryValueSafe $path "Priority" "REG_DWORD" "6"
    return ($a -and $b -and $c -and $d -and $e)
}

function Optimize-MouseInput {
    $path = "HKCU\Control Panel\Mouse"
    $a = Set-RegistryValueSafe $path "MouseSpeed" "REG_SZ" "0"
    $b = Set-RegistryValueSafe $path "MouseThreshold1" "REG_SZ" "0"
    $c = Set-RegistryValueSafe $path "MouseThreshold2" "REG_SZ" "0"
    return ($a -and $b -and $c)
}

function Disable-HPET {
    [void](Invoke-NativeCommand -FilePath "bcdedit.exe" -Arguments @("/deletevalue", "useplatformclock"))

    # bcdedit returns an error when the value is already absent. That state is acceptable.
    return $true
}

function Optimize-GPU-TDR {
    $path = "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    $a = Set-RegistryValueSafe $path "TdrDelay" "REG_DWORD" "10"
    $b = Set-RegistryValueSafe $path "TdrDdiDelay" "REG_DWORD" "20"
    return ($a -and $b)
}

function Set-TcpAutotuning {
    $ok = Invoke-NativeCommand -FilePath "netsh.exe" -Arguments @("int", "tcp", "set", "global", "autotuninglevel=high")
    return $ok
}

function Show-CompletionMessage {
    $message = if ($script:FailedSteps -eq 0) {
        "Installation completed successfully.`nAll optimizations are now active."
    }
    else {
        "Optimization completed with ${script:FailedSteps} warning(s).`nReview the console output before rebooting."
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show(
            $message,
            $script:AppName,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
    catch {
        Write-Host "[INFO] $message" -ForegroundColor Cyan
    }
}

function Preset-UltimateXPLUS {
    $script:AppliedSteps = 0
    $script:FailedSteps = 0
    $script:StepResults = @()
    $script:ManifestPath = $null
    $script:RestoreCheckpointCreated = $false

    Write-Type "[ULTRA] ULTIMATEXPLUS CORE ENGAGED" 5 Magenta
    Set-AppState "APPLYING"
    Write-Section "APPLYING CORE MODE"

    Invoke-OptimizationStep "Validate required Windows tools" { Test-RequiredCommands } | Out-Null
    Invoke-OptimizationStep "Create system restore checkpoint" { New-SystemRestoreCheckpointSafe } | Out-Null
    Invoke-OptimizationStep "Create registry backup folder" { Initialize-BackupFolder; return $true } | Out-Null
    Invoke-OptimizationStep "Disable Game Bar capture" { Disable-GameBar } | Out-Null
    Invoke-OptimizationStep "Disable background applications" { Disable-BackgroundApps } | Out-Null
    Invoke-OptimizationStep "Apply system responsiveness profile" { Optimize-SystemResponsiveness } | Out-Null
    Invoke-OptimizationStep "Enable high performance power profile" { Enable-PerformancePowerPlan } | Out-Null
    Invoke-OptimizationStep "Apply PriorityControl parameters" { Set-PriorityControl } | Out-Null
    Invoke-OptimizationStep "Apply Plus X fullscreen optimizations" { Disable-FullscreenOptimizations } | Out-Null
    Invoke-OptimizationStep "Optimize MMCSS game task profile" { Optimize-MMCSSTasks } | Out-Null
    Invoke-OptimizationStep "Optimize mouse input" { Optimize-MouseInput } | Out-Null
    Invoke-OptimizationStep "Check HPET platform clock state" { Disable-HPET } | Out-Null
    Invoke-OptimizationStep "Apply GPU TDR values" { Optimize-GPU-TDR } | Out-Null
    Invoke-OptimizationStep "Clear GPU shader cache" {
        if ($GPUType -eq "NVIDIA") { return (Clear-NvidiaShaderCache) }
        if ($GPUType -eq "AMD") { return (Clear-AMDShaderCache) }
        return $true
    } | Out-Null
    Invoke-OptimizationStep "Set TCP autotuning" { Set-TcpAutotuning } | Out-Null
    Invoke-OptimizationStep "Export run manifest" { Export-RunManifest } | Out-Null

    Set-AppState "ACTIVE"
    Write-Section "SUMMARY"
    $warningColor = "Yellow"

    if ($script:FailedSteps -eq 0) {
        $warningColor = "Green"
    }

    Write-Host "Applied : ${script:AppliedSteps}" -ForegroundColor Green
    Write-Host "Warnings: ${script:FailedSteps}" -ForegroundColor $warningColor
    Show-StepSummary
    if ($script:BackupRoot) {
        Write-Host "Backups : $script:BackupRoot" -ForegroundColor DarkGray
    }
    if ($script:LogPath) {
        Write-Host "Run Log : $script:LogPath" -ForegroundColor DarkGray
    }
    if ($script:ManifestPath) {
        Write-Host "Manifest: $script:ManifestPath" -ForegroundColor DarkGray
    }
    Write-Host "[ENGINE] LOW LATENCY MODE ACTIVE" -ForegroundColor Green
    Write-Host "[!] Reboot Windows to ensure every system change is fully applied." -ForegroundColor Yellow

    Show-CompletionMessage
}

# ==========================
# MENU
# ==========================
function Preset-Menu {
    while ($true) {
        Update-ThaiTimeTitle
        Clear-Host
        Write-Host "===== ULTIMATEXPLUS PANEL =====" -ForegroundColor Cyan
        Write-Host "1) Activate ULTIMATEXPLUS CORE MODE"
        Write-Host "X) Exit"

        $c = Read-Host "Select Option"

        switch ($c) {
            "1" { Preset-UltimateXPLUS }
            "X" { return }
            "x" { return }
            default { Write-Host "[!] Invalid option." -ForegroundColor Yellow }
        }

        Write-Host "Press Enter..."
        Read-Host
    }
}

# ==========================
# BOOT SEQUENCE
# ==========================
Set-AppState "READY"
Check-Admin
[void](Initialize-RunLog)
Show-SplashEnterprise

Clear-Host
$banner = @'
==============================
   ULTIMATEXPLUS ENGINE
==============================
'@
Write-Host $banner -ForegroundColor Cyan

Write-Type "ULTIMATEXPLUS :: PERFORMANCE ENGINE" 5 Green
Write-Type "Initializing low-latency pipeline..." 5 DarkCyan

Show-TechStep "Booting Core Modules"
Show-TechStep "Syncing Hardware Profile"
Show-ProgressText "Loading Engine Components"

$ClientInfo = Get-ClientInfo
Show-ClientInfo $ClientInfo
Detect-HardwareInfo
Preset-Menu

Set-AppState "EXIT"
Write-Host "[EXIT] ULTIMATEXPLUS Engine Closed. Reboot recommended." -ForegroundColor Cyan
Stop-RunLog
