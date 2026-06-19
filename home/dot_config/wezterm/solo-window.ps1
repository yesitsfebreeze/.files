# Solo the terminal on Windows: minimize every top-level window EXCEPT those that
# belong to WezTerm, then force WezTerm back to the foreground. The keybinding
# fires while WezTerm is focused, so GetForegroundWindow() is a WezTerm window and
# its process id identifies every window we must leave alone. Launched hidden by
# solo-window.vbs (no console flash).
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@

$SW_MINIMIZE = 6
$SW_RESTORE = 9

$fg = [Win]::GetForegroundWindow()
$wtPid = 0
$fgThread = [Win]::GetWindowThreadProcessId($fg, [ref]$wtPid)   # WezTerm's thread + pid

$cb = [Win+EnumProc]{
    param($h, $l)
    $p = 0
    [void][Win]::GetWindowThreadProcessId($h, [ref]$p)
    # Skip anything WezTerm owns (so we never minimize the terminal itself, incl.
    # any secondary/owned window), plus the title-less helper windows the desktop
    # keeps around. Visible + titled + foreign process ≈ a real other app.
    if ($p -ne $wtPid -and [Win]::IsWindowVisible($h) -and [Win]::GetWindowTextLength($h) -gt 0) {
        [Win]::ShowWindow($h, $SW_MINIMIZE) | Out-Null
    }
    return $true
}
[Win]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null

# Minimizing the others can hand foreground to the desktop, so pull WezTerm back.
# SetForegroundWindow is refused for a background process unless we briefly attach
# our input thread to the target window's thread — the canonical unlock trick.
$cur = [Win]::GetCurrentThreadId()
[void][Win]::AttachThreadInput($cur, $fgThread, $true)
[void][Win]::ShowWindow($fg, $SW_RESTORE)
[void][Win]::SetForegroundWindow($fg)
[void][Win]::AttachThreadInput($cur, $fgThread, $false)
