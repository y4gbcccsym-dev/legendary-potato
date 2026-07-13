using System.Windows;
using CornnerDesktopStudio.App.Services;
using CornnerDesktopStudio.App.ViewModels;
using CornnerDesktopStudio.Contracts.Services;
using CornnerDesktopStudio.Core.Services;
using CornnerDesktopStudio.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CornnerDesktopStudio.App;

public partial class App : Application
{
    public static IServiceProvider Services { get; private set; } = null!;
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddSingleton<IAppDataService, AppDataService>();
        services.AddSingleton<IBackupService, BackupService>();
        services.AddSingleton<IProfileService, ProfileService>();
        services.AddSingleton<ILocalizationService, LocalizationService>();
        services.AddSingleton<IShortcutService, ShortcutService>();
        services.AddSingleton<IWindowLayoutService, WindowLayoutService>();
        services.AddSingleton<IWindowsCapabilityService, WindowsCapabilityService>();
        services.AddSingleton<MainViewModel>();
        Services = services.BuildServiceProvider();
        AppDomain.CurrentDomain.UnhandledException += (_, args) => System.Diagnostics.Debug.WriteLine(args.ExceptionObject);
        DispatcherUnhandledException += (_, args) => { System.Diagnostics.Debug.WriteLine(args.Exception); args.Handled = true; };
    }
}
