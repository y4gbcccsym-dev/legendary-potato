using System.Windows.Input;
namespace CornnerPCRescue.Commands;
public sealed class AsyncRelayCommand(Func<CancellationToken, Task> execute, Func<bool>? canExecute = null) : ICommand
{
    bool _isRunning; public event EventHandler? CanExecuteChanged;
    public bool CanExecute(object? parameter) => !_isRunning && (canExecute?.Invoke() ?? true);
    public async void Execute(object? parameter){ if(!CanExecute(parameter)) return; _isRunning=true; Raise(); try{ await execute(CancellationToken.None); } finally{ _isRunning=false; Raise(); } }
    public void Raise()=>CanExecuteChanged?.Invoke(this,EventArgs.Empty);
}
