# One-click dotfiles bootstrap (Windows).
#
# From a checkout of this repo:
#     ./setup/bootstrap.ps1
#
# Or one line (clones into ~\.dotfiles, then bootstraps):
#     git clone https://github.com/yesitsfebreeze/kern.git "$HOME\.dotfiles"; & "$HOME\.dotfiles\setup\bootstrap.ps1"
#
# Installs chezmoi (via winget/scoop), then applies the dotfiles, which in turn
# install every tool from setup/home/.chezmoidata/packages.yaml.
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
function Say { param($m) Write-Host "==> $m" -ForegroundColor Green }

# 1. Ensure chezmoi is installed.
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Say "Installing chezmoi via winget"
        winget install --id twpayne.chezmoi -e --silent `
            --accept-package-agreements --accept-source-agreements
    }
    elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Say "Installing chezmoi via scoop"
        scoop install chezmoi
    }
    else {
        $bin = "$env:LOCALAPPDATA\chezmoi"
        New-Item -ItemType Directory -Force -Path $bin | Out-Null
        Say "Installing chezmoi to $bin"
        & ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing 'https://get.chezmoi.io/ps1'))) -b $bin
        $env:Path = "$bin;$env:Path"
    }
}

$chezmoi = (Get-Command chezmoi -ErrorAction SilentlyContinue).Source
if (-not $chezmoi) { $chezmoi = "$env:LOCALAPPDATA\chezmoi\chezmoi.exe" }

# 2. Initialise + apply from this repo's setup/ directory.
Say "Applying dotfiles from $ScriptDir"
& $chezmoi init --apply --source $ScriptDir

Say "Done. Launch WezTerm to start a Nushell session."
Say "Re-sync any time with:  chezmoi apply"
