# capsule.nu — one directory, one dev container, one CLI (01-capsule/01,
# task C.2): `capsule [dir] [--rebuild]` plus the `list`/`clean` subcommands.
# Sourced by config.nu at the MODULES anchor; parses standalone under `nu -n`
# (theme.nu precedent) — the gate sources it directly, and no def here
# depends on anything config.nu sets up.
#
# EVERY DOCKER CALL GOES THROUGH `^docker`, so a PATH shim can observe every
# one — tests/capsule-lifecycle.sh drives this file against a recording shim
# and never touches the real daemon.
#
# THE TOOL HAS NO WORKING DIRECTORY OF ITS OWN (R5, finding C-3): everything
# downstream of argument parsing uses the expanded `$target` only, and no
# directory change is ever made here. The legacy `mount` failed on exactly
# this — it moved itself to a non-existent hardcoded directory and mounted a
# `workspace/` subdirectory instead of the directory it was handed. The gate
# greps this file for the regression spellings, so they are kept out of this
# comment entirely and a hit is proof of a regression.
#
# REBUILD DETECTION IS A CONTENT HASH IN AN IMAGE LABEL, NOT MTIME AND NOT A
# SIDE STATE FILE: the sha256 of the Dockerfile it was built from rides on
# the image as the `capsule.dockerfile` label, so a `touch` never triggers a
# rebuild and there is no second file to drift. The AUTO path updates the
# IMAGE ONLY and attaches to the existing container as-is; `--rebuild` is
# the one recreate gesture, because recreation destroys container-local
# state and the cheap mistake has to be the safe one (R2, R4 — and what
# help/capsule.nuon already promises).
#
# CREDENTIALS (01-capsule/03, task C.3) ARRIVE BY READ-ONLY MOUNT AND NEVER
# BY IMAGE LAYER. The Dockerfile has no COPY and no ADD, so nothing from the
# host can enter the image; the host's keys, identity and exported agent
# tokens are bound in `:ro` at run time. Two rules carry the reason with
# them, because both have already been got wrong somewhere:
#   * THE EXPORT DIRECTORY IS ~/.cache/capsule/creds, NOT ~/.config/capsule.
#     `~/.config/capsule` is the docker BUILD CONTEXT (_capsule_build passes
#     it as the context path), so a token written there would be one
#     `COPY .` away from a layer. The legacy config made the mirror-image
#     mistake and wrote a plaintext token inside the dotfiles tree itself.
#   * THE CREDS PATH IS BOUND AS A DIRECTORY, NEVER AS INDIVIDUAL FILES. A
#     file bind pins an inode; the refresh replaces each file by rename
#     (atomic), which changes the inode, so a file bind would keep showing
#     an already-running container the old token forever. A directory bind
#     shows the rename immediately, which is what lets a rotated credential
#     heal a RUNNING capsule (R5).

# The image name. C.2 owns it; nothing else builds or tags it (dev-image's
# own gate uses throwaway capsule-gate-* tags).
const CAPSULE_IMAGE = "capsule:latest"
# The container name prefix (R1, R6).
const CAPSULE_PREFIX = "capsule-"
# Image label: sha256 of the Dockerfile the image was built from.
const CAPSULE_HASH_LABEL = "capsule.dockerfile"
# Container label: the absolute directory mounted. Ownership marker — `list`
# and `clean` only ever see containers that carry it AND the name prefix.
const CAPSULE_DIR_LABEL = "capsule.dir"

