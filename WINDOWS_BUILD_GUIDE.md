# Windows Build Guide

This guide is for Windows PowerShell users who see errors like:

```text
MSBUILD : error MSB1003: Specify a project or solution file.
MSBUILD : error MSB1009: Project file does not exist.
.\build.cmd : The term '.\build.cmd' is not recognized...
cd : Cannot find path 'C:\path\to\legendary-potato' because it does not exist.
```

Those errors mean PowerShell is **not inside the folder that contains this repository**. `C:\path\to\legendary-potato` is only an example placeholder. Do not type it literally.


## No-command option

If you are not comfortable typing commands, open the downloaded/extracted repository folder in File Explorer and double-click:

```text
START_HERE.cmd
```

The helper checks whether it is next to `CornnerDesktopStudio.sln`, checks for `dotnet`, runs the build, verifies the EXE, and opens the publish folder when successful. Thai instructions are in `START_HERE_TH.md`.

## Step 1: Get the repository onto your PC

If you do not already have the files, download or clone the repository first.

### Option A: Git clone

```powershell
cd $env:USERPROFILE\Downloads
git clone <repository-url> legendary-potato
cd .\legendary-potato
```

### Option B: ZIP download

1. Download the repository ZIP from your Git hosting page.
2. Extract it, for example to:

```text
C:\Users\12\Downloads\legendary-potato
```

3. Open PowerShell in that extracted folder, or run:

```powershell
cd $env:USERPROFILE\Downloads\legendary-potato
```

## Step 2: Verify you are in the correct folder

Run:

```powershell
Get-ChildItem .\CornnerDesktopStudio.sln, .\build.cmd, .\src\CornnerDesktopStudio.App\CornnerDesktopStudio.App.csproj
```

You should see all three files. If any file is missing, you are still in the wrong folder or the repository was not downloaded/extracted correctly.

## Step 3: Build everything

```powershell
.\build.cmd
```

This runs:

- `dotnet restore`
- `dotnet build -c Release`
- `dotnet test -c Release`
- `dotnet publish -c Release -r win-x64 --self-contained true`
- EXE existence verification

## Step 4: Open the EXE

After a successful publish:

```powershell
.\publish\win-x64\CornnerDesktopStudio.exe
```

## If you do not know where the repository folder is

Search your user folder for the solution file:

```powershell
Get-ChildItem $env:USERPROFILE -Filter CornnerDesktopStudio.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10 FullName
```

Then `cd` to the directory shown before running `build.cmd`.

## If dotnet is not installed

Install the .NET 8 SDK from Microsoft, then reopen PowerShell:

```powershell
dotnet --info
```

The command must show an installed SDK before build/publish can work.
