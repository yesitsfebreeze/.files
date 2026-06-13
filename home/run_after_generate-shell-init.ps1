# chezmoi run_after — regenerate the shell-integration files that Nushell sources.
# Runs on every `chezmoi apply`/`update` (the run_after_ prefix makes it run last,
# after the package installer), NEVER at shell start. config.nu only *sources*
# these files, so launching nu/WezTerm does zero setup work.
$ErrorActionPreference = 'Continue'

$h = $env:USERPROFILE

# Starship prompt init -> ~/.cache/starship/init.nu
$starshipInit = Join-Path $h '.cache\starship\init.nu'
New-Item -ItemType Directory -Force -Path (Split-Path $starshipInit) | Out-Null
if (Get-Command starship -ErrorAction SilentlyContinue) {
    starship init nu | Set-Content -Encoding utf8 -Path $starshipInit
}
# Guarantee the file exists (empty = harmless no-op) so `source` never fails.
if (-not (Test-Path $starshipInit)) { '' | Set-Content -Encoding utf8 -Path $starshipInit }

# Zoxide init -> ~/.zoxide.nu
$zoxideInit = Join-Path $h '.zoxide.nu'
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init nushell | Set-Content -Encoding utf8 -Path $zoxideInit
}
if (-not (Test-Path $zoxideInit)) { '' | Set-Content -Encoding utf8 -Path $zoxideInit }