# The one Dockerfile — the chezmoi target of C.1 (01-capsule/02-dev-image).
def _capsule_dockerfile [] { $env.HOME | path join ".config" "capsule" "Dockerfile" }
# Recents store, per C.4 R1: state, not config — outside ~/.config, so
# `chezmoi apply` never touches it.
def _capsule_recents [] { $env.HOME | path join ".cache" "capsule" "recents.nuon" }
# The exported credential material (C.3). Runtime state, so it sits beside
# recents.nuon and deliberately OUTSIDE the docker build context — see the
# credentials note in this file's header for why that is a hard rule.
def _capsule_creds_dir [] { $env.HOME | path join ".cache" "capsule" "creds" }
# The first-run container-side setup script, as chezmoi deploys it. Mounted
# read-only and run once on the create path; C.3's spec02 owns its contents.
def _capsule_setup_script [] { $env.HOME | path join ".config" "capsule" "setup-credentials.sh" }

# _capsule_name (R1): capsule-<san>-<hash8>. <san> is the directory basename
# with every character outside [A-Za-z0-9_.-] replaced by `-`; <hash8> is the
# first 8 hex chars of the sha256 of the absolute path. The hash is ALWAYS
# appended, not only on collision: same dir -> same name on every invocation,
# two `api` dirs in different parents -> different names, no registry to
# consult.
def _capsule_name [dir: string] {
    let san = ($dir | path basename | str replace --all --regex '[^A-Za-z0-9_.-]' '-')
    let hash8 = ($dir | hash sha256 | str substring 0..7)
    $"($CAPSULE_PREFIX)($san)-($hash8)"
}

# _capsule_hash: content hash of the Dockerfile as deployed.
def _capsule_hash [] { open --raw (_capsule_dockerfile) | hash sha256 }

# _capsule_image_hash: the hash the current image was built from; "" when the
# image is absent.
def _capsule_image_hash [] {
    let r = (^docker image inspect $CAPSULE_IMAGE --format $"{{index .Config.Labels \"($CAPSULE_HASH_LABEL)\"}}" | complete)
    if $r.exit_code != 0 { "" } else { $r.stdout | str trim }
}

# _capsule_build: build output streams to the terminal. Non-zero exit aborts
# the def — the container is never touched after a failed build. No
# --platform flag: native linux/arm64, C.1's rule.
def _capsule_build [] {
    let hash = (_capsule_hash)
    try {
        ^docker build -t $CAPSULE_IMAGE --label $"($CAPSULE_HASH_LABEL)=($hash)" -f (_capsule_dockerfile) ($env.HOME | path join ".config" "capsule")
    } catch {
        error make {msg: "capsule: docker build failed — image and container left untouched"}
    }
}

# _capsule_state: {exists, running, dir_label} for one container name.
# dir_label empty on an existing container means it is NOT ours (R6's
# ownership marker) — never adopt it, never remove it.
#
# dir_label is load-bearing: it is what guards the `--rebuild` REMOVAL. Step
# 6 of `capsule` refuses on an empty dir_label, and step 7's
# `^docker rm -f $name` never consults _capsule_owned — so nothing else
# stands between a forced rebuild and a container this tool did not create.
# Measured 2026-08-23: with the emptiness test neutered, `--rebuild` against
# a same-named container carrying no capsule.dir label asks docker to remove
# it. The foreign-rebuild scenario in tests/capsule-lifecycle.sh and its
# control hold that down; a refactor that drops the refusal turns them red.
#
# Empty here really does mean "no marker": `index .Config.Labels` prints the
# empty string for a container that has no such label — measured against
# docker 29.4.0 and against text/template's `index` on a nil map, an empty
# map and a missing key. It never prints <no value>, which would read as
# non-empty and open the guard.
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

# _capsule_owned (R6): the ONE set both `list` and `clean` operate on. Label
# AND prefix — strictly narrower than the prefix R6 requires, so a hand-made
# container that happens to be named capsule-x is still never touched.
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

# _capsule_record (R7, format per C.4 R1): most recent first, deduplicated,
# capped at 20. Non-fatal by design — a read-only cache dir must not block
# the attach, so any failure is one stderr line and the flow continues.
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

