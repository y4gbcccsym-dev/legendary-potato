using CornnerPCRescue.Models;
namespace CornnerPCRescue.Services;

public interface ISystemInfoService { Task<DashboardSnapshot> GetDashboardAsync(ApplyMode mode, CancellationToken ct); Task<IReadOnlyList<ScanResult>> ScanAsync(ApplyMode mode, IProgress<ScanResult> progress, CancellationToken ct); }
public interface IMaintenanceService { Task<MaintenancePreview> PreviewAsync(CancellationToken ct); Task<IReadOnlyList<ReportEntry>> ApplyAsync(BackupManifest backup, CancellationToken ct); }
public interface IFiveMService { Task<IReadOnlyList<ScanResult>> ScanAsync(CancellationToken ct); Task<MaintenancePreview> PreviewProfileAsync(string profile, CancellationToken ct); Task<IReadOnlyList<ReportEntry>> ApplyProfileAsync(string profile, BackupManifest backup, CancellationToken ct); }
public interface INetworkService { Task<NetworkSnapshot> GetSnapshotAsync(CancellationToken ct); Task<MaintenancePreview> PreviewOptionalChangesAsync(CancellationToken ct); }
public interface IBackupService { string BackupRoot { get; set; } Task<BackupManifest> CreateBackupAsync(IEnumerable<string> paths, CancellationToken ct); Task<bool> RestoreAsync(BackupManifest manifest, CancellationToken ct); Task<IReadOnlyList<BackupManifest>> ListBackupsAsync(CancellationToken ct); }
public interface IReportService { Task AddAsync(ReportEntry entry, CancellationToken ct); Task<IReadOnlyList<ReportEntry>> ListAsync(CancellationToken ct); Task<string> ExportTextAsync(CancellationToken ct); Task<string> ExportJsonAsync(CancellationToken ct); }
public interface ISettingsService { ApplyMode Mode { get; set; } string Language { get; set; } bool DetailedLogging { get; set; } string BackupRoot { get; set; } }
