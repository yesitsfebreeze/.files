#!/usr/bin/env bash
# Mirror the Windows clipboard onto the Wayland clipboard, right before WezTerm
# forwards Ctrl-V to a WSL program (e.g. Claude Code).
#
# Why: WezTerm runs on Windows; Wispr and terminal copies land on the WINDOWS
# clipboard. Claude reads the WAYLAND clipboard (wl-paste). WSLg's auto-bridge is
# unreliable once anything calls wl-copy -- wl-copy then squats the Wayland
# selection, so newer Windows content (dictated text, a fresh copy) never crosses
# and Claude keeps pasting the stale buffer. So we don't trust Wayland: we read
# the Windows clipboard directly (the source of truth) and always overwrite
# Wayland to match -- image as PNG (Claude rejects WSLg's bmp), otherwise text.
ps=$(command -v powershell.exe 2>/dev/null || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)

resp=$("$ps" -NoProfile -NonInteractive -Sta -Command '
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
$cb=[System.Windows.Forms.Clipboard];
if($cb::ContainsImage()){
  $i=$cb::GetImage();
  if($i){
    $ms=New-Object System.IO.MemoryStream;
    $i.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png);
    "IMG " + [Convert]::ToBase64String($ms.ToArray());
  } else { "NONE" }
} elseif($cb::ContainsText()){
  $t=($cb::GetText()) -replace "\r","";
  "TXT " + [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($t));
} else { "NONE" }
' 2>/dev/null | tr -d '\r\n')

kind=${resp%% *}
data=${resp#* }
case "$kind" in
  IMG) printf '%s' "$data" | base64 -d | wl-copy --type image/png ;;
  TXT) printf '%s' "$data" | base64 -d | wl-copy ;;
  *)   : ;;  # empty Windows clipboard -> leave Wayland untouched
esac