# _capsule_creds_write: publish one credential file, mode 0600, ATOMICALLY —
# write a temp name, set the mode on it, rename it into place. The rename is
# what a running container sees the instant it happens; an in-place rewrite
# would expose a half-written credential to whatever is reading it.
def _capsule_creds_write [name: string, content: any] {
    let d = (_capsule_creds_dir)
    let tmp = ($d | path join $".($name).new")
    let final = ($d | path join $name)
    $content | save -f --raw $tmp
    ^chmod 600 $tmp
    ^mv -f $tmp $final
}

# _capsule_creds_drop: remove one exported file. Called whenever the host
# source is gone, because a revoked or logged-out credential must DISAPPEAR
# rather than linger — a stale file that outlives its source is exactly the
# failure R5 names.
def _capsule_creds_drop [name: string] {
    let f = ((_capsule_creds_dir) | path join $name)
    if ($f | path exists) { rm -f $f }
}

# _capsule_creds_fresh: true when every exported file is younger than 60s.
# The short-circuit exists because the export is not free (measured on this
# host, 2026-08-23: `git credential fill` through the `!gh auth
# git-credential` helper 0.75–1.16s, the keychain read 0.34–0.50s), and a
# burst of mounts must not fire a burst of `gh` calls.
def _capsule_creds_fresh [] {
    let d = (_capsule_creds_dir)
    if not ($d | path exists) { return false }
    let files = (try { ls $d } catch { [] })
    if ($files | is-empty) { return false }
    let cutoff = ((date now) - 60sec)
    $files | all {|f| $f.modified > $cutoff }
}

# _capsule_refresh_git (R3): the host's github.com HTTPS credential, in
# git-credential-store format.
#
# GIT_TERMINAL_PROMPT=0 IS LOAD-BEARING, NOT DEFENSIVE: with no helper
# reachable, `git credential fill` blocks on a terminal prompt, so a
# hermetic run would HANG instead of failing (verified 2026-08-23: with an
# empty HOME it exits 128 with "terminal prompts disabled").
#
# Both fields go through `url encode --all` because the store format is a
# URL: a token containing `:`, `@` or `/` silently corrupts the line
# otherwise, and the corruption is invisible until a push fails.
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

# _capsule_refresh_claude_credentials (R4): the agent's OAuth payload.
#
# THIS IS THE MACOS FACT R4's ORIGINAL WORDING MISSED. On this host Claude
# Code keeps its tokens in the LOGIN KEYCHAIN and
# `~/.claude/.credentials.json` does not exist (verified 2026-08-23), so
# mounting `~/.claude` would have propagated no credential at all. The
# keychain item's payload is byte-for-byte the format that file would hold,
# so it is exported unchanged; the file is the fallback for a Linux-style
# layout.
#
# Parse-checked before publishing: a truncated credential file makes the
# agent die on a parse error instead of falling back to a login flow.
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

# _capsule_refresh_claude_json (R4): a FILTERED PROJECTION of ~/.claude.json,
# never a copy. It exists only so the agent skips onboarding.
#
# The host file is ~671 KB and its `mcpServers` and `projects` keys name host
# paths and every project the user has ever opened. Copying it would drag
# phantom MCP servers (which fail once per prompt inside a container) and the
# whole project history into every capsule. Six keys, by name, and nothing
# else — widening this list is a decision, not a default.
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

# _capsule_refresh_opencode (R4): the agent's auth file only. NOT the rest of
# ~/.local/share/opencode — that is a 94 MB live SQLite database with WAL
# sidecars, and a Docker Desktop bind is the wrong medium for a live WAL.
def _capsule_refresh_opencode [] {
    let src = ($env.HOME | path join ".local" "share" "opencode" "auth.json")
    if ($src | path exists) {
        _capsule_creds_write "opencode-auth.json" (open --raw $src)
    } else {
        _capsule_creds_drop "opencode-auth.json"
    }
}

