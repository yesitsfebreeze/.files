#!/usr/bin/env nu

# Gate for the `help` content model — home/dot_config/nushell/help/*.nuon.
# Spec: .mi/prd/06-help/01-content-model/prd.md (R1-R3, R9 and the coverage
# requirements R4-R8).
#
#   nu tests/help-content-model.nu
#
# Prints one line per violation and exits non-zero if there are any. It is
# deliberately strict: an unknown field is an error, not a shrug, because the
# renderers and the drift check read these files as an interface.
#
# What it does NOT check, and cannot: whether a `verify` target actually
# resolves against a live shell, editor or terminal. That is `help --check`
# (.mi/prd/06-help/04-drift-check), and it needs a deployed configuration.

const REQUIRED = ["title" "use" "topic" "mode" "verify" "source"]
const OPTIONAL = ["key" "cmd" "also" "why"]

const MODES = ["shell" "nvim:normal" "nvim:visual" "nvim:insert" "terminal" "container"]

# kind -> required fields, optional fields. `kind` itself is always required.
const VERIFY_KINDS = {
    "keybinding": {req: ["name"], opt: []}
    "alias": {req: ["name"], opt: []}
    "command": {req: ["name"], opt: []}
    "nvim-map": {req: ["mode" "lhs"], opt: ["desc" "scope"]}
    "wezterm-key": {req: ["key" "mods"], opt: ["table"]}
    "prose": {req: [], opt: []}
}

const NVIM_MAP_MODES = ["n" "v" "x" "i" "o" "t" "c" "s"]
const NVIM_MAP_SCOPES = ["global" "buffer"]

# Transcribed from the node's coverage requirements, NOT read back out of the
# data files — that is the whole point. If a requirement names a surface and no
# entry documents it, this list is what notices.
const COVERAGE = {
    # R4 — shell
    "shell.nuon": [
        "Ctrl-R" "Alt-R" "Up / Down" "Shift+Up / Shift+Down"
        "Ctrl-Space / F1" "Ctrl-T" "Ctrl-Q" "Esc"
        "z <query>" "zi" "zz" "zl <query>" "zc <query>" "cdi" "<word>" "cd <path>"
        "ls" "ls -D" "l / ll / la"
        "cat <file>" "grep" "g" "lg" "nv / vi" "nn" "q / :q / /exit" "rr"
        "bb / ba" "cf <file>" "pass <tab>"
        "cc [...args]" "cr [...args]"
    ]
    # R5 — Neovim
    "nvim.nuon": [
        "<leader>"
        "<C-h> <C-j> <C-k> <C-l>" "<C-Up> <C-Down> <C-Left> <C-Right>"
        "<leader>| and <leader>-" "<S-h> <S-l> <leader>bd" "<A-j> <A-k>"
        "<C-d> <C-u> n N" "< and > (visual)" "<leader>w and <leader>q"
        "<leader>p (visual)"
        "<leader>ff and <leader><space>" "<leader>fg" "<leader>fb" "<leader>fh"
        "<Tab> <S-Tab> <CR> (telescope)"
        "gd and gI" "<leader>rn and <leader>ca" "Neovim's own LSP keys"
        "<Tab> <S-Tab> <C-n> <C-p> <C-Space> <C-e>"
        "<leader>e" "<leader>cf"
        "<S-Up> <S-Down> <S-Left> <S-Right>" "h j k l (visual)"
        "<C-c> (visual)" "<C-v> (visual)"
        "<leader>t"
    ]
    # R6 — terminal. `Cmd+N` is knowingly absent; see terminal.nuon's header.
    "terminal.nuon": [
        "F5 <digit>" "F5 <letter>" "Ctrl+Shift+Q" "nine tabs"
        "Ctrl+Shift+D" "Ctrl+Shift+B" "Ctrl+Shift+S" "Ctrl+Shift+T"
    ]
    # R7 — capsule
    "capsule.nuon": [
        "capsule [dir]" "capsule --rebuild" "capsule list" "capsule clean"
    ]
}

# R8 — the concept entries, which must exist AND must be prose.
const CONCEPTS = ["mkcd" "<word>" "tv channel" "credentials in a capsule"]

