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
# Point ripgrep at its config so `rg` shares the global search-ignore that fd
# reads natively from ~/.config/fd/ignore (node_modules, target, build, …).
$env.RIPGREP_CONFIG_PATH = ($nu.home-dir | path join ".config" "ripgrep" "config")
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

# Start dir: open every interactive shell in the last directory we navigated into —
# by any means (real `cd`, zoxide z/zi, `zz`, picker jump) — falling back to ~/dev
# (the dev workspace) on a fresh machine. mkcd records that dir in startdir.txt on
# every move. We read the file directly here because env.nu runs before config.nu
# sources dirstack.nu — the path mirrors `_startdir_file`.
# Guarded on an interactive stdout so a non-interactive `nu -c ...` caller keeps its
# own cwd. burrito cells read this env.nu too, so every pane lands on the same dir.
if (is-terminal --stdout) {
    let dev_dir = ($nu.home-dir | path join "dev")
    mkdir $dev_dir
    let state = ($env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state"))
    let startdir_file = ($state | path join "nushell" "startdir.txt")
    let start = (if ($startdir_file | path exists) {
        let d = (open --raw $startdir_file | str trim)
        if (($d | is-not-empty) and ($d | path exists)) { $d } else { null }
    } else { null })
    cd (if ($start == null) { $dev_dir } else { $start })
}

# Shell integrations are generated at apply time by the chezmoi run_after script,
# not here, and merely sourced by config.nu — so shell launch does zero work.
