using System.Windows; using CornnerPCRescue.ViewModels;
namespace CornnerPCRescue;
public partial class MainWindow:Window{ readonly MainViewModel _vm; public MainWindow(MainViewModel vm){InitializeComponent(); _vm=vm; DataContext=vm;} void Nav_Click(object sender,RoutedEventArgs e){ if(sender is System.Windows.Controls.Button b && b.Content is string page) _vm.Navigate(page); }}
