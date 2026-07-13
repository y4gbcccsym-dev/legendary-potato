[CmdletBinding()]
param(
    [ValidateSet('Restore','Build','Test','Publish','All')]
    [string]$Target = 'All',

    [string]$Configuration = 'Release'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$solution = Join-Path $repoRoot 'CornnerDesktopStudio.sln'
$appProject = Join-Path $repoRoot 'src/CornnerDesktopStudio.App/CornnerDesktopStudio.App.csproj'
$publishDir = Join-Path $repoRoot 'publish/win-x64'

if (-not (Test-Path $solution)) { throw "Solution not found: $solution" }
if (-not (Test-Path $appProject)) { throw "App project not found: $appProject" }

function Invoke-Step {
    param([string]$Name, [scriptblock]$Block)
    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Block
}

if ($Target -in @('Restore','All')) { Invoke-Step 'Restore' { dotnet restore $solution } }
if ($Target -in @('Build','All')) { Invoke-Step 'Build' { dotnet build $solution -c $Configuration --no-restore } }
if ($Target -in @('Test','All')) { Invoke-Step 'Test' { dotnet test $solution -c $Configuration --no-build } }
if ($Target -in @('Publish','All')) {
    Invoke-Step 'Publish' { dotnet publish $appProject -c $Configuration -r win-x64 --self-contained true -o $publishDir }
    $exe = Join-Path $publishDir 'CornnerDesktopStudio.exe'
    if (-not (Test-Path $exe)) { throw "Expected EXE was not created: $exe" }
    Write-Host "Published: $exe" -ForegroundColor Green
}
