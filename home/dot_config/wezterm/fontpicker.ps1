# WezTerm Nerd-Font picker helper (Windows).
#
# RUNTIME USER STATE -- not provisioning. packages.yaml still owns the guaranteed
# default font (JetBrainsMono Nerd Font); this script installs *extra* Nerd Fonts
# the user picks interactively via CTRL+SHIFT+F. Fonts installed here are
# deliberately outside the package manifest (project-law #1 boundary).
#
# Modes:
#   fontpicker.ps1                 -> open the fzf picker (spawned by wezterm)
#   fontpicker.ps1 -Install NAME   -> debounced download+install of a hovered font
#                                     (invoked by fzf's `focus` bind)
#
# Install path: %LOCALAPPDATA%\Microsoft\Windows\Fonts + a per-user HKCU registry
# entry (no admin required, Windows 10 1809+). State files mirror the sh helper.

param([string]$Install)

$ErrorActionPreference = 'SilentlyContinue'

$WZ = Join-Path $env:USERPROFILE '.config\wezterm'
$Installed = Join-Path $WZ 'installed'
New-Item -ItemType Directory -Force -Path $Installed | Out-Null

$FontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
New-Item -ItemType Directory -Force -Path $FontDir | Out-Null
$RegKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

$ApiUrl = 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest'
$DlBase = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download'

function Write-NoBom([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text)
}

function Install-Font([string]$Name) {
    if (-not $Name) { return $false }
    $marker = Join-Path $Installed $Name
    if (Test-Path $marker) { return $true }

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("nf_" + $Name)
    $zip = "$tmp.zip"
    Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
    try {
        Invoke-WebRequest -Uri "$DlBase/$Name.zip" -OutFile $zip -UseBasicParsing
    } catch { return $false }
    if (-not (Test-Path $zip)) { return $false }

    try {
        Expand-Archive -Path $zip -DestinationPath $tmp -Force
    } catch { Remove-Item -Force $zip -ErrorAction SilentlyContinue; return $false }

    $ttfs = Get-ChildItem -Path $tmp -Recurse -Filter '*.ttf' -ErrorAction SilentlyContinue
    $found = $false
    foreach ($f in $ttfs) {
        $dest = Join-Path $FontDir $f.Name
        Copy-Item -Path $f.FullName -Destination $dest -Force
        if (Test-Path $dest) {
            $found = $true
            $regName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name) + ' (TrueType)'
            New-ItemProperty -Path $RegKey -Name $regName -Value $dest -PropertyType String -Force | Out-Null
        }
    }
    Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
    if (-not $found) { return $false }
    New-Item -ItemType File -Force -Path $marker | Out-Null
    return $true
}

# --- mode: -Install NAME (debounced, called from fzf focus) --------------------
if ($Install) {
    $req = Join-Path $WZ 'preview-request.txt'
    Write-NoBom $req $Install
    Start-Sleep -Milliseconds 400
    if ((Get-Content -Raw $req -ErrorAction SilentlyContinue) -ne $Install) { return }

    if (Install-Font $Install) {
        Write-NoBom (Join-Path $WZ 'preview-font.txt') "$Install Nerd Font"
    }
    return
}

# --- mode: open the picker -----------------------------------------------------
$catalog = Join-Path $WZ 'font-catalog.txt'
$needFetch = $true
if (Test-Path $catalog) {
    $item = Get-Item $catalog
    if ($item.Length -gt 0 -and $item.LastWriteTime -gt (Get-Date).AddDays(-1)) {
        $needFetch = $false
    }
}
if ($needFetch) {
    try {
        $rel = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing -Headers @{ 'User-Agent' = 'wezterm-fontpicker' }
        $names = $rel.assets.name |
            Where-Object { $_ -like '*.zip' -and $_ -notlike '*FontPatcher*' } |
            ForEach-Object { $_ -replace '\.zip$', '' } |
            Sort-Object -Unique
        if ($names) { Write-NoBom $catalog (($names -join "`n") + "`n") }
    } catch { }
}

if (-not (Test-Path $catalog) -or (Get-Item $catalog).Length -eq 0) {
    Write-Host 'Could not fetch the Nerd Fonts catalog (offline and no cache).'
    Write-Host 'Press Enter to close.'
    [void](Read-Host)
    Write-NoBom (Join-Path $WZ 'picker-closed.txt') 'REVERT'
    exit 1
}

Remove-Item -Force (Join-Path $WZ 'preview-font.txt'), (Join-Path $WZ 'preview-request.txt'), (Join-Path $WZ 'picker-closed.txt') -ErrorAction SilentlyContinue

$self = $PSCommandPath
$header = 'Enter: keep   Esc: revert   |   hover to preview (downloads on hover)'
$bind = "focus:execute-silent(pwsh -NoProfile -File `"$self`" -Install {})"

$sel = Get-Content $catalog | fzf --prompt 'Nerd Font> ' --header $header --height 100% --layout reverse --bind $bind

if ($sel) {
    Install-Font $sel | Out-Null
    Write-NoBom (Join-Path $WZ 'active-font.txt')  "$sel Nerd Font"
    Write-NoBom (Join-Path $WZ 'preview-font.txt') "$sel Nerd Font"
    Write-NoBom (Join-Path $WZ 'picker-closed.txt') 'KEEP'
} else {
    Write-NoBom (Join-Path $WZ 'picker-closed.txt') 'REVERT'
}

Remove-Item -Force (Join-Path $WZ 'preview-request.txt') -ErrorAction SilentlyContinue
