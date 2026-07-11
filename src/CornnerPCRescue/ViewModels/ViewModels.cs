using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using CornnerPCRescue.Commands;
using CornnerPCRescue.Models;
using CornnerPCRescue.Services;
namespace CornnerPCRescue.ViewModels;
public abstract class ObservableObject:INotifyPropertyChanged{ public event PropertyChangedEventHandler? PropertyChanged; protected void Set<T>(ref T f,T v,[CallerMemberName]string? n=null){ if(!EqualityComparer<T>.Default.Equals(f,v)){f=v; PropertyChanged?.Invoke(this,new(n));}} protected void On([CallerMemberName]string? n=null)=>PropertyChanged?.Invoke(this,new(n)); }
public sealed class MainViewModel:ObservableObject
{
    readonly ISystemInfoService _system; readonly ISettingsService _settings; readonly IBackupService _backup; readonly IReportService _reports; readonly IMaintenanceService _maint; readonly IFiveMService _fivem; readonly INetworkService _network;
    string _page="Dashboard"; DashboardSnapshot? _dashboard; string _status="พร้อมใช้งาน"; MaintenancePreview? _preview; NetworkSnapshot? _networkSnapshot;
    public MainViewModel(ISystemInfoService system,ISettingsService settings,IBackupService backup,IReportService reports,IMaintenanceService maint,IFiveMService fivem,INetworkService network){_system=system;_settings=settings;_backup=backup;_reports=reports;_maint=maint;_fivem=fivem;_network=network; NavigateCommand=new AsyncRelayCommand(ct=>Task.CompletedTask); ScanCommand=new AsyncRelayCommand(ScanAsync); PreviewMaintenanceCommand=new AsyncRelayCommand(PreviewMaintenanceAsync); BackupCommand=new AsyncRelayCommand(BackupAsync); NetworkCommand=new AsyncRelayCommand(NetworkAsync); _=RefreshDashboardAsync(CancellationToken.None);}
    public string CurrentPage{get=>_page;set=>Set(ref _page,value);} public DashboardSnapshot? Dashboard{get=>_dashboard;set=>Set(ref _dashboard,value);} public string StatusText{get=>_status;set=>Set(ref _status,value);} public MaintenancePreview? CurrentPreview{get=>_preview;set=>Set(ref _preview,value);} public NetworkSnapshot? NetworkSnapshot{get=>_networkSnapshot;set=>Set(ref _networkSnapshot,value);} public ObservableCollection<ScanResult> ScanResults{get;}=[]; public ObservableCollection<ReportEntry> Reports{get;}=[];
    public bool IsPreviewMode{get=>_settings.Mode==ApplyMode.Preview; set{_settings.Mode=value?ApplyMode.Preview:ApplyMode.RealApply; On(); _=RefreshDashboardAsync(CancellationToken.None);}}
    public ICommand NavigateCommand{get;} public ICommand ScanCommand{get;} public ICommand PreviewMaintenanceCommand{get;} public ICommand BackupCommand{get;} public ICommand NetworkCommand{get;}
    public void Navigate(string page)=>CurrentPage=page;
    async Task RefreshDashboardAsync(CancellationToken ct){ Dashboard=await _system.GetDashboardAsync(_settings.Mode,ct); }
    async Task ScanAsync(CancellationToken ct){ CurrentPage="Scan PC"; ScanResults.Clear(); StatusText="กำลัง Scan..."; var progress=new Progress<ScanResult>(r=>ScanResults.Add(r)); var results=await _system.ScanAsync(_settings.Mode,progress,ct); foreach(var result in await _fivem.ScanAsync(ct)) ScanResults.Add(result); await _reports.AddAsync(new(DateTimeOffset.Now,OperationKind.Scan,"Scan PC",$"ตรวจ {results.Count} รายการ",Severity.Info),ct); await RefreshReports(ct); StatusText="Scan เสร็จแล้ว"; await RefreshDashboardAsync(ct); }
    async Task PreviewMaintenanceAsync(CancellationToken ct){ CurrentPage="Windows Maintenance"; CurrentPreview=await _maint.PreviewAsync(ct); StatusText="Preview พร้อมใช้งาน ยังไม่ Apply"; }
    async Task BackupAsync(CancellationToken ct){ CurrentPage="Backup & Restore"; var manifest=await _backup.CreateBackupAsync([],ct); var entry=new ReportEntry(DateTimeOffset.Now,OperationKind.Apply,"Backup",$"สร้าง Manifest {manifest.Id} ({manifest.Files.Count} files)",Severity.Info); await _reports.AddAsync(entry,ct); Reports.Add(entry); StatusText="Backup manifest ถูกสร้างแล้ว"; }
    async Task NetworkAsync(CancellationToken ct){ CurrentPage="Network"; NetworkSnapshot=await _network.GetSnapshotAsync(ct); }
    async Task RefreshReports(CancellationToken ct){ Reports.Clear(); foreach(var r in await _reports.ListAsync(ct)) Reports.Add(r); }
}
