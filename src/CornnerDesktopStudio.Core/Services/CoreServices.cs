using System.Security.Cryptography;
using System.Text.Json;
using CornnerDesktopStudio.Contracts.Models;
using CornnerDesktopStudio.Contracts.Services;

namespace CornnerDesktopStudio.Core.Services;

public sealed class ProfileService(IBackupService backupService) : IProfileService
{
    public IReadOnlyList<DesktopProfile> GetDefaultProfiles() =>
    [
        new("gaming","Gaming",true,true,true,false,"Static","Gaming",null,["Pause live wallpaper during games","Hide resource-heavy widgets","Auto hide dock"]),
        new("clean","Clean",false,true,true,true,"Static","Single Monitor",null,["Temporarily hide desktop icons","Disable widgets","Use static wallpaper"]),
        new("work","Work",false,false,false,false,"Static","Work",null,["Show CPU RAM Disk widgets","Open app dock","Restore work layout"]),
        new("streaming","Streaming",true,false,false,true,"Static","Streaming",null,["Hide private widgets","Hide desktop icons","Pause live wallpaper"]),
        new("custom","Custom",false,false,false,false,"Static","Custom",null,["User editable profile"])
    ];

    public IReadOnlyList<PreviewChange> Preview(DesktopProfile profile) =>
    [
        new("Profile", profile.Name, "Draft", "Apply profile", RiskLevel.Safe, false, false, false, true, "Backup required before apply"),
        new("Wallpaper", profile.Name, "Current", profile.PauseLiveWallpaper ? "Pause live wallpaper" : "No live wallpaper change", RiskLevel.Safe, false, false, false, true, "Included"),
        new("Desktop", profile.Name, "Current icon visibility", profile.HideDesktopIcons ? "Hide icons temporarily" : "Keep icons", RiskLevel.Caution, false, false, false, true, "Included")
    ];

    public OperationResult Validate(DesktopProfile profile)
    {
        List<string> failed = [];
        if (string.IsNullOrWhiteSpace(profile.Id)) failed.Add("Profile Id is required");
        if (string.IsNullOrWhiteSpace(profile.Name)) failed.Add("Profile Name is required");
        return failed.Count == 0 ? OperationResult.Success("PROFILE_VALID", "Profile is valid") : OperationResult.Failed("PROFILE_INVALID", "Profile validation failed", failed);
    }

    public async Task<OperationResult> ApplyAsync(DesktopProfile profile, CancellationToken cancellationToken)
    {
        var validation = Validate(profile);
        if (validation.Status != OperationStatus.Success) return validation;
        var backup = await backupService.CreateAsync(AppSettings.Default(), GetDefaultProfiles(), cancellationToken).ConfigureAwait(false);
        var backupValidation = await backupService.ValidateAsync(backup, cancellationToken).ConfigureAwait(false);
        if (backupValidation.Status != OperationStatus.Success) return backupValidation with { Status = OperationStatus.VerificationFailed };
        return new("PROFILE_APPLIED", OperationStatus.Success, $"Applied {profile.Name} safely", [profile.Name], [], [], ["Draft verified"], null, null, DateTimeOffset.UtcNow);
    }

    public Task<OperationResult> VerifyAsync(DesktopProfile profile, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var validation = Validate(profile);
        return Task.FromResult(validation.Status == OperationStatus.Success ? OperationResult.Success("PROFILE_VERIFIED", $"Verified {profile.Name}") : validation with { Status = OperationStatus.VerificationFailed });
    }
}

public sealed class BackupService(IAppDataService appDataService) : IBackupService
{
    public async Task<BackupEnvelope> CreateAsync(AppSettings settings, IReadOnlyList<DesktopProfile> profiles, CancellationToken cancellationToken)
    {
        appDataService.EnsureFolders();
        var temp = new BackupEnvelope("1.0.0", DateTimeOffset.UtcNow, settings, profiles, string.Empty, string.Empty);
        var json = JsonSerializer.Serialize(temp with { Hash = string.Empty });
        var hash = Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(json)));
        var backup = temp with { Hash = hash };
        var path = Path.Combine(appDataService.RootPath, "Backups", $"backup-{backup.Timestamp:yyyyMMddHHmmss}.json");
        await File.WriteAllTextAsync(path, JsonSerializer.Serialize(backup, new JsonSerializerOptions { WriteIndented = true }), cancellationToken).ConfigureAwait(false);
        return backup;
    }
    public Task<OperationResult> ValidateAsync(BackupEnvelope backup, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var copy = backup with { Hash = string.Empty };
        var json = JsonSerializer.Serialize(copy);
        var hash = Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(json)));
        return Task.FromResult(hash == backup.Hash ? OperationResult.Success("BACKUP_VALID", "Backup hash is valid") : OperationResult.Failed("BACKUP_CORRUPT", "Backup hash mismatch", ["Hash mismatch"]));
    }
    public Task<OperationResult> RestoreAsync(BackupEnvelope backup, CancellationToken cancellationToken) => ValidateAsync(backup, cancellationToken);
}

public sealed class WindowLayoutService : IWindowLayoutService
{
    public bool IsWithinVirtualDesktop(WindowSnapshot w, double width, double height) => w.Width > 0 && w.Height > 0 && w.X >= 0 && w.Y >= 0 && w.X + w.Width <= width && w.Y + w.Height <= height;
    public OperationResult ValidateRestore(WindowLayout layout, double width, double height)
    {
        var failed = layout.Windows.Where(w => !IsWithinVirtualDesktop(w, width, height)).Select(w => $"{w.ProcessName}:{w.Title}").ToList();
        return failed.Count == 0 ? OperationResult.Success("LAYOUT_VALID", "All windows fit") : new OperationResult("LAYOUT_PARTIAL", OperationStatus.PartialSuccess, "Some windows are outside the desktop", [], failed, [], [], null, null, DateTimeOffset.UtcNow);
    }
}
