# How to find and run CornnerPCRescue on Windows

If PowerShell says `Project file does not exist`, you are not in the repository folder.
The folder must contain this file:

```text
CornnerPCRescue.sln
```

## 1. Find the repository folder

Run this from PowerShell:

```powershell
Get-ChildItem -Path $env:USERPROFILE -Filter CornnerPCRescue.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5 FullName
```

Example output:

```text
C:\Users\12\Downloads\legendary-potato\CornnerPCRescue.sln
```

## 2. Change directory to the folder that contains the solution

Use the folder path from the output, without `CornnerPCRescue.sln` at the end:

```powershell
cd C:\Users\12\Downloads\legendary-potato
```

Do not type `cd C:\path\to\legendary-potato`; that is only a placeholder.

## 3. Run the app

```powershell
.\Start-CornnerPCRescue.ps1
```

Or run directly with dotnet:

```powershell
dotnet run --project .\src\CornnerPCRescue\CornnerPCRescue.csproj
```
