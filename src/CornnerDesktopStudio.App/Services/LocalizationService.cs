using CornnerDesktopStudio.Contracts.Services;

namespace CornnerDesktopStudio.App.Services;

public sealed class LocalizationService : ILocalizationService
{
    readonly Dictionary<string, Dictionary<string,string>> _resources = new()
    {
        ["en-US"] = new() { ["AppTitle"]="Cornner Desktop Studio", ["Dashboard"]="Dashboard", ["Profiles"]="Desktop Profiles", ["Wallpaper"]="Wallpaper", ["Widgets"]="Widgets", ["Dock"]="App Dock", ["Layouts"]="Window Layouts", ["Organizer"]="Desktop Organizer", ["Taskbar"]="Taskbar", ["Startup"]="Startup", ["Backup"]="Backup & Restore", ["Log"]="Activity Log", ["Settings"]="Settings", ["Preview"]="Preview Changes", ["Apply"]="Apply Profile", ["Restore"]="Restore Last Backup" },
        ["th-TH"] = new() { ["AppTitle"]="Cornner Desktop Studio", ["Dashboard"]="แดชบอร์ด", ["Profiles"]="โปรไฟล์เดสก์ท็อป", ["Wallpaper"]="วอลเปเปอร์", ["Widgets"]="วิดเจ็ต", ["Dock"]="แอปด็อก", ["Layouts"]="เลย์เอาต์หน้าต่าง", ["Organizer"]="จัดระเบียบเดสก์ท็อป", ["Taskbar"]="ทาสก์บาร์", ["Startup"]="เริ่มพร้อม Windows", ["Backup"]="สำรองและกู้คืน", ["Log"]="บันทึกกิจกรรม", ["Settings"]="ตั้งค่า", ["Preview"]="ดูตัวอย่างการเปลี่ยนแปลง", ["Apply"]="ใช้โปรไฟล์", ["Restore"]="กู้คืนสำรองล่าสุด" }
    };
    public string CurrentLanguage { get; } = Thread.CurrentThread.CurrentUICulture.Name.StartsWith("th", StringComparison.OrdinalIgnoreCase) ? "th-TH" : "en-US";
    public string this[string key] => _resources[CurrentLanguage].TryGetValue(key, out var value) ? value : key;
    public IReadOnlyDictionary<string,string> GetLanguage(string language) => _resources[language];
    public IReadOnlyList<string> ValidateCompleteness()
    {
        var keys = _resources.Values.SelectMany(d => d.Keys).Distinct().ToArray();
        return _resources.SelectMany(lang => keys.Where(k => !lang.Value.ContainsKey(k)).Select(k => $"{lang.Key}:{k}")).ToArray();
    }
}
