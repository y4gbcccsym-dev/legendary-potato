#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsInspectorPath = Join-Path $ScriptRoot 'tools\nvidiaProfileInspector.exe'
$RootInspectorPath = Join-Path $ScriptRoot 'nvidiaProfileInspector.exe'
$ProfilePath = Join-Path $ScriptRoot 'profiles\FiveM_GTA5_Performance.nip'
$BackupsPath = Join-Path $ScriptRoot 'backups'

function Write-ThaiInfo {
    param([string]$Message)
    Write-Host "[ข้อมูล] $Message" -ForegroundColor Cyan
}

function Write-ThaiSuccess {
    param([string]$Message)
    Write-Host "[สำเร็จ] $Message" -ForegroundColor Green
}

function Write-ThaiWarn {
    param([string]$Message)
    Write-Host "[คำเตือน] $Message" -ForegroundColor Yellow
}

function Write-ThaiError {
    param([string]$Message)
    Write-Host "[ผิดพลาด] $Message" -ForegroundColor Red
}

function Pause-Thai {
    Write-Host ''
    Read-Host 'กด Enter เพื่อกลับไปเมนูหลัก'
}

function Get-NvidiaAdapter {
    try {
        $adapters = Get-CimInstance Win32_VideoController
        return $adapters | Where-Object { $_.Name -match 'NVIDIA' } | Select-Object -First 1
    }
    catch {
        Write-ThaiError 'ไม่สามารถตรวจสอบการ์ดจอจาก Win32_VideoController ได้'
        return $null
    }
}

function Get-InspectorPath {
    if (Test-Path -LiteralPath $ToolsInspectorPath) {
        return $ToolsInspectorPath
    }

    if (Test-Path -LiteralPath $RootInspectorPath) {
        return $RootInspectorPath
    }

    return $null
}

function Ensure-RequiredFiles {
    $inspectorPath = Get-InspectorPath
    if (-not $inspectorPath) {
        Write-ThaiError 'ไม่พบ nvidiaProfileInspector.exe ในโฟลเดอร์ tools หรือโฟลเดอร์หลักของโปรเจกต์'
        return $false
    }

    if (-not (Test-Path -LiteralPath $ProfilePath)) {
        Write-ThaiError 'ไม่พบไฟล์โปรไฟล์ profiles\FiveM_GTA5_Performance.nip กรุณาวางไฟล์จริงก่อนใช้งาน'
        return $false
    }

    return $true
}

