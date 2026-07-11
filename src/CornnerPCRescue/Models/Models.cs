namespace CornnerPCRescue.Models;

public enum Severity { Healthy, Info, Warning, Critical }
public enum ApplyMode { Preview, RealApply }
public enum OperationKind { Scan, Apply, Restore }

public sealed record ScanResult(string Name, string Status, string Summary, string Evidence, string Recommendation, Severity Severity, TimeSpan Duration);
public sealed record DashboardSnapshot(int HealthScore, string Cpu, double CpuUsage, string RamTotal, string RamUsed, string RamFree, string Gpu, string GpuStatus, string SystemDrive, string WindowsVersion, string PowerPlan, string BackupStatus, string FiveMStatus, ApplyMode Mode, IReadOnlyList<ScanResult> Issues);
public sealed record MaintenancePreview(string Title, string Description, bool RequiresAdmin, IReadOnlyList<string> Actions, IReadOnlyList<string> ForbiddenActions);
public sealed record BackupManifest(string Id, DateTimeOffset CreatedAt, string Root, IReadOnlyList<BackupFile> Files);
public sealed record BackupFile(string OriginalPath, string BackupPath, string Sha256, long Length);
public sealed record ReportEntry(DateTimeOffset Timestamp, OperationKind Kind, string Title, string Details, Severity Severity);
public sealed record NetworkSnapshot(string Adapter, string Ip, string Gateway, string Dns, string LinkSpeed, string GatewayPing, string InternetPing, string PacketLoss, string Jitter, string TcpGlobalSettings);
public sealed record FiveMProfile(string Name, string Description, IReadOnlyList<string> PreviewActions);
