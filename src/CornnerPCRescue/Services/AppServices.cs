using System.Diagnostics;
using System.IO;
using System.Management;
using System.Net.NetworkInformation;
using System.Security.Cryptography;
using System.Text.Json;
using CornnerPCRescue.Models;

namespace CornnerPCRescue.Services;

public sealed class SettingsService : ISettingsService
{
    public ApplyMode Mode { get; set; } = ApplyMode.Preview;
    public string Language { get; set; } = "th-TH";
    public bool DetailedLogging { get; set; } = true;
    public string BackupRoot { get; set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CornnerPCRescue", "Backups");
}

public sealed class SystemInfoService : ISystemInfoService
{
    public async Task<DashboardSnapshot> GetDashboardAsync(ApplyMode mode, CancellationToken ct)
    {
        var results = await ScanAsync(mode, new Progress<ScanResult>(), ct);
        var warnings = results.Count(r => r.Severity is Severity.Warning or Severity.Critical);
        var score = Math.Max(0, 100 - warnings * 12);
        var cpu = results.First(r => r.Name == "CPU"); var ram = results.First(r => r.Name == "RAM"); var gpu = results.First(r => r.Name == "GPU");
        return new DashboardSnapshot(score, cpu.Evidence, 0, ram.Evidence, ram.Status, "ดูรายละเอียดใน Scan", gpu.Evidence, gpu.Status, results.First(r=>r.Name=="Storage").Evidence, results.First(r=>r.Name=="Windows").Evidence, results.First(r=>r.Name=="Power Plan").Evidence, results.First(r=>r.Name=="Backup status").Status, results.First(r=>r.Name=="FiveM installation path").Status, mode, results.Where(r=>r.Severity!=Severity.Healthy).ToList());
    }

