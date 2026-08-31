# capsule.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Capsule

const CAPSULE_IMAGE = "capsule:latest"
const CAPSULE_PREFIX = "capsule-"
const CAPSULE_HASH_LABEL = "capsule.dockerfile"
const CAPSULE_DIR_LABEL = "capsule.dir"

def _capsule_dockerfile [] { $env.HOME | path join ".config" "capsule" "Dockerfile" }
def _capsule_recents [] { $env.HOME | path join ".cache" "capsule" "recents.nuon" }
def _capsule_creds_dir [] { $env.HOME | path join ".cache" "capsule" "creds" }
def _capsule_setup_script [] { $env.HOME | path join ".config" "capsule" "setup-credentials.sh" }

def _capsule_name [dir: string] {
    let san = ($dir | path basename | str replace --all --regex '[^A-Za-z0-9_.-]' '-')
    let hash8 = ($dir | hash sha256 | str substring 0..7)
    $"($CAPSULE_PREFIX)($san)-($hash8)"
}

def _capsule_hash [] { open --raw (_capsule_dockerfile) | hash sha256 }

def _capsule_image_hash [] {
    let r = (^docker image inspect $CAPSULE_IMAGE --format $"{{index .Config.Labels \"($CAPSULE_HASH_LABEL)\"}}" | complete)
    if $r.exit_code != 0 { "" } else { $r.stdout | str trim }
}

def _capsule_build [] {
    let hash = (_capsule_hash)
    try {
        ^docker build -t $CAPSULE_IMAGE --label $"($CAPSULE_HASH_LABEL)=($hash)" -f (_capsule_dockerfile) ($env.HOME | path join ".config" "capsule")
    } catch {
        error make {msg: "capsule: docker build failed — image and container left untouched"}
    }
}

def _capsule_state [name: string] {
    let r = (^docker container inspect $name --format $"{{.State.Running}}{{\"\\t\"}}{{index .Config.Labels \"($CAPSULE_DIR_LABEL)\"}}" | complete)
    if $r.exit_code != 0 {
        {exists: false, running: false, dir_label: ""}
    } else {
        let parts = ($r.stdout | str trim | split row (char tab))
        {
            exists: true
            running: (($parts | get 0? | default "") == "true")
            dir_label: ($parts | get 1? | default "")
        }
    }
}

def _capsule_owned [] {
    let r = (^docker ps -a --filter $"label=($CAPSULE_DIR_LABEL)" --format $"{{.Names}}\t{{.Label \"($CAPSULE_DIR_LABEL)\"}}\t{{.State}}" | complete)
    if $r.exit_code != 0 { return [] }
    $r.stdout
    | lines
    | where {|l| $l | is-not-empty }
    | each {|l|
        let p = ($l | split row (char tab))
        {
            name: ($p | get 0? | default "")
            dir: ($p | get 1? | default "")
            status: (if ($p | get 2? | default "") == "running" { "running" } else { "stopped" })
        }
    }
    | where {|row| $row.name | str starts-with $CAPSULE_PREFIX }
}

def _capsule_record [dir: string] {
    try {
        let f = (_capsule_recents)
        mkdir ($f | path dirname)
        let old = (if ($f | path exists) { open $f } else { [] })
        [$dir] ++ ($old | where {|d| $d != $dir }) | first 20 | save -f $f
    } catch {
        print -e $"capsule: could not record ($dir) in the recents store \(non-fatal)"
    }
}

def _capsule_creds_write [name: string, content: any] {
    let d = (_capsule_creds_dir)
    let tmp = ($d | path join $".($name).new")
    let final = ($d | path join $name)
    $content | save -f --raw $tmp
    ^chmod 600 $tmp
    ^mv -f $tmp $final
}

def _capsule_creds_drop [name: string] {
    let f = ((_capsule_creds_dir) | path join $name)
    if ($f | path exists) { rm -f $f }
}

