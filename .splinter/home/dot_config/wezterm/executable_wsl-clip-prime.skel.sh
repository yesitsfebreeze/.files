# §source home/dot_config/wezterm/executable_wsl-clip-prime.sh
#!/usr/bin/env bash
# Put any Windows-clipboard image onto the Wayland clipboard as PNG, so Claude Code's
# `wl-paste --type image/png` branch finds it. WSLg bridges a copied Windows image to
# Wayland only as image/bmp, which Claude rejects; and once wl-copy squats the Wayland
# selection the auto-bridge stalls. So we read the WINDOWS clipboard directly (the source
# of truth) every time and overwrite Wayland to match.
#
# wezterm's Ctrl-Shift-V runs this, then forwards Ctrl-V so Claude runs its image probe.
# Text paste does NOT come through here -- plain Ctrl-V pastes it natively (bracketed
# paste), which is fast and is also how Wispr dictation lands.
ps=$(command -v powershell.exe 2>/dev/null || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)
png=$(mktemp)
trap 'rm -f "$png"' EXIT
"$ps" -NoProfile -NonInteractive -Sta -Command '
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
$i=[System.Windows.Forms.Clipboard]::GetImage();
if($null -eq $i){ exit 1 }
$ms=New-Object System.IO.MemoryStream;
$i.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png);
[Convert]::ToBase64String($ms.ToArray());
' 2>/dev/null | tr -d '\r\n' | base64 -d >"$png"
[ -s "$png" ] && wl-copy --type image/png <"$png"