function Get-NewestExportedNipNearInspector {
    param([string]$InspectorPath)

    $inspectorFolder = Split-Path -Parent $InspectorPath
    return Get-ChildItem -Path $inspectorFolder -Filter '*.nip' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Backup-NvidiaProfiles {
    $inspectorPath = Get-InspectorPath
    if (-not $inspectorPath) {
        Write-ThaiError 'ไม่พบ nvidiaProfileInspector.exe จึงไม่สามารถสำรองข้อมูลได้'
        return $false
    }

    if (-not (Test-Path -LiteralPath $BackupsPath)) {
        New-Item -Path $BackupsPath -ItemType Directory -Force | Out-Null
    }

    $beforeNewest = Get-NewestExportedNipNearInspector -InspectorPath $inspectorPath

    Write-ThaiInfo 'กำลังสำรองโปรไฟล์ NVIDIA ที่ปรับแต่งไว้...'
    try {
        Start-Process -FilePath $inspectorPath -ArgumentList '-exportCustomized' -Wait -NoNewWindow
    }
    catch {
        Write-ThaiError 'สั่ง export โปรไฟล์ไม่สำเร็จ'
        return $false
    }

    Start-Sleep -Milliseconds 500
    $afterNewest = Get-NewestExportedNipNearInspector -InspectorPath $inspectorPath

    if (-not $afterNewest) {
        Write-ThaiError 'ไม่พบไฟล์ .nip ที่ถูก export จาก NVIDIA Profile Inspector'
        return $false
    }

    if ($beforeNewest -and $afterNewest.FullName -eq $beforeNewest.FullName -and $afterNewest.LastWriteTime -le $beforeNewest.LastWriteTime) {
        Write-ThaiWarn 'ไม่พบไฟล์สำรองใหม่ จะใช้ไฟล์ .nip ล่าสุดที่หาได้แทน'
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupFileName = "NVIDIA_Custom_Backup_$timestamp.nip"
    $backupTarget = Join-Path $BackupsPath $backupFileName

    try {
        Copy-Item -LiteralPath $afterNewest.FullName -Destination $backupTarget -Force
        Write-ThaiSuccess "สำรองโปรไฟล์สำเร็จ: $backupFileName"
        return $true
    }
    catch {
        Write-ThaiError 'คัดลอกไฟล์สำรองไปยังโฟลเดอร์ backups ไม่สำเร็จ'
        return $false
    }
}

function Apply-FiveMGTA5Profile {
    if (-not (Ensure-RequiredFiles)) {
        return
    }

    if (-not (Backup-NvidiaProfiles)) {
        Write-ThaiError 'หยุดการนำเข้าโปรไฟล์เพื่อความปลอดภัย เพราะการสำรองข้อมูลไม่สำเร็จ'
        return
    }

    $inspectorPath = Get-InspectorPath
    Write-ThaiInfo 'กำลังนำเข้าโปรไฟล์ FiveM + GTA V...'

    try {
        Start-Process -FilePath $inspectorPath -ArgumentList @('-silentImport', "`"$ProfilePath`"") -Wait -NoNewWindow
        Write-ThaiSuccess 'นำเข้าโปรไฟล์ FiveM + GTA V สำเร็จ'
        Write-ThaiInfo 'กรุณาปิด FiveM / GTA V / Rockstar / Epic ให้หมดก่อน แล้วเปิดใหม่อีกครั้ง'
        Write-ThaiInfo 'โดยปกติไม่ต้องรีสตาร์ต Windows ทั้งเครื่อง ยกเว้นไดรเวอร์ NVIDIA แจ้งให้รีสตาร์ต'
    }
    catch {
        Write-ThaiError 'นำเข้าโปรไฟล์ FiveM + GTA V ไม่สำเร็จ'
    }
}

function Restore-NvidiaBackup {
    $inspectorPath = Get-InspectorPath
    if (-not $inspectorPath) {
        Write-ThaiError 'ไม่พบ nvidiaProfileInspector.exe จึงไม่สามารถคืนค่าได้'
        return
    }

    if (-not (Test-Path -LiteralPath $BackupsPath)) {
        Write-ThaiError 'ไม่พบโฟลเดอร์ backups สำหรับการคืนค่า'
        return
    }

    $backupFiles = Get-ChildItem -Path $BackupsPath -Filter '*.nip' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if (-not $backupFiles) {
        Write-ThaiError 'ไม่พบไฟล์สำรอง .nip ในโฟลเดอร์ backups'
        return
    }

    Write-Host 'เลือกไฟล์สำรองที่ต้องการคืนค่า:' -ForegroundColor Cyan
    for ($i = 0; $i -lt $backupFiles.Count; $i++) {
        Write-Host "[$($i + 1)] $($backupFiles[$i].Name)"
    }

    $choice = Read-Host 'พิมพ์หมายเลขไฟล์สำรอง'
    if (-not [int]::TryParse($choice, [ref]$null)) {
        Write-ThaiError 'รูปแบบหมายเลขไม่ถูกต้อง'
        return
    }

    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $backupFiles.Count) {
        Write-ThaiError 'หมายเลขที่เลือกอยู่นอกช่วงรายการ'
        return
    }

    $selectedBackup = $backupFiles[$index].FullName
    Write-ThaiInfo "กำลังคืนค่าจากไฟล์: $($backupFiles[$index].Name)"

    try {
        Start-Process -FilePath $inspectorPath -ArgumentList @('-silentImport', "`"$selectedBackup`"") -Wait -NoNewWindow
        Write-ThaiSuccess 'คืนค่าโปรไฟล์ NVIDIA จากไฟล์สำรองสำเร็จ'
    }
    catch {
        Write-ThaiError 'คืนค่าโปรไฟล์จากไฟล์สำรองไม่สำเร็จ'
    }
}

function Check-System {
    $adapter = Get-NvidiaAdapter
    if ($adapter) {
        Write-ThaiSuccess "พบการ์ดจอ NVIDIA: $($adapter.Name)"
        if ($adapter.DriverVersion) {
            Write-ThaiInfo "เวอร์ชันไดรเวอร์: $($adapter.DriverVersion)"
        }
        else {
            Write-ThaiWarn 'ไม่พบข้อมูลเวอร์ชันไดรเวอร์จากระบบ'
        }
    }
    else {
        Write-ThaiWarn 'ไม่พบการ์ดจอ NVIDIA ในระบบ'
    }

    $inspectorPath = Get-InspectorPath
    if ($inspectorPath) {
        Write-ThaiSuccess "พบ nvidiaProfileInspector.exe: $inspectorPath"
    }
    else {
        Write-ThaiError 'ไม่พบ nvidiaProfileInspector.exe'
    }

    if (Test-Path -LiteralPath $ProfilePath) {
        Write-ThaiSuccess 'พบไฟล์โปรไฟล์ FiveM_GTA5_Performance.nip'
    }
    else {
        Write-ThaiError 'ไม่พบไฟล์โปรไฟล์ FiveM_GTA5_Performance.nip'
    }

    if (Test-Path -LiteralPath $BackupsPath) {
        $latestBackup = Get-ChildItem -Path $BackupsPath -Filter '*.nip' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestBackup) {
            Write-ThaiInfo "ไฟล์สำรองล่าสุด: $($latestBackup.Name)"
        }
        else {
            Write-ThaiWarn 'ยังไม่มีไฟล์สำรองในโฟลเดอร์ backups'
        }
    }
    else {
        Write-ThaiWarn 'ยังไม่มีโฟลเดอร์ backups'
    }
}

function Open-NvidiaApp {
    $possiblePaths = @(
        "$env:ProgramFiles\NVIDIA Corporation\NVIDIA app\NVIDIAApp.exe",
        "$env:LocalAppData\NVIDIA Corporation\NVIDIA App\NVIDIAApp.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path -LiteralPath $path) {
            Start-Process -FilePath $path
            Write-ThaiSuccess 'เปิด NVIDIA App แล้ว'
            return
        }
    }

    Write-ThaiWarn 'ไม่พบ NVIDIA App อัตโนมัติ กรุณาเปิดด้วยตนเองจากเมนู Start'
}

function Open-NvidiaControlPanel {
    try {
        Start-Process 'nvcplui.exe'
        Write-ThaiSuccess 'เปิด NVIDIA Control Panel แล้ว'
    }
    catch {
        Write-ThaiWarn 'ไม่สามารถเปิด NVIDIA Control Panel อัตโนมัติ กรุณาเปิดด้วยตนเอง'
    }
}

function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
        Write-ThaiError 'สคริปต์นี้ต้องใช้ Windows PowerShell 5.1 หรือใหม่กว่า'
        return $false
    }

    return $true
}