def _capsule_creds_fresh [] {
    let d = (_capsule_creds_dir)
    if not ($d | path exists) { return false }
    let files = (try { ls $d } catch { [] })
    if ($files | is-empty) { return false }
    let cutoff = ((date now) - 60sec)
    $files | all {|f| $f.modified > $cutoff }
}

def _capsule_refresh_git [] {
    let g = (try {
        with-env {GIT_TERMINAL_PROMPT: "0"} {
            "protocol=https\nhost=github.com\n" | ^git credential fill | complete
        }
    } catch { {exit_code: 1, stdout: ""} })
    let user = (if $g.exit_code == 0 {
        $g.stdout | lines | where {|l| $l | str starts-with "username=" }
        | get 0? | default "" | str replace "username=" ""
    } else { "" })
    let pass = (if $g.exit_code == 0 {
        $g.stdout | lines | where {|l| $l | str starts-with "password=" }
        | get 0? | default "" | str replace "password=" ""
    } else { "" })
    if ($user | is-not-empty) and ($pass | is-not-empty) {
        let u = ($user | url encode --all)
        let p = ($pass | url encode --all)
        _capsule_creds_write "git-credentials" $"https://($u):($p)@github.com\n"
    } else {
        _capsule_creds_drop "git-credentials"
    }
}

def _capsule_refresh_claude_credentials [] {
    let k = (try {
        ^security find-generic-password -s "Claude Code-credentials" -w | complete
    } catch { {exit_code: 1, stdout: ""} })
    let host_file = ($env.HOME | path join ".claude" ".credentials.json")
    let payload = (if $k.exit_code == 0 {
        $k.stdout | str trim
    } else if ($host_file | path exists) {
        open --raw $host_file | into string | str trim
    } else { "" })
    let parses = (if ($payload | is-empty) { false } else {
        try { $payload | from json | ignore; true } catch { false }
    })
    if $parses {
        _capsule_creds_write "claude-credentials.json" $"($payload)\n"
    } else {
        _capsule_creds_drop "claude-credentials.json"
    }
}

def _capsule_refresh_claude_json [] {
    let src = ($env.HOME | path join ".claude.json")
    let j = (if ($src | path exists) { try { open $src } catch { null } } else { null })
    if $j == null {
        _capsule_creds_drop "claude.json"
        return
    }
    let cols = ($j | columns)
    let keep = [
        "hasCompletedOnboarding" "theme" "installMethod"
        "userID" "firstStartTime" "oauthAccount"
    ]
    let filtered = ($keep | reduce --fold {} {|k, acc|
        if ($k in $cols) { $acc | upsert $k ($j | get $k) } else { $acc }
    })
    _capsule_creds_write "claude.json" $"($filtered | to json)\n"
}

def _capsule_refresh_opencode [] {
    let src = ($env.HOME | path join ".local" "share" "opencode" "auth.json")
    if ($src | path exists) {
        _capsule_creds_write "opencode-auth.json" (open --raw $src)
    } else {
        _capsule_creds_drop "opencode-auth.json"
    }
}

def _capsule_refresh_creds [] {
    if (_capsule_creds_fresh) { return }
    let d = (_capsule_creds_dir)
    mkdir $d
    ^chmod 700 $d
    _capsule_refresh_git
    _capsule_refresh_claude_credentials
    _capsule_refresh_claude_json
    _capsule_refresh_opencode
}

def _capsule_cred_mounts [] {
    mut flags = []
    let ssh = ($env.HOME | path join ".ssh")
    if ($ssh | path exists) {
        $flags = ($flags | append ["-v" $"($ssh):/opt/capsule/host/ssh:ro"])
    }
    let gitconfig = ($env.HOME | path join ".gitconfig")
    if ($gitconfig | path exists) {
        $flags = ($flags | append ["-v" $"($gitconfig):/opt/capsule/host/gitconfig:ro"])
    }
    let creds = (_capsule_creds_dir)
    if ($creds | path exists) {
        $flags = ($flags | append ["-v" $"($creds):/opt/capsule/creds:ro"])
    }
    let setup = (_capsule_setup_script)
    if ($setup | path exists) {
        $flags = ($flags | append ["-v" $"($setup):/opt/capsule/setup-credentials.sh:ro"])
    }
    $flags
}

