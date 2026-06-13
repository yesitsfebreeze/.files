# Remote one-liner installer (Windows).
#
# Run straight from GitHub - clones ~\.files (or updates it if present),
# then runs bootstrap:
#     irm https://raw.githubusercontent.com/yesitsfebreeze/.files/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$Repo = 'https://github.com/yesitsfebreeze/.files.git'
$Dest = "$HOME\.files"

function Say { param($m) Write-Host "==> $m" -ForegroundColor Green }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required but was not found on PATH. Install git and re-run."
}

if (Test-Path "$Dest\.git") {
    Say "Updating existing checkout at $Dest"
    git -C $Dest pull --ff-only
}
else {
    if (Test-Path $Dest) {
        throw "$Dest exists but is not a git checkout. Move or remove it, then re-run."
    }
    Say "Cloning $Repo into $Dest"
    git clone $Repo $Dest
}

& "$Dest\bootstrap.ps1"
