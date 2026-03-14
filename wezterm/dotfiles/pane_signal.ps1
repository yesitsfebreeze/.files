<# .SYNOPSIS
  Emit a WezTerm user-var signal (OSC 1337 SetUserVar).
  Used by pane_mode.lua to wire fzf selections to side panes.
.EXAMPLE
  .\pane_signal.ps1 sel "path/to/file.txt"
#>
param(
  [Parameter(Mandatory)][string]$Name,
  [Parameter(Mandatory)][string]$Value
)
$b = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value))
[Console]::Write("$([char]27)]1337;SetUserVar=$Name=$b$([char]7)")
