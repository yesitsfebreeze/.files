#!/usr/bin/env nu

# Gate for the `help` content model — home/dot_config/nushell/help/*.nuon.
# Spec: .mi/prd/06-help/01-content-model/prd.md — R1 format, R2 entry schema,
# R3 topics, R4 concept entries, R5 writing rules — plus the surface lists of
# its `coverage/` child, R1 shell · R2 nvim · R3 terminal · R4 capsule.
#
# The numbers moved on 2026-08-20 when the node split: the four coverage
# requirements left for the child, so the old R8 is R4 and the old R9 is R5.
# The node's own renumbering table is the map. Comments below cite the numbers
# as they are now, not as the commit that wrote them found them.
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

# R3 — the manual's spine, transcribed from the node's R3 in the order R3 gives
# it. Deliberately NOT read out of `topics.nuon`: the topic list used to be read
# out of the data being checked, which meant the check only asserted referential
# integrity and could not notice the data drifting from the requirement.
# Measured, not assumed: with the old code, renaming `git` to `vcs` and deleting
# `history` both still exited 0. The order is part of the requirement ("ordered
# by how often it's needed"), so it is compared as a list, not as a set.
const TOPICS = ["navigate" "find" "history" "edit" "git" "containers" "terminal" "agents" "config"]

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
    # coverage R1 — shell
    "shell.nuon": [
        "Ctrl-R" "Alt-R" "Up / Down" "Shift+Up / Shift+Down"
        "Ctrl-Space / F1" "Ctrl-T" "Ctrl-Q" "Esc"
        "z <query>" "zi" "zz" "zl <query>" "zc <query>" "cdi" "<word>" "cd <path>"
        "ls" "ls -D" "l / ll / la"
        "cat <file>" "grep" "g" "lg" "nv / vi" "nn" "q / :q / /exit" "rr"
        "bb / ba" "cf <file>" "pass <tab>"
        "cc [...args]" "cr [...args]"
    ]
    # coverage R2 — Neovim
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
    # coverage R3 — terminal. `Cmd+N` is knowingly absent; see terminal.nuon's
    # header.
    #
    # The last three are ahead of that requirement's wording, deliberately. It
    # names "F5 jump mode, tab/window/quit keys, and the capsule bindings";
    # `Ctrl+Shift+X`, `Ctrl+V` and `Ctrl+C` are none of those, but they ARE
    # keybindings the live terminal config defines and
    # `capabilities-terminal.md` rates take-over-as-is (C 4/U 9, C 1/U 8,
    # C 3/U 9), so the coverage child's acceptance — "every keybinding defined
    # in the terminal config has an entry" — cannot be met without them. An
    # amendment naming them is requested against that child; until it lands
    # this list asserts slightly more than the requirement says, which is the
    # safe direction. `F6` (DEFER) and the `Ctrl+Shift+B` wallpaper pipeline
    # (DO NOT PORT) are the two live keys deliberately NOT listed.
    "terminal.nuon": [
        "F5 <digit>" "F5 <letter>" "Ctrl+Shift+Q" "nine tabs"
        "Ctrl+Shift+D" "Ctrl+Shift+B" "Ctrl+Shift+S" "Ctrl+Shift+T"
        "Ctrl+Shift+X" "Ctrl+V" "Ctrl+C"
    ]
    # coverage R4 — capsule
    "capsule.nuon": [
        "capsule [dir]" "capsule --rebuild" "capsule list" "capsule clean"
    ]
}

# R4 — the concept entries, which must exist AND must be prose.
const CONCEPTS = ["mkcd" "<word>" "tv channel" "credentials in a capsule"]

def id [e: record] {
    if ("key" in ($e | columns)) { $e.key } else if ("cmd" in ($e | columns)) { $e.cmd } else { "<unidentified>" }
}

# R5 — "`use` describes the real gesture, never restates the key". The gateable
# clause is the opening: a key entry whose `use` starts with its own key has
# written the title again instead of the gesture.
#
# Backticks count, and that is the whole repair. The first version compared the
# bare id only. Measured across all 84 entries: bare-prefix hits 0,
# backtick-prefix hits 24 — the check fired on nothing at all, defeated by one
# character, while reading like the thing that held R5 up. `selftest` below
# proves it can still fire, on every run.
#
# Scoped to `key` entries on purpose, and this is a reading of R5 rather than a
# narrowing of it: R5 says "never restates the *key*". A `cmd` entry has no key
# to restate — for `g` or `capsule list` the invocation *is* the gesture,
# because typing it is what you do. Naming the key mid-sentence is likewise
# fine; R5's own example ("press `F5`, then a digit 1-9") does exactly that.
def restates-key [use: string, eid: string] {
    ($use | str starts-with $eid) or ($use | str starts-with $"`($eid)`")
}

