# Solo the terminal on Windows: minimize every top-level window except the one
# in the foreground. The WezTerm keybinding fires only while WezTerm is focused,
# so the foreground window IS WezTerm — it stays put while everything else drops
# to the taskbar. Launched hidden by solo-window.vbs (no console flash).
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@

$fg = [Win]::GetForegroundWindow()
$SW_MINIMIZE = 6
$cb = [Win+EnumProc]{
    param($h, $l)
    # Skip the foreground window (WezTerm), invisible windows, and the legion of
    # title-less helper/tool windows the desktop keeps around — minimizing those
    # does nothing useful and can disturb the shell. Visible + titled ≈ real apps.
    if ($h -ne $fg -and [Win]::IsWindowVisible($h) -and [Win]::GetWindowTextLength($h) -gt 0) {
        [Win]::ShowWindow($h, $SW_MINIMIZE) | Out-Null
    }
    return $true
}
[Win]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