# _capsule_refresh_creds (R3, R4, R5): export the host's credential material
# into one 0700 directory, four files at 0600. Each file is written only when
# its host source answers and REMOVED when it does not.
#
# Notably absent, and each absence measured rather than assumed: the whole of
# `~/.claude` (it holds history.jsonl and projects/ — every transcript from
# every project, and a capsule is where third-party code runs), `~/.claude.json`
# itself (host-path settings that fail once per prompt), and
# `~/.local/share/opencode` (the SQLite store above). R4's purpose — the
# preinstalled agents work with no login flow — is met by the four files.
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

# _capsule_cred_mounts (R1, R2, R3, R5): the `-v` flags, in order, that go
# BETWEEN the workspace bind and the image name.
#
# `:ro` ON EVERY ONE, and it is not decoration: nothing the container does
# can write back to the host's keys or config. The SSH keys in particular are
# copied container-local by the setup script precisely because their modes
# must be changed without touching the host copy.
#
# A SOURCE THAT DOES NOT EXIST IS SKIPPED, NOT PASSED: docker materialises a
# missing bind source as an empty DIRECTORY on the host, and a `~/.gitconfig`
# turned into a directory is real damage.
#
# Two staleness notes. `~/.gitconfig` and the setup script are FILE binds, so
# a host edit that replaces the file (`git config` writes by rename) is
# invisible to containers that already exist — `capsule --rebuild` is the
# fix, and that is acceptable for identity and aliases. And a capsule created
# BEFORE C.3 landed has no credential mounts at all, because docker cannot
# add mounts to an existing container: `capsule --rebuild` is again the fix.
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
#
# THE PICKER IS A TELEVISION AD-HOC CHANNEL, NOT A HAND-ROLLED TUI. 04-shell's
# invariant I3 gives every picker screen to tv and names exactly one exception
# (fzf behind `zi`), so a second hand-rolled picker would be a new decision.
# Ad-hoc (`^tv --source-command …`, no channel argument) rather than a cable
# file, because a cable file would put a capsule surface inside
# ~/.config/television, which 04-shell/04 owns.
#
# EVERY TV CALL GOES THROUGH `^tv`, for the same reason every docker call goes
# through `^docker`: a PATH shim can then observe it, so
# tests/capsule-recents.sh drives the real picker path against a recording
# shim and never needs a terminal.

# _capsule_recents_read (R4): the store, pruned on read. A directory that no
# longer exists is dropped AND the pruned list is written back, so a dead
# entry leaves the picker for good instead of being filtered on every open.
# The write-back is non-fatal, like _capsule_record's: a store that cannot be
# rewritten must still be pickable.
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

# _capsule_shquote: POSIX single-quote one path for the source command tv
# runs through sh — everything inside '' is literal, and an embedded quote is
# closed, escaped and reopened. A LOCAL helper and not finder.nu's: this file
# parses standalone under `nu -n` and the gate sources it directly, so no def
# here may belong to another module.
def _capsule_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

# _capsule_recents_pick (R2, R3): the picker screen. Returns the chosen
# directory, or "" when the pick was aborted.
#
# The flag set, every flag load-bearing, measured against television 0.15.9 on
# 2026-08-23:
#   --input-header "Recent"  is R3's mode feedback, and the picker surface is
#       its host because the WezTerm status bar is clock-only and
#       set_left_status is never called (finding C-5). tv defaults this title
#       to the channel name, which for an ad-hoc channel says nothing.
#   --no-sort  keeps the source order, and the source order IS the recency
#       order (R1: most recent first). Without it tv reorders by match
#       quality and the newest entry is no longer on top.
#   --keybindings 'enter="confirm_selection"'  confirms the pick whatever
#       ~/.config/television/config.toml binds — that file belongs to
#       04-shell/04, and an ad-hoc channel has no prototype of its own to
#       carry the binding. The grammar is key="action" and tv validates it
#       eagerly: the inverse config-file form `confirm_selection = "enter"`
#       exits 1 with `Error parsing CLI arguments`, so a typo is loud rather
#       than silent.
#   --no-preview  a list of directories has nothing to preview.
def _capsule_recents_pick [dirs: list] {
    let src = $"printf '%s\\n' ($dirs | each {|d| _capsule_shquote $d } | str join ' ')"
    let raw = (try {
        ^tv --source-command $src --input-header "Recent" --no-sort --no-preview --keybindings 'enter="confirm_selection"'
    } catch { "" })
    $raw | lines | where {|l| ($l | str trim) != "" } | get -o 0 | default "" | str trim
}