# R5 — "`title` is one line, imperative, no trailing period". One-line and the
# trailing period are checked in `main`; "imperative" had no test at all, so a
# clause R5 calls gated was two thirds gated and the remaining third read as
# covered.
#
# Imperative is decided from its failure modes rather than by tagging parts of
# speech, and all three are visible in the first word: a gerund ("Jumping to a
# tab"), a third-person verb ("Jumps to a tab"), or a noun phrase ("The tab
# jumper", "A faster route to ..."). Bare-verb openers are left alone, which is
# what an imperative is.
#
# The -s allowlist is not a curiosity: several perfectly imperative verbs end in
# s, and `Press` opens titles in a manual about keys more than any other word.
#
# Measured before this was written, over all 84 titles: 0 end in `-ing`, 0 end
# in `-s`, 0 open with a determiner — so it finds no violation today. That is a
# passing check with 84 subjects, not the empty check law 3 refuses: `selftest`
# below is what tells the two apart, and this corpus has already shipped one
# check that could not fire (see `restates-key`).
const NOUN_PHRASE_OPENERS = ["the" "a" "an" "this" "that" "these" "those" "your" "my" "our" "you" "it" "there" "here" "when" "how" "what" "why" "where" "which" "whether" "if" "to" "for" "with" "about" "into" "from" "some" "every" "each" "any" "no"]
const IMPERATIVE_S_VERBS = ["press" "pass" "focus" "cross" "process" "dismiss" "discuss" "toss" "miss" "address" "express" "compress" "access" "guess"]

def non-imperative [title: string] {
    let first = ($title | str trim | split row " " | first
        | str replace --all --regex '[^A-Za-z-]' '' | str lowercase)
    if ($first | is-empty) { return "" }
    if ($first in $NOUN_PHRASE_OPENERS) {
        return $"opens with `($first)`, which starts a noun phrase rather than telling the reader to do something"
    }
    if ($first | str ends-with "ing") {
        return $"opens with the gerund `($first)`"
    }
    if ($first | str ends-with "s") and (not ($first in $IMPERATIVE_S_VERBS)) {
        return $"opens with the third-person `($first)` — a title describes the reader's action, in the form they would be told to take it"
    }
    ""
}

# Law 3, rung 2: a gate that cannot fire is a wish, and this one silently could
# not for a whole cycle. Positive and negative controls run every time, so the
# next person to touch `restates-key` finds out here rather than in review.
def selftest [] {
    mut bad = []
    if (non-imperative "Jump to a tab by its number") != "" {
        $bad = ($bad | append "selftest: non-imperative rejects a bare-verb title, which is the form R5 asks for")
    }
    if (non-imperative "Press Ctrl-X twice to copy") != "" {
        $bad = ($bad | append "selftest: non-imperative rejects `Press`, an imperative verb that ends in s — the allowlist is what keeps the -s rule usable")
    }
    if (non-imperative "Fuzzy-search the shell history") != "" {
        $bad = ($bad | append "selftest: non-imperative rejects a hyphenated verb")
    }
    if (non-imperative "Jumping to a tab by its number") == "" {
        $bad = ($bad | append "selftest: non-imperative misses a gerund title")
    }
    if (non-imperative "Jumps to a tab by its number") == "" {
        $bad = ($bad | append "selftest: non-imperative misses a third-person title")
    }
    if (non-imperative "The fastest way to a tab") == "" {
        $bad = ($bad | append "selftest: non-imperative misses a noun-phrase title")
    }
    if not (restates-key "`Ctrl-X` closes the pane" "Ctrl-X") {
        $bad = ($bad | append "selftest: restates-key misses the backticked form — the corpus writes every id in backticks, so this is the form that matters")
    }
    if not (restates-key "Ctrl-X closes the pane" "Ctrl-X") {
        $bad = ($bad | append "selftest: restates-key misses the bare form")
    }
    if (restates-key "Press `Ctrl-X`, then a digit 1-9" "Ctrl-X") {
        $bad = ($bad | append "selftest: restates-key fires on a gesture that merely names its key, which R5 asks for")
    }
    $bad
}

def main [dir?: path] {
    let dir = ($dir | default ($env.FILE_PWD | path dirname | path join "home" "dot_config" "nushell" "help"))
    mut errors = (selftest)

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
    if $topic_ids != $TOPICS {
        $errors = ($errors | append $"topics.nuon: the spine is `($topic_ids | str join ', ')` but R3 names `($TOPICS | str join ', ')` — same nine ids, same order")
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

            # R5 — writing rules
            if ("title" in $cols) {
                if ($e.title | str trim | is-empty) { $errors = ($errors | append $"($at): empty title") }
                if ($e.title | str contains "\n") { $errors = ($errors | append $"($at): title spans more than one line") }
                if ($e.title | str ends-with ".") { $errors = ($errors | append $"($at): title ends with a period") }
                let mood = (non-imperative $e.title)
                if $mood != "" { $errors = ($errors | append $"($at): title is not imperative — it ($mood)") }
            }
            if ("use" in $cols) {
                if ($e.use | str trim | is-empty) { $errors = ($errors | append $"($at): empty use") }
                if $has_key and (restates-key $e.use $eid) {
                    $errors = ($errors | append $"($at): use opens by restating the key — R5 wants the gesture, as in 'press ($eid), then …', not the title again")
                }
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

    # the coverage child's R1-R4 (the surface lists), then this node's R4
    # (the concept entries)
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
            $errors = ($errors | append $"concept entry `($c)` is missing — R4")
        } else {
            let kinds = ($hit | first | get entry.verify | get kind)
            if $kinds != ["prose"] {
                $errors = ($errors | append $"concept entry `($c)` is not verify: prose — R4")
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
