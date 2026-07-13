# Architecture

Cornner Desktop Studio uses a layered .NET 8 architecture.

- `CornnerDesktopStudio.App`: WPF UI, MVVM view models, resource dictionaries, localization implementation, and dependency injection bootstrap.
- `CornnerDesktopStudio.Contracts`: DTOs, enums, interfaces, result objects, and shared models.
- `CornnerDesktopStudio.Core`: validation, preview/apply orchestration, profile management, backup validation, restore, rollback-friendly result handling, and layout validation.
- `CornnerDesktopStudio.Infrastructure`: local app data folders, safe Windows capability checks, shortcut validation, wallpaper validation, and future isolated Windows API adapters.
- `tests`: xUnit tests with temporary directories and fake-safe workflows only.

All destructive or risky Windows behaviors are excluded from the initial MVP and must be guarded by preview, backup, capability checks, and explicit user apply actions before implementation.
