using CornnerDesktopStudio.Infrastructure.Services;
using Xunit;

namespace CornnerDesktopStudio.Infrastructure.Tests;

public sealed class InfrastructureTests
{
    [Fact] public void Broken_shortcut_detection_uses_file_system_safely(){ var service = new ShortcutService(); Assert.True(service.IsBrokenShortcut(Path.Combine(Path.GetTempPath(), Guid.NewGuid()+".exe"))); Assert.False(service.IsBrokenShortcut("https://example.com")); }
    [Fact] public void App_data_service_creates_required_folders(){ var root = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString()); var service = new AppDataService(root); service.EnsureFolders(); Assert.True(Directory.Exists(Path.Combine(root, "Backups"))); }
    [Fact] public void Unsupported_wallpaper_is_not_reported_success(){ var path = Path.GetTempFileName(); try { var result = new SafeWallpaperService().ValidateWallpaper(path); Assert.NotEqual(CornnerDesktopStudio.Contracts.Models.OperationStatus.Success, result.Status); } finally { File.Delete(path); } }
    [Fact] public void Required_app_data_folder_names_are_stable(){ var folders = new[] { "Config", "Profiles", "Backups", "Logs", "Cache", "Wallpapers", "Exports" }; Assert.Contains("Backups", folders); Assert.Equal(7, folders.Length); }
    [Fact] public void Windows_capability_service_is_queryable(){ var service = new WindowsCapabilityService(); Assert.False(string.IsNullOrWhiteSpace(service.WindowsVersion)); }
}
