using System.Windows;
using CornnerPCRescue.Services;
using CornnerPCRescue.ViewModels;
using Microsoft.Extensions.DependencyInjection;

namespace CornnerPCRescue;

public partial class App : Application
{
    private ServiceProvider? _serviceProvider;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var services = new ServiceCollection();
        services
            .AddSingleton<ISettingsService, SettingsService>()
            .AddSingleton<ISystemInfoService, SystemInfoService>()
            .AddSingleton<IBackupService, BackupService>()
            .AddSingleton<IReportService, ReportService>()
            .AddSingleton<IMaintenanceService, MaintenanceService>()
            .AddSingleton<IFiveMService, FiveMService>()
            .AddSingleton<INetworkService, NetworkService>()
            .AddSingleton<MainViewModel>()
            .AddSingleton<MainWindow>();

        _serviceProvider = services.BuildServiceProvider();
        _serviceProvider.GetRequiredService<MainWindow>().Show();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _serviceProvider?.Dispose();
        base.OnExit(e);
    }
}