def id [e: record] {
    if ("key" in ($e | columns)) { $e.key } else if ("cmd" in ($e | columns)) { $e.cmd } else { "<unidentified>" }
}

def main [dir?: path] {
    let dir = ($dir | default ($env.FILE_PWD | path dirname | path join "home" "dot_config" "nushell" "help"))
    mut errors = []

    if not ($dir | path exists) {
        print -e $"content dir not found: ($dir)"
        exit 1
    }

    let topics = (open ($dir | path join "topics.nuon"))
    let topic_ids = ($topics | get id)
    if ($topic_ids | is-empty) {
        print -e "topics.nuon defines no topics — refusing to pass a check with nothing to check"
        exit 1
    }
    for t in $topics {
        let cols = ($t | columns)
        for f in ["id" "title" "summary"] {
            if not ($f in $cols) { $errors = ($errors | append $"topics.nuon: topic ($t.id? | default '?') is missing `($f)`") }
        }
    }

    let files = ($COVERAGE | columns)
    mut all = []

    for file in $files {
        let path = ($dir | path join $file)
        if not ($path | path exists) {
            $errors = ($errors | append $"($file): missing — R1 names one file per surface")
            continue
        }
        let entries = (open $path)
        if ($entries | is-empty) {
            $errors = ($errors | append $"($file): no entries")
            continue
        }
        for e in $entries {
            let cols = ($e | columns)
            let eid = (id $e)
            let at = $"($file) [($eid)]"

            # R2 — required fields, and exactly one of key/cmd
            for f in $REQUIRED {
                if not ($f in $cols) { $errors = ($errors | append $"($at): missing required field `($f)`") }
            }
            let has_key = ("key" in $cols)
            let has_cmd = ("cmd" in $cols)
            if ($has_key and $has_cmd) { $errors = ($errors | append $"($at): carries both `key` and `cmd` — R2 wants one") }
            if (not $has_key) and (not $has_cmd) { $errors = ($errors | append $"($at): carries neither `key` nor `cmd`") }
            for f in $cols {
                if not ($f in ($REQUIRED | append $OPTIONAL)) { $errors = ($errors | append $"($at): unknown field `($f)`") }
            }

            # R3 — topic is one of the nine
            if ("topic" in $cols) and (not ($e.topic in $topic_ids)) {
                $errors = ($errors | append $"($at): topic `($e.topic)` is not in topics.nuon")
            }
            # R2 — mode is one of the six
            if ("mode" in $cols) and (not ($e.mode in $MODES)) {
                $errors = ($errors | append $"($at): mode `($e.mode)` is not one of ($MODES | str join ', ')")
            }

            # R9 — writing rules
            if ("title" in $cols) {
                if ($e.title | str trim | is-empty) { $errors = ($errors | append $"($at): empty title") }
                if ($e.title | str contains "\n") { $errors = ($errors | append $"($at): title spans more than one line") }
                if ($e.title | str ends-with ".") { $errors = ($errors | append $"($at): title ends with a period") }
            }
            if ("use" in $cols) {
                if ($e.use | str trim | is-empty) { $errors = ($errors | append $"($at): empty use") }
                if ($e.use | str starts-with $eid) { $errors = ($errors | append $"($at): use opens by restating the key — R9 wants the gesture") }
            }

            # R2 — verify is a non-empty list of typed targets
            if ("verify" in $cols) {
                let v = $e.verify
                if not ((($v | describe -d).type) in ["list" "table"]) {
                    $errors = ($errors | append $"($at): verify is not a list")
                } else if ($v | is-empty) {
                    $errors = ($errors | append $"($at): verify is an empty list — use [{kind: \"prose\"}] for an entry with no live handle")
                } else {
                    for t in $v {
                        let tc = ($t | columns)
                        if not ("kind" in $tc) {
                            $errors = ($errors | append $"($at): verify target with no `kind`")
                            continue
                        }
                        if not ($t.kind in ($VERIFY_KINDS | columns)) {
                            $errors = ($errors | append $"($at): unknown verify kind `($t.kind)`")
                            continue
                        }
                        let shape = ($VERIFY_KINDS | get $t.kind)
                        for f in $shape.req {
                            if not ($f in $tc) { $errors = ($errors | append $"($at): ($t.kind) target is missing `($f)`") }
                        }
                        for f in $tc {
                            if not ($f in (["kind"] | append $shape.req | append $shape.opt)) {
                                $errors = ($errors | append $"($at): ($t.kind) target has unknown field `($f)`")
                            }
                        }
                        if ($t.kind == "nvim-map") and ("mode" in $tc) and (not ($t.mode in $NVIM_MAP_MODES)) {
                            $errors = ($errors | append $"($at): nvim-map mode `($t.mode)` is not a Neovim mode letter")
                        }
                        if ($t.kind == "nvim-map") and ("scope" in $tc) and (not ($t.scope in $NVIM_MAP_SCOPES)) {
                            $errors = ($errors | append $"($at): nvim-map scope `($t.scope)` is not global or buffer")
                        }
                    }
                }
            }

            # `source` must point at a PRD that exists, or the browser's
            # ctrl-o opens nothing.
            #
            # TRANSITIONAL: the PRD tree is mid-conversion from flat prose
            # (`04-shell/05-history.md`) to board nodes
            # (`04-shell/05-history/prd.md`). Sources are written in node form,
            # which is where the tree is going and what this node's own links
            # use. Where only the flat form exists yet, that is counted and
            # printed, not failed — a source matching NEITHER form is still an
            # error, so a typo cannot hide here. Delete this fallback (and the
            # `pending` counter) once the conversion has landed.
            mut pending_this = 0
            if ("source" in $cols) {
                let repo = ($env.FILE_PWD | path dirname)
                let node_form = ($repo | path join $e.source)
                let flat_forms = [
                    ($repo | path join ($e.source | str replace --regex '/prd\.md$' '.md'))
                    ($repo | path join ($e.source | path dirname | path join "00-epic.md"))
                ]
                if not ($node_form | path exists) {
                    if ($flat_forms | any {|f| $f | path exists }) {
                        $pending_this = 1
                    } else {
                        $errors = ($errors | append $"($at): source `($e.source)` exists in neither node nor flat form")
                    }
                }
            }

            $all = ($all | append {file: $file, id: $eid, entry: $e, source_pending: $pending_this})
        }
    }

    # `also` has to resolve — a related-entry pointer to nothing is worse
    # than no pointer.
    let ids = ($all | get id)
    for row in $all {
        let cols = ($row.entry | columns)
        if ("also" in $cols) {
            for a in $row.entry.also {
                if not ($a in $ids) {
                    $errors = ($errors | append $"($row.file) [($row.id)]: also references `($a)`, which is not an entry")
                }
            }
        }
    }

    # R4-R8 — coverage
    for file in $files {
        let want = ($COVERAGE | get $file)
        let have = ($all | where file == $file | get id)
        for w in $want {
            if not ($w in $have) { $errors = ($errors | append $"($file): nothing documents `($w)` — named by the coverage requirement") }
        }
    }
    for c in $CONCEPTS {
        let hit = ($all | where id == $c)
        if ($hit | is-empty) {
            $errors = ($errors | append $"concept entry `($c)` is missing — R8")
        } else {
            let kinds = ($hit | first | get entry.verify | get kind)
            if $kinds != ["prose"] {
                $errors = ($errors | append $"concept entry `($c)` is not verify: prose — R8")
            }
        }
    }

    let prose = ($all | where {|r| ($r.entry.verify | get kind) == ["prose"]} | length)
    let pending = ($all | get source_pending | math sum)
    print $"help content model: ($all | length) entries across ($files | length) files, ($topic_ids | length) topics, ($prose) prose-only"
    if $pending > 0 {
        print $"  note: ($pending) entries name a source that only exists in pre-board flat form yet"
    }
    print ($all | group-by {|r| $r.entry.topic } | items {|k, v| {topic: $k, entries: ($v | length)} })

    if ($errors | is-empty) {
        print "ok"
    } else {
        print -e $"($errors | length) violation(char lparen)s(char rparen):"
        for e in $errors { print -e $"  ($e)" }
        exit 1
    }
}
