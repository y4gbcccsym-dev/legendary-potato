using CornnerPCRescue.Models;
using CornnerPCRescue.Services;

namespace CornnerPCRescue.Tests;

public sealed class SafetyTests
{
    [Fact]
    public async Task MaintenancePreviewContainsForbiddenUnsafeActions()
    {
        var preview = await new MaintenanceService().PreviewAsync(CancellationToken.None);
        Assert.Contains(preview.ForbiddenActions, x => x.Contains("Prefetch", StringComparison.OrdinalIgnoreCase));
        Assert.Contains(preview.ForbiddenActions, x => x.Contains("Defender", StringComparison.OrdinalIgnoreCase));
        Assert.DoesNotContain(preview.Actions, x => x.Contains("Prefetch", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task BackupRestoreVerifiesSha256()
    {
        var root = Path.Combine(Path.GetTempPath(), "CornnerPCRescueTests", Guid.NewGuid().ToString("N"));
        var source = Path.Combine(root, "settings.xml");
        Directory.CreateDirectory(root);
        await File.WriteAllTextAsync(source, "safe-settings");
        var service = new BackupService { BackupRoot = Path.Combine(root, "backups") };
        var manifest = await service.CreateBackupAsync([source], CancellationToken.None);
        await File.WriteAllTextAsync(source, "changed");
        Assert.True(await service.RestoreAsync(manifest, CancellationToken.None));
        Assert.Equal("safe-settings", await File.ReadAllTextAsync(source));
    }

    [Fact]
    public void SettingsDefaultToPreviewMode()
    {
        Assert.Equal(ApplyMode.Preview, new SettingsService().Mode);
    }
}
