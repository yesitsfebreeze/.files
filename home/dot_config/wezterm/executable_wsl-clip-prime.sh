#!/usr/bin/env bash
# Bridge a Windows-clipboard image into the Wayland clipboard as PNG.
#
# WSLg mirrors a copied Windows image to the Wayland clipboard only as image/bmp,
# and Claude Code's paste accepts just png/jpeg/gif/webp -- so it grabs the bmp,
# fails to decode it, and reports "no image". WezTerm runs this right before it
# forwards Ctrl-V: if the clipboard holds an unconverted image, re-encode it to PNG
# with PowerShell and take over the Wayland selection, so Claude's first matching
# branch (wl-paste --type image/png) wins. Fast-paths out for text or already-PNG.
types=$(wl-paste -l 2>/dev/null || true)
case "$types" in
  *image/png*) exit 0 ;;   # already PNG (we primed it, or an app set one)
  *image/*) ;;             # some other image (bmp from WSLg) -> convert below
  *) exit 0 ;;             # no image on the clipboard -> text paste, nothing to do
esac

ps=$(command -v powershell.exe 2>/dev/null || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)
png=$(mktemp)
trap 'rm -f "$png"' EXIT
"$ps" -NoProfile -NonInteractive -Sta -Command 'Add-Type -AssemblyName System.Windows.Forms; $i=[System.Windows.Forms.Clipboard]::GetImage(); if($null -eq $i){exit 1}; $ms=New-Object System.IO.MemoryStream; $i.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png); [Convert]::ToBase64String($ms.ToArray())' 2>/dev/null | tr -d '\r' | base64 -d >"$png"
[ -s "$png" ] && wl-copy --type image/png <"$png"
