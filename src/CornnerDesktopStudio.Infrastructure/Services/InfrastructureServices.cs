using CornnerDesktopStudio.Contracts.Models;
using CornnerDesktopStudio.Contracts.Services;

namespace CornnerDesktopStudio.Infrastructure.Services;

public sealed class AppDataService : IAppDataService
{
    public string RootPath { get; }
    public AppDataService(string? rootPath = null) => RootPath = rootPath ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CornnerDesktopStudio");
    public void EnsureFolders()
    {
        foreach (var folder in new[] { "Config", "Profiles", "Backups", "Logs", "Cache", "Wallpapers", "Exports" }) Directory.CreateDirectory(Path.Combine(RootPath, folder));
    }
}

public sealed class ShortcutService : IShortcutService
{
    public bool IsBrokenShortcut(string targetPath)
    {
        if (string.IsNullOrWhiteSpace(targetPath)) return true;
        if (Uri.TryCreate(targetPath, UriKind.Absolute, out var uri) && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)) return false;
        return !File.Exists(targetPath) && !Directory.Exists(targetPath);
    }
}

public sealed class WindowsCapabilityService : IWindowsCapabilityService
{
    public string WindowsVersion => Environment.OSVersion.VersionString;
    public bool SupportsTaskbarAlignment() => OperatingSystem.IsWindowsVersionAtLeast(10, 0, 22000);
    public bool SupportsWidgetsButton() => OperatingSystem.IsWindowsVersionAtLeast(10, 0, 22000);
}

public sealed class SafeWallpaperService
{
    static readonly HashSet<string> Supported = new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".mp4", ".webm" };
    public OperationResult ValidateWallpaper(string path)
    {
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path)) return OperationResult.Failed("WALLPAPER_MISSING", "Wallpaper file does not exist", [path]);
        return Supported.Contains(Path.GetExtension(path)) ? OperationResult.Success("WALLPAPER_SUPPORTED", "Wallpaper file is supported") : new OperationResult("WALLPAPER_UNSUPPORTED", OperationStatus.Unsupported, "Wallpaper format is unsupported", [], [], [path], [], null, null, DateTimeOffset.UtcNow);
    }
}
