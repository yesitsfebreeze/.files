# env.nu — evaluated before config.nu.
# Launched explicitly by WezTerm via:  nu --env-config ~/.config/nushell/env.nu
# so this is the single env file used on every OS.

# --- PATH <-> list conversions (must be present since we override the stock env.nu) ---
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
        to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
        to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# --- PATH additions (cross-platform) ---
$env.PATH = (
    $env.PATH
    | prepend ($nu.home-dir | path join ".local" "bin")
    | prepend ($nu.home-dir | path join ".cargo" "bin")
    | uniq
)

# --- Standard env ---
$env.XDG_CONFIG_HOME = ($nu.home-dir | path join ".config")
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_SHELL = "nu"

# --- Shell integrations are GENERATED AT APPLY TIME, not here. ---
# Starting a shell must never run setup/install work. The starship and zoxide
# init files are written by the chezmoi run_after script
# `run_after_generate-shell-init.{sh,ps1}` on every `chezmoi apply`/`update`,
# and merely *sourced* by config.nu. So nu/WezTerm launch does zero work.