# ── the recents picker (01-capsule/04, task C.4) ────────────────────────────

def _capsule_recents_read [] {
    let f = (_capsule_recents)
    if not ($f | path exists) { return [] }
    let stored = (try { open $f } catch { [] })
    let live = ($stored | where {|d| ($d | path type) == "dir" })
    if $live != $stored {
        try { $live | save -f $f } catch {
            print -e "capsule: could not prune the recents store (non-fatal)"
        }
    }
    $live
}

def _capsule_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

def _capsule_recents_pick [dirs: list] {
    let src = $"printf '%s\\n' ($dirs | each {|d| _capsule_shquote $d } | str join ' ')"
    let raw = (try {
        ^tv --source-command $src --input-header "Recent" --no-sort --no-preview --keybindings 'enter="confirm_selection"'
    } catch { "" })
    $raw | lines | where {|l| ($l | str trim) != "" } | get -o 0 | default "" | str trim
}

def capsule [dir?: path, --rebuild] {
    let target = ($dir | default $env.PWD | path expand)
    if ($target | path type) != "dir" {
        error make {msg: $"capsule: not a directory: ($target)"}
    }
    if (which docker | is-empty) {
        error make {msg: "capsule: docker not found on PATH — start Docker Desktop"}
    }
    if not ((_capsule_dockerfile) | path exists) {
        error make {msg: $"capsule: (_capsule_dockerfile) is missing — run chezmoi apply"}
    }
    let name = (_capsule_name $target)
    let state = (_capsule_state $name)
    if $rebuild or not $state.exists {
        _capsule_refresh_creds
    } else {
        job spawn { _capsule_refresh_creds } | ignore
    }
    if $rebuild or ((_capsule_hash) != (_capsule_image_hash)) { _capsule_build }
    if $state.exists and ($state.dir_label | is-empty) {
        error make {msg: $"capsule: a container named ($name) exists but was not created by capsule — remove or rename it yourself"}
    }
    if $rebuild and $state.exists { ^docker rm -f $name | ignore }
    let exists = ($state.exists and not $rebuild)
    if not $exists {
        ^docker run -d --name $name --label $"($CAPSULE_DIR_LABEL)=($target)" -v $"($target):/workspace" ...(_capsule_cred_mounts) $CAPSULE_IMAGE | ignore
    } else if not $state.running {
        ^docker start $name | ignore
    }
    if not $exists and ((_capsule_setup_script) | path exists) {
        try {
            ^docker exec $name bash /opt/capsule/setup-credentials.sh
        } catch {
            print -e "capsule: /opt/capsule/setup-credentials.sh failed — attaching anyway; credentials may be incomplete"
        }
    }
    _capsule_record $target
    ^docker exec -it $name zsh
}

def "capsule list" [] {
    _capsule_owned | select name dir status
}

def "capsule clean" [--all] {
    let owned = (_capsule_owned)
    let victims = (if $all { $owned } else { $owned | where status == "stopped" })
    $victims | each {|row|
        if $row.status == "running" {
            ^docker rm -f $row.name | ignore
        } else {
            ^docker rm $row.name | ignore
        }
        $row.name
    }
}

def "capsule recent" [] {
    if not $nu.is-interactive {
        error make {msg: "capsule recent: interactive-only — tv needs a TTY"}
    }
    if (which tv | is-empty) {
        error make {msg: "capsule recent: `tv` (television) is not installed — the picker needs it"}
    }
    let dirs = (_capsule_recents_read)
    if ($dirs | is-empty) {
        print "capsule recent: no recent workspaces yet — mount one with `capsule`"
        return
    }
    let picked = (_capsule_recents_pick $dirs)
    if ($picked | is-empty) { return }
    capsule $picked
}
