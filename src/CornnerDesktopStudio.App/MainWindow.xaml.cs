using System.Windows;
using CornnerDesktopStudio.App.ViewModels;
using Microsoft.Extensions.DependencyInjection;

namespace CornnerDesktopStudio.App;
public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = App.Services.GetRequiredService<MainViewModel>();
    }
}