if (-not (Test-PowerShellVersion)) {
    exit 1
}

while ($true) {
    Clear-Host
    Write-Host '==== NVD FiveM Profile Toolkit ====' -ForegroundColor Magenta
    Write-Host '[1] Check system / ตรวจสอบระบบ'
    Write-Host '[2] Backup NVIDIA customized profiles / สำรองโปรไฟล์ NVIDIA เดิม'
    Write-Host '[3] Apply FiveM + GTA V NVIDIA profile / นำเข้าโปรไฟล์ FiveM + GTA V'
    Write-Host '[4] Restore NVIDIA profile from backup / คืนค่าโปรไฟล์จากไฟล์สำรอง'
    Write-Host '[5] Open NVIDIA App / เปิด NVIDIA App'
    Write-Host '[6] Open NVIDIA Control Panel / เปิด NVIDIA Control Panel'
    Write-Host '[0] Exit / ออก'

    $menuChoice = Read-Host 'เลือกเมนู'
    Write-Host ''

    switch ($menuChoice) {
        '1' { Check-System; Pause-Thai }
        '2' { Backup-NvidiaProfiles | Out-Null; Pause-Thai }
        '3' { Apply-FiveMGTA5Profile; Pause-Thai }
        '4' { Restore-NvidiaBackup; Pause-Thai }
        '5' { Open-NvidiaApp; Pause-Thai }
        '6' { Open-NvidiaControlPanel; Pause-Thai }
        '0' {
            Write-ThaiInfo 'ออกจากโปรแกรม'
            break
        }
        default {
            Write-ThaiWarn 'เมนูไม่ถูกต้อง กรุณาเลือกใหม่'
            Pause-Thai
        }
    }
}
