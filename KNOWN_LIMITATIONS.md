# Known Limitations

- Live wallpaper WorkerW embedding is not enabled in this MVP because it requires Windows desktop runtime validation.
- Hardware temperatures are not estimated; unavailable values must show `Not Available`.
- Taskbar customization is capability-detected but not force-applied.
- Desktop organizer uses the planned virtual-panel model and must not move or delete real desktop files by default.
- System tray and overlay windows are planned for the next implementation pass.
- Build, test, publish, and executable launch verification require a machine with the .NET 8 SDK; the current container did not have `dotnet` installed.
