' Hidden launcher for solo-window.ps1. WezTerm spawns this via wscript (a GUI
' host with no console), and we run PowerShell with window style 0 (hidden), so
' the minimize-others pass happens with zero visible flash. The .ps1 sits beside
' this file; derive its path from our own so it works wherever chezmoi deploys.
Dim sh, ps1
Set sh = CreateObject("WScript.Shell")
ps1 = Replace(WScript.ScriptFullName, "solo-window.vbs", "solo-window.ps1")
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -File """ & ps1 & """", 0, False