# capsule [dir] [--rebuild] — mount a directory (default: $env.PWD) into its
# per-directory dev container and attach an interactive zsh at /workspace.
def capsule [dir?: path, --rebuild] {
    # 1 — the target. Everything downstream uses $target only (R5).
    let target = ($dir | default $env.PWD | path expand)
    if ($target | path type) != "dir" {
        error make {msg: $"capsule: not a directory: ($target)"}
    }
    # 2 — preconditions, named.
    if (which docker | is-empty) {
        error make {msg: "capsule: docker not found on PATH — start Docker Desktop"}
    }
    if not ((_capsule_dockerfile) | path exists) {
        error make {msg: $"capsule: (_capsule_dockerfile) is missing — run chezmoi apply"}
    }
    # 3 — the name and its container state. Resolved BEFORE the build now,
    # because C.3's credential refresh has to know whether this invocation is
    # a create or an attach: the create path pays for the export up front,
    # the attach path must not.
    let name = (_capsule_name $target)
    let state = (_capsule_state $name)
    # 4 — the credential export (C.3 R3/R4/R5). AFTER the docker and
    # Dockerfile preconditions, never before: C.2's gate asserts that a
    # missing docker means NOTHING happened, and that has to include leaving
    # no credential directory behind.
    #
    # SYNCHRONOUS ON THE CREATE PATH, BACKGROUNDED ON THE ATTACH PATH. The
    # mount source must exist before `docker run`, and a cold start is
    # dominated by docker anyway — but the export costs ~1.5s, which would
    # break C.2 R2's "well under one second" warm attach. Backgrounded, the
    # parent then blocks in `docker exec` for the whole session, so the job
    # finishes long before anything inside reads a credential; and because
    # the creds path is a DIRECTORY bind, the fresh token appears inside the
    # already-running session rather than only on the next mount.
    if $rebuild or not $state.exists {
        _capsule_refresh_creds
    } else {
        job spawn { _capsule_refresh_creds } | ignore
    }
    # 5 — build when forced or when the Dockerfile hash no longer matches the
    # image label (R3, R4). Otherwise never — no implicit rebuild.
    if $rebuild or ((_capsule_hash) != (_capsule_image_hash)) { _capsule_build }
    # 6 — a container of this name that lacks the capsule.dir label is
    # foreign: never adopt, never remove — checked BEFORE the --rebuild rm,
    # so even a forced rebuild cannot destroy someone else's container.
    if $state.exists and ($state.dir_label | is-empty) {
        error make {msg: $"capsule: a container named ($name) exists but was not created by capsule — remove or rename it yourself"}
    }
    # 7 — only --rebuild recreates (R4). The auto path never removes a
    # container: a hash-triggered rebuild updated the image only, and the
    # existing container is attached as-is.
    # The removal below is covered by step 6's dir_label refusal, NOT by
    # _capsule_owned — the site roster and both guards are enumerated at
    # `capsule clean`.
    if $rebuild and $state.exists { ^docker rm -f $name | ignore }
    let exists = ($state.exists and not $rebuild)
    if not $exists {
        # 8 — create, detached; the image's CMD ["sleep","infinity"] idles it.
        # The credential binds sit between the workspace bind and the image
        # name, all `:ro` (C.3).
        ^docker run -d --name $name --label $"($CAPSULE_DIR_LABEL)=($target)" -v $"($target):/workspace" ...(_capsule_cred_mounts) $CAPSULE_IMAGE | ignore
    } else if not $state.running {
        # 9 — exists but stopped: start and attach (R2).
        ^docker start $name | ignore
    }
    # 10 — first-run credential setup (C.3 spec02), CREATE PATH ONLY. It runs
    # as `dev`, the image's unprivileged user: C.1 R5 already creates that
    # user and the script writes only inside $HOME, so the exec carries
    # neither a user override nor any privilege escalation. The legacy setup
    # script ran with root privileges and created users itself; none of that
    # survives the consolidation. The gate greps this file for both
    # spellings, so they are kept out of this comment entirely and a hit is
    # proof of a regression.
    #
    # A non-zero exit is one stderr line and the flow CONTINUES to the
    # attach, so a broken setup leaves a usable container to debug in rather
    # than no container at all.
    if not $exists and ((_capsule_setup_script) | path exists) {
        try {
            ^docker exec $name bash /opt/capsule/setup-credentials.sh
        } catch {
            print -e "capsule: /opt/capsule/setup-credentials.sh failed — attaching anyway; credentials may be incomplete"
        }
    }
    # 11 — record AFTER the container is confirmed up, BEFORE the attach,
    # because exec blocks until the shell exits (R7).
    _capsule_record $target
    # 12 — attach. The image's WORKDIR /workspace puts the shell in the
    # mounted directory; no -w flag to drift from it.
    ^docker exec -it $name zsh
}

