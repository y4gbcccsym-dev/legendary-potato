using System.Collections.ObjectModel;
using System.Windows.Input;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CornnerDesktopStudio.Contracts.Models;
using CornnerDesktopStudio.Contracts.Services;

namespace CornnerDesktopStudio.App.ViewModels;

public sealed partial class MainViewModel : ObservableObject
{
    readonly IProfileService _profiles;
    readonly ILocalizationService _localization;
    [ObservableProperty] string selectedPage = "Dashboard";
    [ObservableProperty] string status = "Ready";
    public ObservableCollection<string> NavigationItems { get; }
    public ObservableCollection<DesktopProfile> Profiles { get; }
    public ObservableCollection<PreviewChange> PreviewItems { get; } = [];
    public ICommand NavigateCommand { get; }
    public IAsyncRelayCommand PreviewCommand { get; }
    public IAsyncRelayCommand ApplyCommand { get; }
    public ICommand RestoreCommand { get; }
    public MainViewModel(IProfileService profiles, ILocalizationService localization)
    {
        _profiles = profiles; _localization = localization;
        NavigationItems = new(["Dashboard","Desktop Profiles","Wallpaper","Widgets","App Dock","Window Layouts","Desktop Organizer","Taskbar","Startup","Backup & Restore","Activity Log","Settings"]);
        Profiles = new(_profiles.GetDefaultProfiles());
        NavigateCommand = new RelayCommand<string>(p => SelectedPage = p ?? "Dashboard");
        PreviewCommand = new AsyncRelayCommand(PreviewAsync);
        ApplyCommand = new AsyncRelayCommand(ApplyAsync);
        RestoreCommand = new RelayCommand(() => Status = _localization["Restore"] + ": Safe MVP restore preview only");
    }
    async Task PreviewAsync() { await Task.Yield(); PreviewItems.Clear(); foreach(var item in _profiles.Preview(Profiles.First())) PreviewItems.Add(item); Status = _localization["Preview"] + " completed"; }
    async Task ApplyAsync() { var result = await _profiles.ApplyAsync(Profiles.First(), CancellationToken.None); Status = $"{result.Status}: {result.Message}"; }
}
