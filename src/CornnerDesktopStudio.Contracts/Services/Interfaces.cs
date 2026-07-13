using CornnerDesktopStudio.Contracts.Models;

namespace CornnerDesktopStudio.Contracts.Services;

public interface IProfileService { IReadOnlyList<DesktopProfile> GetDefaultProfiles(); IReadOnlyList<PreviewChange> Preview(DesktopProfile profile); OperationResult Validate(DesktopProfile profile); Task<OperationResult> ApplyAsync(DesktopProfile profile, CancellationToken cancellationToken); Task<OperationResult> VerifyAsync(DesktopProfile profile, CancellationToken cancellationToken); }
public interface IBackupService { Task<BackupEnvelope> CreateAsync(AppSettings settings, IReadOnlyList<DesktopProfile> profiles, CancellationToken cancellationToken); Task<OperationResult> ValidateAsync(BackupEnvelope backup, CancellationToken cancellationToken); Task<OperationResult> RestoreAsync(BackupEnvelope backup, CancellationToken cancellationToken); }
public interface ILocalizationService { string CurrentLanguage { get; } string this[string key] { get; } IReadOnlyDictionary<string,string> GetLanguage(string language); IReadOnlyList<string> ValidateCompleteness(); }
public interface IShortcutService { bool IsBrokenShortcut(string targetPath); }
public interface IWindowLayoutService { bool IsWithinVirtualDesktop(WindowSnapshot window, double desktopWidth, double desktopHeight); OperationResult ValidateRestore(WindowLayout layout, double desktopWidth, double desktopHeight); }
public interface IWindowsCapabilityService { bool SupportsTaskbarAlignment(); bool SupportsWidgetsButton(); string WindowsVersion { get; } }
public interface IAppDataService { string RootPath { get; } void EnsureFolders(); }
