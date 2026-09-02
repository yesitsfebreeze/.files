# env.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# ── PATH repair (R1) ────────────────────────────────────────────────────────
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

# ── Environment (R2) ────────────────────────────────────────────────────────
$env.XDG_CONFIG_HOME = ($nu.home-dir | path join ".config")
$env.XDG_DATA_HOME = ($env.XDG_DATA_HOME? | default ($nu.home-dir | path join ".local" "share"))

$env.RIPGREP_CONFIG_PATH = ($nu.home-dir | path join ".config" "ripgrep" "config")

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

$env.STARSHIP_SHELL = "nu"

# Who the board is working as; every `pearde` command reads it and refuses without it.
$env.PEARDE_AS = "engineer"

$env.SHELL = $nu.current-exe

# ── Start dir (R7) ──────────────────────────────────────────────────────────
#
# TRAP: only OUTSIDE tmux. This `cd` is unconditional, it runs on every
# interactive shell, and it runs AFTER the launcher has placed the process —
# so inside tmux it silently defeated every `-c` in tmux.conf. Measured
# 2026-09-01: `tmux split-window -c /usr/local` landed the new pane in
# whatever startdir.txt happened to hold, which is the last directory visited
# in ANY pane. A split is meant to inherit the pane it was split from and a
# `F5 <digit>` window is meant to be a clean `~`; both were reading one global
# file instead.
#
# Under tmux the launcher is the one that knows: every pane is created with an
# explicit `-c`, and `tmux-main` seeds the SESSION with startdir.txt so the
# first pane of a fresh server still comes up where you left off. That is
# where R7 lives now — one read when the environment starts, not one per
# shell. `mkcd` keeps writing the file; only the reader moved.
#
# The bare-`nu` case keeps the old behaviour, and it is not hypothetical:
# `tmux-main`'s no-tmux fallback execs nushell directly, and that shell has no
# launcher to inherit a directory from.
if $nu.is-interactive and ($env.TMUX? | is-empty) {
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

# ── The Ollama endpoint probe (R2) ──────────────────────────────────────────
if $nu.is-interactive and (which ollama-host | is-not-empty) {
    let _ollama = (do { ^ollama-host } | complete)
    if $_ollama.exit_code == 0 {
        $env.OLLAMA_HOST = ($_ollama.stdout | str trim)
    }
}
