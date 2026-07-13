namespace CornnerDesktopStudio.Contracts.Models;

public enum OperationStatus { Success, PartialSuccess, Failed, VerificationFailed, RolledBack, Unsupported, Cancelled }
public enum RiskLevel { Safe, Caution, Unsupported }
public enum ThemeKind { Dark, Light, Midnight }
public enum AccentColor { Cyan, Blue, Purple, Green, Orange }
public enum WallpaperMode { Fit, Fill, Stretch, Center, Span }

public sealed record OperationResult(
    string Code,
    OperationStatus Status,
    string Message,
    IReadOnlyList<string> AppliedItems,
    IReadOnlyList<string> FailedItems,
    IReadOnlyList<string> SkippedItems,
    IReadOnlyList<string> VerificationResults,
    string? BackupPath,
    OperationResult? RollbackResult,
    DateTimeOffset Timestamp)
{
    public static OperationResult Success(string code, string message, string? backupPath = null) => new(code, OperationStatus.Success, message, [], [], [], [], backupPath, null, DateTimeOffset.UtcNow);
    public static OperationResult Failed(string code, string message, IReadOnlyList<string>? failed = null) => new(code, OperationStatus.Failed, message, [], failed ?? [], [], [], null, null, DateTimeOffset.UtcNow);
}

public sealed record PreviewChange(string Category, string Target, string CurrentValue, string TargetValue, RiskLevel RiskLevel, bool RequiresAdmin, bool RequiresExplorerRestart, bool RequiresAppRestart, bool Supported, string BackupStatus);

public sealed record DesktopProfile(string Id, string Name, bool PauseLiveWallpaper, bool HideWidgets, bool HideDock, bool HideDesktopIcons, string WallpaperMode, string LayoutName, DateTimeOffset? LastAppliedAt, IReadOnlyList<string> AppliedSettingsSummary);

public sealed record AppSettings(string Language, ThemeKind Theme, AccentColor Accent, double FontScale, string Density, bool StartMinimized, bool MinimizeToTray, bool CheckBrokenShortcuts, bool ConfirmBeforeApply, int WallpaperFps, bool PauseWhenFullscreen, bool PauseWhenGameRuns, int WidgetRefreshMs, int HardwareMonitorMs, int BackupRetentionCount)
{
    public static AppSettings Default(string language = "th-TH") => new(language, ThemeKind.Midnight, AccentColor.Cyan, 1.0, "Normal", false, true, true, true, 30, true, true, 1000, 2000, 10);
}

public sealed record BackupEnvelope(string Version, DateTimeOffset Timestamp, AppSettings Settings, IReadOnlyList<DesktopProfile> Profiles, string PreviousWallpaperPath, string Hash);
public sealed record WidgetDefinition(string Id, string Name, string Kind, double X, double Y, double Width, double Height, bool Locked, double Opacity, string Value);
public sealed record DockItem(string Id, string Name, string TargetPath, string Kind, string Category, bool Pinned);
public sealed record WindowLayout(string Id, string Name, IReadOnlyList<WindowSnapshot> Windows);
public sealed record WindowSnapshot(string ProcessName, string Title, double X, double Y, double Width, double Height, string State, string MonitorId);
public sealed record ActivityLogEntry(DateTimeOffset Time, string Level, string Category, string Action, string Target, string PreviousValue, string NewValue, string Result, string ErrorCode, string Message);
