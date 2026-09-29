# gitseg.nu — the prompt's git block, stale-while-revalidate.
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# `git status` in a working repo is the slowest thing the prompt can do
# (measured: 479ms of starship in-process time in kern2, 2.9s raw under
# load) and nushell evaluates PROMPT_COMMAND synchronously, so it blocks
# every Enter. This module is the loader-then-replace pattern: the prompt
# draws the cached segment instantly, a pre_prompt `job spawn` refreshes
# the cache off the critical path, and the next render replaces the view.
# `⋯` marks the one render between. Trade, accepted in the decision memo:
# the git block can lag reality by one refresh cycle.
#
# TRAP: the cache is written via a same-directory tmp + `mv` (atomic
# rename) — a truncated read would paint a half-segment on the prompt.

def _gitseg_dir [] { (_state_dir) | path join "gitseg" }

# Walk up from PWD looking for `.git` — no spawn on the render path. `.git`
# is a FILE in a worktree, so `path exists` is the test, not `path type`.
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

def _gitseg_file [root: string] { (_gitseg_dir) | path join (_gitseg_key $root) }

# TRAP: the trailing `m` is REQUIRED — `ansi -e '30;42'` emits `\e[30;42`
# without the SGR final byte, and the terminal then eats the segment's next
# three characters ("  m" of "  main") as CSI parameter bytes.
def _gitseg_style [] { ansi -e '30;42m' }   # starship's `fg:crust bg:green`

# The refresh job — never on the render path. Symbols match starship's
# git_status: `$` staged, `!` unstaged-modified, `?` untracked. With no
# branch (detached, empty repo) or no git at all, the segment is empty and
# the prompt shows only the format's own arrows — exactly the non-git
# rendering starship produced before this module existed.
def _gitseg_refresh [root: string] {
    let seg = (try {
        let branch = (^git -C $root branch --show-current | str trim)
        if ($branch | is-empty) { "" } else {
            let st = (do -i { ^git -C $root status --porcelain | lines } | default [])
            let symbols = ([
                (if ($st | any {|r| ($r | str substring 0..0) =~ '[AMDRUC]' }) { "$" } else { "" })
                (if ($st | any {|r| ($r | str substring 1..1) =~ '[MD]' }) { "!" } else { "" })
                (if ($st | any {|r| ($r | str starts-with "??") }) { "?" } else { "" })
            ] | str join)
            $"(_gitseg_style)  ($branch)(if ($symbols | is-empty) { "" } else { $" ($symbols)" }) (ansi reset)"
        }
    } catch { "" })
    let d = (_gitseg_dir)
    mkdir $d
    # TRAP: tmp carries the pid — two panes in one repo refresh at once and
    # a shared tmp name would interleave their writes.
    let tmp = ($d | path join $".(_gitseg_key $root).($nu.pid).new")
    $seg | save -f --raw $tmp
    mv -f $tmp (_gitseg_file $root)
}

# The reader — the only thing on the render path, µs.
def _gitseg [] {
    let root = (_gitseg_root)
    if ($root == null) { return "" }
    let f = (_gitseg_file $root)
    if not ($f | path exists) { return $"(_gitseg_style) ⋯ (ansi reset)" }
    open --raw $f
}

# The revalidate — runs in pre_prompt, before each render. At most one
# refresh per repo is in flight; a job that has not written in 30s (a hung
# git) is abandoned and reissued.
def --env _gitseg_revalidate [] {
    let root = (_gitseg_root)
    if ($root == null) { return }
    let f = (_gitseg_file $root)
    let mtime = (if ($f | path exists) { (ls $f | get 0.modified) } else { null })
    let key = (_gitseg_key $root)
    let inflight = ($env._GITSEG_INFLIGHT? | default null)
    if ($inflight != null) and ($inflight.key == $key) {
        # the job wrote the file — this render is the one that replaces the view
        let done = ($mtime != null) and (($inflight.mtime == null) or ($mtime > $inflight.mtime))
        if $done {
            $env._GITSEG_INFLIGHT = null
            return
        }
        if ((date now) - $inflight.at) < 30sec { return }
    }
    $env._GITSEG_INFLIGHT = { key: $key, mtime: $mtime, at: (date now) }
    job spawn { _gitseg_refresh $root } | ignore
}

$env.config.hooks.pre_prompt = (
    ($env.config.hooks.pre_prompt? | default [])
    | append {|| _gitseg_revalidate }
)