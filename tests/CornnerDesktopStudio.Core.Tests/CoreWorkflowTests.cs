using CornnerDesktopStudio.Contracts.Models;
using CornnerDesktopStudio.Contracts.Services;
using CornnerDesktopStudio.Core.Services;
using CornnerDesktopStudio.Infrastructure.Services;
using Xunit;

namespace CornnerDesktopStudio.Core.Tests;

public sealed class CoreWorkflowTests
{
    [Fact] public void Profile_validation_rejects_missing_name(){ var service = new ProfileService(new BackupService(new AppDataService(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString())))); var result = service.Validate(new DesktopProfile("id", "", false, false, false, false, "Static", "Work", null, [])); Assert.Equal(OperationStatus.Failed, result.Status); }
    [Fact] public void Profile_preview_contains_backup_status(){ var service = new ProfileService(new BackupService(new AppDataService(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString())))); var preview = service.Preview(service.GetDefaultProfiles()[0]); Assert.Contains(preview, p => p.BackupStatus.Contains("Backup", StringComparison.OrdinalIgnoreCase)); }
    [Fact] public async Task Backup_validation_detects_corruption(){ var backupService = new BackupService(new AppDataService(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString()))); var backup = await backupService.CreateAsync(AppSettings.Default(), [], CancellationToken.None); var result = await backupService.ValidateAsync(backup with { Hash = "BAD" }, CancellationToken.None); Assert.Equal(OperationStatus.Failed, result.Status); }
    [Fact] public async Task Apply_workflow_succeeds_after_backup(){ var service = new ProfileService(new BackupService(new AppDataService(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString())))); var result = await service.ApplyAsync(service.GetDefaultProfiles()[0], CancellationToken.None); Assert.Equal(OperationStatus.Success, result.Status); }
    [Fact] public void Window_bounds_validation_reports_partial_success(){ var service = new WindowLayoutService(); var layout = new WindowLayout("bad", "Bad", [new WindowSnapshot("p", "t", 1900, 1000, 500, 500, "Normal", "m")]); var result = service.ValidateRestore(layout, 1920, 1080); Assert.Equal(OperationStatus.PartialSuccess, result.Status); }
}