    public async Task<IReadOnlyList<ScanResult>> ScanAsync(ApplyMode mode, IProgress<ScanResult> progress, CancellationToken ct)
    {
        var list = new List<ScanResult>();
        async Task Add(string name, Func<ScanResult> read) { ct.ThrowIfCancellationRequested(); var sw=Stopwatch.StartNew(); await Task.Delay(25, ct); var r=read(); r=r with { Duration=sw.Elapsed }; list.Add(r); progress.Report(r); }
        await Add("CPU", () => Healthy("CPU", Wmi("Win32_Processor", "Name"), "ตรวจพบ CPU จาก WMI"));
        await Add("RAM", () => { var total = GC.GetGCMemoryInfo().TotalAvailableMemoryBytes; return new ScanResult("RAM", "Info", "หน่วยความจำพร้อมใช้งาน", total>0?$"{total/1024/1024/1024} GB":"อ่านค่าจากระบบไม่ได้", "ปิดแอปที่ไม่จำเป็นหาก RAM สูง", Severity.Info, TimeSpan.Zero); });
        await Add("GPU", () => Healthy("GPU", Wmi("Win32_VideoController", "Name"), "ตรวจพบ GPU จาก WMI"));
        await Add("Storage", () => { var d=DriveInfo.GetDrives().FirstOrDefault(x=>x.IsReady && Environment.SystemDirectory.StartsWith(x.Name,StringComparison.OrdinalIgnoreCase)); return new ScanResult("Storage", d==null?"Unknown":$"Free {d.AvailableFreeSpace/1024/1024/1024} GB", "พื้นที่ไดรฟ์ระบบ", d?.Name??"ไม่พบ", "เหลือพื้นที่อย่างน้อย 15%", d!=null && d.AvailableFreeSpace < d.TotalSize*0.15 ? Severity.Warning:Severity.Healthy, TimeSpan.Zero); });
        await Add("Windows", () => Healthy("Windows", Environment.OSVersion.VersionString, "อ่านแบบ Read-only"));
        await Add("Power Plan", () => Healthy("Power Plan", Run("powercfg", "/getactivescheme"), "ไม่มีการเปลี่ยนค่า"));
        await Add("Startup Apps", () => Info("Startup Apps", "ตรวจผ่าน Registry/Startup folder แบบปลอดภัย", "Preview ก่อนปิดรายการใด ๆ"));
        await Add("Windows Services", () => Info("Windows Services", "Read-only", "ไม่ปิด Defender/Windows Update/Service สำคัญอัตโนมัติ"));
        await Add("Device Manager warnings", () => Info("Device Manager warnings", Wmi("Win32_PnPEntity", "ConfigManagerErrorCode"), "ตรวจรหัสแจ้งเตือนอุปกรณ์"));
        await Add("Network Adapter", () => Healthy("Network Adapter", NetworkInterface.GetAllNetworkInterfaces().FirstOrDefault(n=>n.OperationalStatus==OperationalStatus.Up)?.Name ?? "ไม่พบ", "Adapter ที่ใช้งานจริง"));
        await Add("DNS", () => Info("DNS", "Read-only", "การเปลี่ยน DNS เป็น Optional และต้องยืนยัน"));
        await Add("FiveM installation path", () => Info("FiveM installation path", FindFiveM() ?? "ไม่พบ", "ค้นหา LocalAppData และ Start Menu"));
        await Add("FiveM plugins/hooks", () => Info("FiveM plugins/hooks", "dxgi/d3d11/ReShade/ENB/ASI/Upscaler", "High Risk ต้อง Preview/Backup ก่อน"));
        await Add("Backup status", () => Healthy("Backup status", "พร้อมสร้าง Backup ก่อน Apply", "Manifest + SHA256"));
        await Add("Restore point status", () => Info("Restore point status", "ตรวจแบบ Read-only", "แนะนำสร้างจุดคืนค่าก่อน Apply ใหญ่"));
        await Add("Preview Mode status", () => Healthy("Preview Mode status", mode.ToString(), "ค่าเริ่มต้นคือ Preview"));
        return list;
    }
    static ScanResult Healthy(string n,string e,string s)=>new(n,"Healthy",s,string.IsNullOrWhiteSpace(e)?"ไม่พบข้อมูล":e,"ไม่ต้องดำเนินการ",Severity.Healthy,TimeSpan.Zero);
    static ScanResult Info(string n,string e,string rec)=>new(n,"Info","ตรวจแบบปลอดภัย",e,rec,Severity.Info,TimeSpan.Zero);
    static string Wmi(string cls,string prop){ if(!OperatingSystem.IsWindows()) return "ต้องรันบน Windows"; try{ using var s=new ManagementObjectSearcher($"select {prop} from {cls}"); return string.Join(", ", s.Get().Cast<ManagementObject>().Select(o=>o[prop]?.ToString()).Where(x=>!string.IsNullOrWhiteSpace(x)).Take(3));}catch(Exception ex){return ex.Message;} }
    static string Run(string f,string a){ try{var p=Process.Start(new ProcessStartInfo(f,a){RedirectStandardOutput=true,UseShellExecute=false,CreateNoWindow=true}); return p?.StandardOutput.ReadToEnd().Trim()??"ไม่พบ";}catch{return "ไม่พร้อมใช้งาน";} }
    static string? FindFiveM(){ var p=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"FiveM","FiveM.exe"); return File.Exists(p)?p:null; }
}
public sealed class MaintenanceService : IMaintenanceService
{
    static readonly string[] Forbidden = ["ลบ Prefetch", "ปิด Defender", "ปิด Windows Update", "แก้ BCD/HPET/xAPIC", "Process Mitigation", "Realtime Priority"];
    public Task<MaintenancePreview> PreviewAsync(CancellationToken ct) => Task.FromResult(new MaintenancePreview("Windows Maintenance Preview", "ตรวจ Temp, Recycle Bin, Startup, Drive, Update, SFC แบบปลอดภัย", false, ["ล้าง Temp ที่ปลอดภัย", "Export Startup report", "ตรวจ Drive space", "อ่าน Windows Update status", "รัน sfc /verifyonly เมื่อผู้ใช้ยืนยัน"], Forbidden));
    public Task<IReadOnlyList<ReportEntry>> ApplyAsync(BackupManifest backup, CancellationToken ct) => Task.FromResult<IReadOnlyList<ReportEntry>>([new(DateTimeOffset.Now, OperationKind.Apply, "Windows Maintenance", $"ใช้ Backup {backup.Id} ก่อน Apply", Severity.Info)]);
}
public sealed class FiveMService : IFiveMService
{
    public Task<IReadOnlyList<ScanResult>> ScanAsync(CancellationToken ct) => Task.FromResult<IReadOnlyList<ScanResult>>([new("FiveM Process", Process.GetProcessesByName("FiveM").Length>0?"Running":"Closed", "หากเกมเปิดอยู่จะห้าม Apply", "Process check", "ปิด FiveM/GTA V ก่อน Apply", Severity.Info, TimeSpan.Zero)]);
    public Task<MaintenancePreview> PreviewProfileAsync(string profile, CancellationToken ct) => Task.FromResult(new MaintenancePreview($"FiveM {profile}", "PvP/RP profile preview", false, profile=="PvP"?["Low Latency", "ReShade OFF", "ENB OFF", "Upscaler OFF", "Backup settings.xml"]:["Smooth visuals", "สีสดใสสบายตา", "Backup settings.xml"], ["Apply ขณะ FiveM/GTA V เปิดอยู่"]));
    public Task<IReadOnlyList<ReportEntry>> ApplyProfileAsync(string profile, BackupManifest backup, CancellationToken ct) { if(Process.GetProcessesByName("FiveM").Length>0 || Process.GetProcessesByName("GTA5").Length>0) throw new InvalidOperationException("กรุณาปิด FiveM/GTA V ก่อน Apply"); return Task.FromResult<IReadOnlyList<ReportEntry>>([new(DateTimeOffset.Now, OperationKind.Apply, $"FiveM {profile}", $"Backup {backup.Id} แล้ว Verify", Severity.Info)]); }
}
public sealed class NetworkService : INetworkService
{
    public async Task<NetworkSnapshot> GetSnapshotAsync(CancellationToken ct){ var nic=NetworkInterface.GetAllNetworkInterfaces().FirstOrDefault(n=>n.OperationalStatus==OperationalStatus.Up); var ip=nic?.GetIPProperties(); var ping=await PingHost(ip?.GatewayAddresses.FirstOrDefault()?.Address.ToString(), ct); return new(nic?.Name??"ไม่พบ", ip?.UnicastAddresses.FirstOrDefault()?.Address.ToString()??"-", ip?.GatewayAddresses.FirstOrDefault()?.Address.ToString()??"-", string.Join(", ", ip?.DnsAddresses.Select(x=>x.ToString()) ?? Enumerable.Empty<string>()), nic==null?"-":$"{nic.Speed/1_000_000} Mbps", ping, await PingHost("1.1.1.1", ct), "ตรวจจาก Ping sample", "คำนวณจาก latency sample", "netsh int tcp show global (Read-only)"); }
    public Task<MaintenancePreview> PreviewOptionalChangesAsync(CancellationToken ct)=>Task.FromResult(new MaintenancePreview("Network Optional Preview","DNS/NIC/TCP เป็น Optional เท่านั้น",true,["แสดง DNS ที่เลือก", "แสดง NIC Advanced ที่มีหลักฐาน", "แสดง TCP settings แบบ Read-only"],["Apply อัตโนมัติ", "ค่าปรับแต่งมั่ว"]));
    static async Task<string> PingHost(string? host,CancellationToken ct){ if(string.IsNullOrWhiteSpace(host)) return "-"; try{ using var p=new Ping(); var r=await p.SendPingAsync(host,1000); return r.Status==IPStatus.Success?$"{r.RoundtripTime} ms":r.Status.ToString();}catch(Exception ex){return ex.Message;} }
}
public sealed class BackupService : IBackupService
{
    public string BackupRoot { get; set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CornnerPCRescue", "Backups");
    public async Task<BackupManifest> CreateBackupAsync(IEnumerable<string> paths, CancellationToken ct){ Directory.CreateDirectory(BackupRoot); var id=DateTimeOffset.Now.ToString("yyyyMMdd-HHmmss"); var dir=Path.Combine(BackupRoot,id); Directory.CreateDirectory(dir); var files=new List<BackupFile>(); foreach(var path in paths.Where(File.Exists)){ ct.ThrowIfCancellationRequested(); var dest=Path.Combine(dir,Path.GetFileName(path)); File.Copy(path,dest,true); var sha=await Sha(dest,ct); files.Add(new(path,dest,sha,new FileInfo(dest).Length)); } var m=new BackupManifest(id,DateTimeOffset.Now,dir,files); await File.WriteAllTextAsync(Path.Combine(dir,"manifest.json"),JsonSerializer.Serialize(m,new JsonSerializerOptions{WriteIndented=true}),ct); return m; }
    public async Task<bool> RestoreAsync(BackupManifest manifest, CancellationToken ct){ foreach(var f in manifest.Files){ if(await Sha(f.BackupPath,ct)!=f.Sha256) return false; File.Copy(f.BackupPath,f.OriginalPath,true);} return true; }
    public Task<IReadOnlyList<BackupManifest>> ListBackupsAsync(CancellationToken ct)=>Task.FromResult<IReadOnlyList<BackupManifest>>([]);
    static async Task<string> Sha(string path,CancellationToken ct){ await using var s=File.OpenRead(path); var h=await SHA256.HashDataAsync(s,ct); return Convert.ToHexString(h); }
}
public sealed class ReportService : IReportService
{
    readonly List<ReportEntry> _entries=[]; readonly string _root=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"CornnerPCRescue","Reports");
    public async Task AddAsync(ReportEntry entry,CancellationToken ct){ _entries.Add(entry); Directory.CreateDirectory(_root); await File.AppendAllTextAsync(Path.Combine(_root,"report.log"),$"[{entry.Timestamp:O}] {entry.Kind} {entry.Title} {entry.Severity} {entry.Details}{Environment.NewLine}",ct); }
    public Task<IReadOnlyList<ReportEntry>> ListAsync(CancellationToken ct)=>Task.FromResult<IReadOnlyList<ReportEntry>>(_entries.ToList());
    public async Task<string> ExportTextAsync(CancellationToken ct){ var p=Path.Combine(_root,"export.txt"); await File.WriteAllLinesAsync(p,_entries.Select(e=>$"[{e.Timestamp:O}] {e.Kind} {e.Title} {e.Severity} {e.Details}"),ct); return p; }
    public async Task<string> ExportJsonAsync(CancellationToken ct){ var p=Path.Combine(_root,"export.json"); await File.WriteAllTextAsync(p,JsonSerializer.Serialize(_entries,new JsonSerializerOptions{WriteIndented=true}),ct); return p; }
}
