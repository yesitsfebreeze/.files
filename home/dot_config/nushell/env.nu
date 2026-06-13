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
    | prepend ($nu.home-path | path join ".local" "bin")
    | prepend ($nu.home-path | path join ".cargo" "bin")
    | uniq
)

# --- Standard env ---
$env.XDG_CONFIG_HOME = ($nu.home-path | path join ".config")
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_SHELL = "nu"

# --- Generate shell integrations (idempotent; sourced from config.nu) ---
# Wrapped so a not-yet-installed tool on first launch cannot break the shell.
let starship_init = ($nu.home-path | path join ".cache" "starship" "init.nu")
mkdir ($starship_init | path dirname)
try { ^starship init nu | save -f $starship_init } catch { }
if not ($starship_init | path exists) { "" | save -f $starship_init }

let zoxide_init = ($nu.home-path | path join ".zoxide.nu")
try { ^zoxide init nushell | save -f $zoxide_init } catch { }
if not ($zoxide_init | path exists) { "" | save -f $zoxide_init }
