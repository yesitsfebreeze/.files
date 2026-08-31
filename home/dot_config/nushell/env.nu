# env.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

# ── PATH <-> list conversions ───────────────────────────────────────────────
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: {|s| $s | split row (char esep) }
        to_string: {|v| $v | str join (char esep) }
    }
    "Path": {
        from_string: {|s| $s | split row (char esep) }
        to_string: {|v| $v | str join (char esep) }
    }
}

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

$env.RIPGREP_CONFIG_PATH = ($nu.home-dir | path join ".config" "ripgrep" "config")

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

$env.STARSHIP_SHELL = "nu"

$env.SHELL = $nu.current-exe

# ── Start dir (R7) ──────────────────────────────────────────────────────────
if $nu.is-interactive {
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
