# gitseg.nu — the prompt's cached segments, stale-while-revalidate.
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# `git status` in a working repo is the slowest thing the prompt can do
# (measured: 479ms of starship in-process time in kern2, 2.9s raw under
# load) and nushell evaluates PROMPT_COMMAND synchronously, so it blocks
# every Enter. This module is the loader-then-replace pattern: the prompt
# draws the cached segment instantly, a pre_prompt `job spawn` refreshes
# the cache off the critical path, and the next render replaces the view.
# `⋯` marks the one render between. The language-version blocks ride the
# same shape with a ONE-HOUR cache — a toolchain's version does not change
# between keystrokes, so the reader never probes, the job does.
#
# Both caches are written via a same-directory tmp + `mv` (atomic rename)
# — a truncated read would paint a half-segment on the prompt. Segment
# CONTENT is plain text: prompt.nu owns every SGR byte.

def _seg_dir [name: string] { (_state_dir) | path join $name }

# Walk up from PWD looking for `.git` — no spawn on the render path. `.git`
# is a FILE in a worktree, so `path exists` is the test, not `path type`.
# prompt.nu also walks this for the directory block.
def _gitseg_root [] {
    mut p = $env.PWD
    loop {
        if ($"($p)/.git" | path exists) { return $p }
        let parent = ($p | path dirname)
        if $parent == $p { return null }
        $p = $parent
    }
}

def _gitseg_key [root: string] { $root | hash sha256 | str substring 0..15 }

def _gitseg_file [root: string] { (_seg_dir "gitseg") | path join (_gitseg_key $root) }

# One porcelain-v2 query, protected across every pane by an OS file lock.
# The worker times out Git after 10s and preserves the last good cache on error.
def _gitseg_refresh [root: string] {
    let worker = ($nu.home-dir | path join ".local/bin/prompt-git")
    ^python3 $worker $root (_gitseg_file $root)
}

# The reader — the only thing on the render path, µs.
def _gitseg [] {
    let root = (_gitseg_root)
    if ($root == null) { return "" }
    let f = (_gitseg_file $root)
    if not ($f | path exists) { return " ⋯ " }
    open --raw $f
}

# Cached reads stay synchronous; only stale entries start a refresh job.
# The shared worker rechecks freshness after locking, so peers do no Git work.
def --env _gitseg_revalidate [] {
    let root = (_gitseg_root)
    if ($root == null) { return }
    let f = (_gitseg_file $root)
    let now = (date now)
    if ($f | path exists) {
        let age = ($now - (ls $f | get 0.modified))
        if $age >= 0sec and $age < 750ms { return }
    }
    let last = ($env._GITSEG_LAST? | default null)
    if $last != null and $last.root == $root and ($now - $last.at) < 750ms { return }
    $env._GITSEG_LAST = {root: $root, at: $now}
    job spawn { _gitseg_refresh $root } | ignore
}

# ── language versions ────────────────────────────────────────────────────────
# One marker table per language, checked in the current directory first and
# then at the repo root (starship showed the root's toolchain from a
# subdirectory — kern2/crates/api carries the rust block from its root).
# The version files live under langseg/ keyed by language name, written by
# the probe job, refreshed at most hourly — the reader never spawns.

const LANGSEG_MARKERS = [
    [lang marker];
    [nodejs "package.json"]
    [nodejs "node_modules"]
    [nodejs ".nvmrc"]
    [rust "Cargo.toml"]
    [rust "Cargo.lock"]
    [golang "go.mod"]
    [golang "go.sum"]
    [golang "go.work"]
    [python ".python-version"]
    [python "pyproject.toml"]
    [python "requirements.txt"]
    [python "setup.py"]
    [python "setup.cfg"]
]
# starship's block order, which is the display order.
const LANGSEG_ORDER = [nodejs rust golang python]

def _langseg_present [] {
    let root = (_gitseg_root)
    let dirs = ([$env.PWD] | append (if ($root == null) { [] } else { [$root] }))
    ($dirs | each {|d|
        $LANGSEG_MARKERS
        | where {|m| ($d | path join $m.marker | path exists) }
        | get lang
    } | flatten | uniq)
}

def _langseg_file [lang: string] { (_seg_dir "langseg") | path join $"($lang).ver" }

# The probe job — versions spelled the way starship spelled them: node and
# rust keep their leading v, go keeps its go, python is bare.
def _langseg_refresh [langs: list<string>] {
    for lang in $langs {
        let v = (try {
            match $lang {
                "nodejs" => { (^node --version | str trim) }
                "rust" => { "v" + (^rustc --version | split row " " | get 1) }
                "golang" => { (^go version | split row " " | get 1) }
                "python" => { (^python3 --version | split row " " | get 2) }
                _ => { "" }
            }
        } catch { "" })
        let d = (_seg_dir "langseg")
        mkdir $d
        let tmp = ($d | path join $".($lang).($nu.pid).new")
        ($v | str trim) | save -f --raw $tmp
        mv -f $tmp (_langseg_file $lang)
    }
}

# The reader: blocks in starship's format — two spaces, the version, one
# space — for every present language whose version file has landed.
def _langseg [] {
    let present = (_langseg_present)
    $LANGSEG_ORDER
    | where {|lang| $lang in $present }
    | each {|lang|
        let f = (_langseg_file $lang)
        if not ($f | path exists) { return "" }
        let v = (open --raw $f | str trim)
        if ($v | is-empty) { "" } else { $"  ($v) " }
    }
    | str join ""
}

# The revalidate: probe a language when its file is missing or an hour old.
# After the first probe the file exists (empty counts — an absent tool is an
# answer, not a retry), so a prompt pays at most four `path exists` checks
# and a mtime look.
def --env _langseg_revalidate [] {
    let present = (_langseg_present)
    if ($present | is-empty) { return }
    let stale = ($present | where {|lang|
        let f = (_langseg_file $lang)
        if not ($f | path exists) { true } else { (ls $f | get 0.modified) < ((date now) - 1hr) }
    })
    if ($stale | is-empty) { return }
    job spawn { _langseg_refresh $stale } | ignore
}

$env.config.hooks.pre_prompt = (
    ($env.config.hooks.pre_prompt? | default [])
    | append {|| _gitseg_revalidate }
)
$env.config.hooks.pre_prompt = (
    ($env.config.hooks.pre_prompt? | default [])
    | append {|| _langseg_revalidate }
)