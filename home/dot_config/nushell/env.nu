# env.nu — evaluated before config.nu, launched explicitly by WezTerm so this is
# the single env file used on every OS.

# PATH <-> list conversions — required because we override the stock env.nu.
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

$env.PATH = (
    $env.PATH
    | prepend ($nu.home-dir | path join ".local" "bin")
    | prepend ($nu.home-dir | path join ".cargo" "bin")
    | uniq
)

$env.XDG_CONFIG_HOME = ($nu.home-dir | path join ".config")
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_SHELL = "nu"

# Advertise Nushell as $SHELL. The login shell in /etc/passwd is still zsh, but
# every child that spawns "the user's shell" should get nu. This is now a fallback,
# not the primary path: config.nu launches burrito as a child of nu (no `exec`), so
# burrito's parent-tree walk finds nu directly and cells launch nu without touching
# $SHELL. We keep this so that if burrito (or anything else) ever does fall back to
# $SHELL, it lands on nu rather than zsh.
$env.SHELL = $nu.current-exe

# `pass` (password-store): pin the store location to its default explicitly so the
# Nushell completion (config sources pass.nu) and the apply-time setup check both
# read the same path. Change this to relocate the store.
$env.PASSWORD_STORE_DIR = ($nu.home-dir | path join ".password-store")

# Shell integrations are generated at apply time by the chezmoi run_after script,
# not here, and merely sourced by config.nu — so shell launch does zero work.
