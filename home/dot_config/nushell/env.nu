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

# Homebrew + macOS system dirs. macOS seeds these into a login shell's PATH via
# `path_helper` (reading /etc/paths and /etc/paths.d/*), but path_helper only runs
# from /etc/zprofile and /etc/profile — bash/zsh. Nushell never runs it, so when nu
# is the login shell (chsh) launched by a GUI WezTerm, /opt/homebrew/bin and the
# system dirs are absent and tools like bat/rg/starship/tv/lazygit go missing.
# We `append` them (lower priority than the user dirs prepended below) and `uniq`
# to keep this a no-op whenever the parent already provided them.
$env.PATH = (
    $env.PATH
    | prepend ($nu.home-dir | path join ".local" "bin")
    | prepend ($nu.home-dir | path join ".cargo" "bin")
    | append [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
    ]
    | uniq
)

$env.XDG_CONFIG_HOME = ($nu.home-dir | path join ".config")
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_SHELL = "nu"

# Advertise Nushell as $SHELL so any child that spawns "the user's shell" gets nu.
# This is a fallback, not the primary path: config.nu launches burrito as a child
# of nu (no `exec`), so burrito's parent-tree walk finds nu directly and cells
# launch nu without touching $SHELL. We keep this so anything that does fall back
# to $SHELL still lands on nu.
$env.SHELL = $nu.current-exe

# `pass` (password-store): pin the store location to its default explicitly so the
# Nushell completion (config sources pass.nu) and the apply-time setup check both
# read the same path. Change this to relocate the store.
$env.PASSWORD_STORE_DIR = ($nu.home-dir | path join ".password-store")

# Default working directory: open every interactive shell in ~/dev (the dev
# workspace) instead of $HOME. `mkdir` is idempotent, so it's created on first
# launch and the `cd` never fails. Guarded on an interactive stdout so a
# non-interactive `nu -c ...` caller keeps its own cwd. burrito cells read this
# env.nu too, so every pane also lands here.
if (is-terminal --stdout) {
    let dev_dir = ($nu.home-dir | path join "dev")
    mkdir $dev_dir
    cd $dev_dir
}

# Shell integrations are generated at apply time by the chezmoi run_after script,
# not here, and merely sourced by config.nu — so shell launch does zero work.
