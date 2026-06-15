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
# every child that spawns "the user's shell" should get nu. burrito relies on this:
# it has no shell config key and picks each cell's shell by walking its parent
# process tree for a known shell — but config.nu `exec`s burrito, replacing the nu
# process, so burrito's parent is WezTerm, the walk finds no shell, and it falls
# back to $SHELL. Without this line that fallback is zsh; with it, every burrito
# cell launches nu.
$env.SHELL = $nu.current-exe

# `pass` (password-store): pin the store location to its default explicitly so the
# Nushell completion (config sources pass.nu) and the apply-time setup check both
# read the same path. Change this to relocate the store.
$env.PASSWORD_STORE_DIR = ($nu.home-dir | path join ".password-store")

# Shell integrations are generated at apply time by the chezmoi run_after script,
# not here, and merely sourced by config.nu — so shell launch does zero work.
