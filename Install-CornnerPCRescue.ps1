<#
.SYNOPSIS
    Publishes CornnerPCRescue and creates a Windows Desktop shortcut.

.DESCRIPTION
    Run from the repository root on Windows. The script restores, publishes the WPF app,
    and creates a shortcut named CornnerPCRescue.lnk on the current user's Desktop.
#>

[CmdletBinding()]
param(
    [string]$Configuration = 'Release',
    [string]$PublishDir = (Join-Path $PSScriptRoot 'artifacts\CornnerPCRescue'),
    [switch]$NoLaunch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$solutionPath = Join-Path $repoRoot 'CornnerPCRescue.sln'
$projectPath = Join-Path $repoRoot 'src\CornnerPCRescue\CornnerPCRescue.csproj'

if (-not (Test-Path -LiteralPath $solutionPath)) {
    throw "CornnerPCRescue.sln was not found. Run this script from the repository root."
}

if (-not (Test-Path -LiteralPath $projectPath)) {
    throw "Project file was not found at '$projectPath'."
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'The dotnet CLI was not found. Install .NET 8 SDK, then run this script again.'
}

New-Item -ItemType Directory -Path $PublishDir -Force | Out-Null

Write-Host 'Restoring solution...' -ForegroundColor Cyan
& dotnet restore $solutionPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Publishing CornnerPCRescue...' -ForegroundColor Cyan
& dotnet publish $projectPath --configuration $Configuration --output $PublishDir --no-restore
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$exePath = Join-Path $PublishDir 'CornnerPCRescue.exe'
if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Publish completed, but CornnerPCRescue.exe was not found at '$exePath'."
}

$desktop = [Environment]::GetFolderPath('DesktopDirectory')
$shortcutPath = Join-Path $desktop 'CornnerPCRescue.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = $PublishDir
$shortcut.Description = 'CornnerPCRescue Windows maintenance utility'
$shortcut.IconLocation = $exePath
$shortcut.Save()

Write-Host "Installed CornnerPCRescue to: $PublishDir" -ForegroundColor Green
Write-Host "Desktop shortcut created: $shortcutPath" -ForegroundColor Green
Write-Host "Run it now with: $exePath" -ForegroundColor Green

if (-not $NoLaunch) {
    Write-Host 'Launching CornnerPCRescue...' -ForegroundColor Cyan
    Start-Process -FilePath $exePath -WorkingDirectory $PublishDir
}
