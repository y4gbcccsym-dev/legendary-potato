<#
.SYNOPSIS
    Launches CornnerPCRescue from the repository root on Windows.

.DESCRIPTION
    Run this script from the folder that contains CornnerPCRescue.sln. It avoids the common
    "The project file does not exist" error caused by running dotnet from C:\Users\<name>
    or another directory that does not contain the repository.
#>

[CmdletBinding()]
param(
    [switch]$Release
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$projectPath = Join-Path $repoRoot 'src\CornnerPCRescue\CornnerPCRescue.csproj'

if (-not (Test-Path -LiteralPath $projectPath)) {
    throw "Project file was not found at '$projectPath'. Open PowerShell in the repository root, or run this script from the folder that contains CornnerPCRescue.sln."
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'The dotnet CLI was not found. Install .NET 8 SDK, then run this script again.'
}

$configuration = if ($Release) { 'Release' } else { 'Debug' }
Write-Host "Starting CornnerPCRescue ($configuration) from $projectPath" -ForegroundColor Cyan
& dotnet run --project $projectPath --configuration $configuration
exit $LASTEXITCODE
