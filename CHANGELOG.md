# Changelog

## 1.0.1

- Added repository-root-aware `build.cmd` and `scripts/build.ps1` so Windows users do not accidentally run `dotnet` from `C:\Users\<user>`.
- Rewrote README build instructions to include `cd` into the repository and explicit solution/project paths.
- Expanded solution and project files into standard multi-line MSBuild format and added normal solution build configurations.
- Added `EnableWindowsTargeting` to the WPF app project for cross-OS restore/build compatibility where supported by the .NET SDK.

## 1.0.0

- Initial Cornner Desktop Studio solution scaffold.
- Added WPF shell, MVVM view model, localization, theme resources, core result models, backup/profile workflows, infrastructure safety services, and tests.