# capsule list (R6): one row per capsule this tool owns — name, the directory
# it was made from, running or stopped.
def "capsule list" [] {
    _capsule_owned | select name dir status
}

# capsule clean [--all] (R6): remove the STOPPED capsules; a bare invocation
# never kills a running container — the cheap mistake has to be the safe one.
# --all additionally stops and removes the running ones. Returns the removed
# names; an empty set returns an empty list and touches nothing.
#
# THE THREE `docker rm` SITES, AND THE GUARD OVER EACH. Enumerated, never
# claimed universally: what stood here was a universal claim, and it was
# measurably false — it said every removal went through the _capsule_owned
# set, and the `--rebuild` recreate never reads that set at all.
#   * `capsule` step 7, the `--rebuild` recreate — guarded by step 6's
#     dir_label refusal. See _capsule_state for why that field is
#     load-bearing.
#   * the stopped branch below — guarded by _capsule_owned.
#   * the running branch below, --all only — guarded by _capsule_owned.
#
# The two guards are not the same test. _capsule_owned is label-key AND name
# prefix; step 6 tests the label's VALUE. They agree on every container this
# tool can create, because the create line always writes a non-empty
# capsule.dir. They diverge on one input nothing here can produce: a
# container someone else named capsule-* and labelled with an EMPTY
# capsule.dir. Step 6 refuses that one; clean removes it.
#
# tests/capsule-lifecycle.sh declares this list as RM_SITES and asserts set
# equality against the file, so a fourth site turns that gate red until the
# roster and this comment are updated with it.
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

# capsule recent (R2): pick a recently mounted directory and mount it. The
# pick funnels straight back into `capsule`, so there is exactly one mount
# path (the epic's one-entry-path acceptance) and this def knows nothing
# about images, names or containers.
#
# THE TTY GUARD IS $nu.is-interactive, and it fails FIRST. tv has no headless
# mode: run without a terminal it aborts with "television had a problem and
# crashed" and writes a crash report (measured 0.15.9, 2026-08-23), so the
# clean error has to come before the call. Ctrl+Shift+O reaches this def
# through `nu --execute`, where $nu.is-interactive is TRUE — measured on
# nushell 0.114.1, 2026-08-23; it is false under `-c`, which is why the
# hermetic gate drives the helpers rather than this def.
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
