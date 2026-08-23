#!/usr/bin/env nu

# Gate for the `help` content model — home/dot_config/nushell/help/*.nuon.
# Spec: prds/06-help/01-content-model/prd.md — R1 format, R2 entry schema,
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
# (prds/06-help/04-drift-check), and it needs a deployed configuration.

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

# kind -> required fields, optional fields, and the fields whose value may be
# an explicit `null`. `kind` itself is always required.
#
# **`null` is a value here, not an absence, and the difference is the whole
# reason `nullable` exists as a field of its own.** `nvim-map`'s `desc` is
# three-state and every state means something different to the drift check:
#
#   field absent      — compare the live `desc` against this entry's `title`
#   desc: null        — the live map carries no description on purpose, so the
#                       drift check asserts existence only and never a mismatch
#                       (14 targets do this today)
#   desc: "some text" — the live map's description must equal that string
#
# The three states are README.md's rule, not this file's invention — see its
# "`verify` — a list of typed targets" section, which is where a writer meets
# them. `nullable` is that rule transcribed, the same way TOPICS and CONCEPTS
# transcribe theirs instead of reading them back out of the data.
#
# Measured before relying on it, because a table would have destroyed the
# distinction: nushell's `open` on a heterogeneous `.nuon` list keeps the
# records heterogeneous rather than null-filling them into a table, so a target
# that omits `scope` reads back with no `scope` column while one that writes
# `desc: null` reads back with a `desc` column holding null. Absence and null
# survive the round trip and are distinguishable, so the shape check can hold
# both rules at once.
const VERIFY_KINDS = {
    "keybinding": {req: ["name"], opt: [], nullable: []}
    "alias": {req: ["name"], opt: [], nullable: []}
    "command": {req: ["name"], opt: [], nullable: []}
    "nvim-map": {req: ["mode" "lhs"], opt: ["desc" "scope"], nullable: ["desc"]}
    "wezterm-key": {req: ["key" "mods"], opt: ["table"], nullable: []}
    "prose": {req: [], opt: [], nullable: []}
}

const NVIM_MAP_MODES = ["n" "v" "x" "i" "o" "t" "c" "s"]
const NVIM_MAP_SCOPES = ["global" "buffer"]

# --- value shape -------------------------------------------------------------
#
# R2 says every entry's fields are "present and well-typed". Until 2026-08-21
# that was gated as field *presence* plus closed-set *membership* and nothing
# else, so a field could be present, correctly named, and hold nothing:
#
#   verify: [{kind: "command", name: ""}]   exited 0
#   key: ""                                 exited 0, and the entry then had
#                                           no id, so every message about it
#                                           read `shell.nuon []`
#   source: ""                              exited 0 — `path join ""` is the
#                                           repo root, which exists
#
# laws.md 2, rung 1: "strict schemas at every boundary — required fields, no
# unknown keys, no silent default". Presence and membership were two thirds of
# a schema. These two predicates are the third, and they are deliberately ONE
# implementation used at all four boundaries this file reads (entry fields,
# verify targets, topics.nuon rows, why-review.nuon rows) rather than four
# spellings of the same idea — adding a fifth boundary should touch one place.
#
# Both return "" for a good value and the reason otherwise, so a caller reads
# as `let b = (bad-string $v); if $b != "" { ... }` everywhere.

def shape-of [v: any] { ($v | describe -d).type }

def bad-string [v: any] {
    let t = (shape-of $v)
    if $t != "string" { return $"is a ($t), not a string" }
    if ($v | str trim | is-empty) { return "is empty" }
    ""
}

def bad-string-list [v: any] {
    let t = (shape-of $v)
    if not ($t in ["list" "table"]) { return $"is a ($t), not a list" }
    if ($v | is-empty) { return "is an empty list" }
    for x in $v {
        let b = (bad-string $x)
        if $b != "" { return $"has an element that ($b)" }
    }
    ""
}

# The `verify` boundary, and the one place the shape layer could still throw.
#
# `record-list` used to check list-ness and never element-ness, so a `verify`
# holding a non-record reached `$t | columns` in the target loop and died with
# an uncaught `nu::shell::only_supports_this_input_type` at the first bad
# entry: exit 1, so it failed closed, but the reader got a stack trace instead
# of an entry id and the rest of the corpus went unreported. That asymmetry is
# what these two close — `bad-record-list` is `bad-string-list` with `record`
# where it says `string`, deliberately the same shape rather than a fifth
# spelling of the idea.
#
# No emptiness check here on purpose: the `verify` loop already reports an
# empty list with a message that tells the writer what to put there
# (`[{kind: "prose"}]`), and a second, blanker violation for the same fact
# would be noise.
def bad-record [v: any] {
    let t = (shape-of $v)
    if $t != "record" { return $"is a ($t), not a record" }
    ""
}

def bad-record-list [v: any] {
    let t = (shape-of $v)
    if not ($t in ["list" "table"]) { return $"is a ($t), not a list" }
    for x in $v {
        let b = (bad-record $x)
        if $b != "" { return $"has an element that ($b)" }
    }
    ""
}

# Every field an entry may carry, and the shape its value must have. `verify`
# is a list whose elements must be records; which *kind* of record each one is,
# and which fields that kind requires, is checked structurally further down.
const FIELD_SHAPES = {
    key: "string"
    cmd: "string"
    title: "string"
    use: "string"
    topic: "string"
    mode: "string"
    verify: "record-list"
    source: "string"
    also: "string-list"
    why: "string"
}

def bad-field [name: string, v: any] {
    let want = ($FIELD_SHAPES | get -o $name)
    if $want == null { return "" }   # unknown field: reported by the caller
    match $want {
        "string" => (bad-string $v)
        "string-list" => (bad-string-list $v)
        "record-list" => (bad-record-list $v)
        _ => ""
    }
}

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
        "cf <file>" "pass <tab>"
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
        "F5 <digit>" "Ctrl+Shift+<arrow>" "Ctrl+Shift+Q" "nine tabs"
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

# R2's `use` sub-box — "the actual gesture, in order, including what to press
# next and what comes back".
#
# **This is a vacuity floor and it is not that clause.** Say it plainly,
# because this corpus has already shipped two checks that read as enforcement
# and enforced nothing. Whether a `use` describes the *real* gesture is truth
# against a live surface: it is `coverage`'s R5 for the entries that have one,
# and for the 80 of 84 that have no deployed surface it cannot be decided here
# at all. Nothing below moves that.
#
# What it does decide is the one escape the node names by hand: replacing
# `capsule list`'s `use` with the single character `"x"` exited 0. A gesture
# has steps; one word is not an under-described gesture, it is an absent one.
#
# The floor is set from the corpus, not from taste. Measured 2026-08-21 over
# all 84 live entries: shortest `use` is 8 words (`nvim.nuon
# [<leader>w and <leader>q]`, 60 characters), next 9, mean 34. Five leaves
# three words of headroom under the shortest thing anyone has actually
# written, so this cannot fire on a real entry today — which is exactly why it
# is a floor against nothing rather than a rule about length. If a legitimate
# four-word `use` ever exists, the honest fix is to widen the floor with the
# new measurement recorded, not to delete the check.
const USE_MIN_WORDS = 5

def too-thin [use: string] {
    let n = ($use | split row " " | where {|w| ($w | str trim) != "" } | length)
    if $n < $USE_MIN_WORDS {
        $"is ($n) word-long, under the ($USE_MIN_WORDS)-word floor — a gesture has steps, and the shortest real `use` in this manual is 8 words"
    } else { "" }
}

# R5 — "`title` is one line, imperative, no trailing period". One-line and the
# trailing period are checked in `main`; "imperative" is decided here.
#
# **This check fails closed, and that is the repair.** The first version decided
# from three failure shapes visible in the first word — a gerund ("Jumping to a
# tab"), a third-person verb ("Jumps to a tab"), or one of 33 hardcoded
# determiners ("The fastest way to a tab"). Anything else passed, so anything
# the blocklist had not thought of passed. Three escapes were confirmed by hand
# and all exited 0: `Tab jumping by number` (gerund, not in first position),
# `Fast tab access by number` (adjective-led noun phrase), `Jumped to a tab by
# its number` (past tense). A blocklist of noun phrases is unbounded; the set of
# verbs a keyboard manual opens a title with is not.
#
# So the rule is inverted: the first word must be a base-form verb on the list
# below, and an unknown opener is an error rather than a shrug (laws.md 3, rung
# 1 — "an unknown name is an error, never an empty value"). Adding a verb is a
# deliberate one-line edit by someone who has read the title, which is the
# review this clause is entitled to.
#
# The list is seeded from the 51 distinct openers of the 84 live titles plus the
# ordinary manual verbs a later entry is likely to need. Compounds are
# head-final, so `fuzzy-search` is admitted by `search` and no compound needs
# listing. Verbs that genuinely end in `s` (`press`, `pass`, `focus`) are just
# members like any other — the old `-s` allowlist was a patch on a rule that no
# longer exists.
#
# It finds no violation in the current 84 titles. That is a passing check with
# 84 subjects, not the empty check law 3 refuses: `selftest` below is what tells
# the two apart, and this corpus has already shipped one check that could not
# fire (see `restates-key`).
const IMPERATIVE_VERBS = [
    # the 51 openers the live corpus uses
    "jump" "open" "search" "paste" "move" "copy" "reopen" "list" "understand"
    "rebuild" "drop" "use" "read" "close" "step" "run" "pick" "remove" "see"
    "freeze" "expect" "rename" "send" "switch" "grep" "find" "work" "format"
    "drive" "select" "save" "indent" "keep" "walk" "split" "resize" "clear"
    "show" "complete" "pull" "check" "write" "resume" "start" "spawn" "leave"
    "dump" "insert" "enter" "toggle" "press"
    # ordinary manual verbs, seeded so a later entry is not blocked on a
    # one-word edit here. Extend deliberately; every member is a base form.
    "add" "attach" "cancel" "confirm" "create" "cycle" "delete" "detach"
    "disable" "edit" "enable" "exit" "explore" "filter" "focus" "follow"
    "give" "hide" "install" "kill" "land" "load" "look" "make" "mark" "mount"
    "name" "navigate" "pass" "preview" "print" "push" "put" "quit" "reach"
    "refresh" "reload" "repeat" "replace" "reset" "restart" "restore" "scroll"
    "set" "sort" "stop" "swap" "take" "trim" "turn" "undo" "unmount" "view"
    "yank" "zoom"
]

# Kept only for the diagnostic: an unknown opener is a violation either way, but
# these three shapes get a message that names the mistake instead of the word.
const NOUN_PHRASE_OPENERS = ["the" "a" "an" "this" "that" "these" "those" "your" "my" "our" "you" "it" "there" "here" "when" "how" "what" "why" "where" "which" "whether" "if" "to" "for" "with" "about" "into" "from" "some" "every" "each" "any" "no"]

def non-imperative [title: string] {
    let first = ($title | str trim | split row " " | first
        | str replace --all --regex '[^A-Za-z-]' '' | str lowercase)
    if ($first | is-empty) { return "" }
    # head-final compounds: `fuzzy-search` is a `search`
    let head = ($first | split row "-" | last)
    if ($first in $IMPERATIVE_VERBS) or ($head in $IMPERATIVE_VERBS) { return "" }
    if ($first in $NOUN_PHRASE_OPENERS) {
        return $"opens with `($first)`, which starts a noun phrase rather than telling the reader to do something"
    }
    if ($first | str ends-with "ing") {
        return $"opens with the gerund `($first)`"
    }
    if ($first | str ends-with "s") {
        return $"opens with the third-person `($first)` — a title describes the reader's action, in the form they would be told to take it"
    }
    $"opens with `($first)`, which is not a base-form verb on IMPERATIVE_VERBS — either the title is not imperative, or the verb is new and belongs on that list"
}

# R5 — "`why` … never restates what `use` already said". This clause cannot be
# gated by word overlap, and that is measured twice over, not assumed:
#
#   whole-`why` containment of content words in `use`, over the 51 pairs that
#   carry a `why` — corpus mean 0.11, and the known defect `Ctrl+V` scored
#   0.097, rank 28 of 51 (below the mean);
#   best-sentence containment, computed on 2026-08-21 to see whether a finer
#   granularity separated them — corpus mean 0.157, and the known defect
#   `Ctrl+C` scored 0.167, rank 23 of 51, while `Ctrl+Shift+B` scored 0.143,
#   rank 27. Any threshold catching them fires on half the manual.
#
# The reason is that a good writer restates in different words: `Ctrl+C`'s `why`
# opened "One key for both because the terminal can tell them apart", which
# repeats a `use` that says "with text selected … with nothing selected" and
# shares almost no vocabulary with it. It takes a reader.
#
# So the clause is held on laws.md 3's third rung — a named reviewer who did not
# write the claim — and this is what makes that assignment real rather than a
# note in a README: every `why` is recorded in `why-review.nuon` against a
# digest of the exact `use`/`why` pair that was read. Add a `why`, or edit
# either field, and the digest stops matching and the gate fails until someone
# re-reads the pair and records it. The review stays human; the *obligation* to
# have done it is mechanical.
def why-digest [use: string, why: string] {
    $"($use)\n--\n($why)" | hash sha256 | str substring 0..15
}

# R2's `use` sub-box and R5's second clause — "`use` describes the real
# gesture, including what to press next and what comes back" — held the same
# way, and for the same reason: no lexical proxy decides it, so a reader does,
# and this makes the *obligation* to have read it mechanical.
#
# **The premise that kept this open for three sessions was wrong, and saying so
# is the point of this comment.** The box read "80 of 84 entries have no
# deployed surface to be checked against", so the clause was parked on
# `coverage`'s R5. But every entry carries a `source:` naming the PRD that
# specifies the capability, all 84 of those resolve (this file already enforces
# that, further down), and a PRD is exactly what a `use` is supposed to
# describe. 79 of the 84 additionally have a live route to read
# (`~/.config/nushell`, `~/.config/nvim`, `~/.config/wezterm` all exist); only
# `capsule.nuon`'s 5 have no surface at all, and their rows say so. The
# `Ctrl-T` defect this node cites as proof the clause was ungated was found by
# exactly that method — `config.nu:635` -> `config.nu:686` -> `finder.nu:33`.
# The method worked; what was missing was the obligation to run it.
#
# **The digest keys on `use` AND `source` together, and that is the difference
# from `why-digest`.** A row here says "this prose matches that spec", which is
# a claim about a pair — so editing *either* side has to invalidate it.
# Re-pointing an entry at a different PRD without re-reading the `use` against
# it is the drift this catches and `why-review.nuon` structurally cannot.
#
# Do NOT replace this with a text metric. Two were measured and both failed:
# whole-`why` containment (mean 0.11) and best-sentence containment (mean
# 0.157) each put the known defects at or below the corpus mean. That history
# is written out above `why-digest` and in README.md so a third is not built.
def use-digest [use: string, source: string] {
    $"($use)\n--\n($source)" | hash sha256 | str substring 0..15
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
    # The three escapes that the blocklist version let through, all confirmed
    # by hand at exit 0 before IMPERATIVE_VERBS replaced it. They are controls
    # rather than history: each one is a shape no blocklist catches.
    if (non-imperative "Tab jumping by number") == "" {
        $bad = ($bad | append "selftest: non-imperative misses a gerund that is not the first word — the escape a first-word blocklist cannot see")
    }
    if (non-imperative "Fast tab access by number") == "" {
        $bad = ($bad | append "selftest: non-imperative misses an adjective-led noun phrase")
    }
    if (non-imperative "Jumped to a tab by its number") == "" {
        $bad = ($bad | append "selftest: non-imperative misses a past-tense opener")
    }
    if (non-imperative "Frobnicate the widget") == "" {
        $bad = ($bad | append "selftest: non-imperative accepts an opener that is on no list — the check has stopped failing closed, which is the whole repair")
    }
    if (why-digest "a" "b") != (why-digest "a" "b") {
        $bad = ($bad | append "selftest: why-digest is not stable for one pair")
    }
    if (why-digest "a" "b") == (why-digest "a" "c") {
        $bad = ($bad | append "selftest: why-digest ignores a changed `why` — a recorded review would survive the edit it is supposed to notice")
    }
    if (why-digest "a" "b") == (why-digest "x" "b") {
        $bad = ($bad | append "selftest: why-digest ignores a changed `use` — a `why` restating a rewritten `use` would pass on the old review")
    }
    if (use-digest "a" "b") != (use-digest "a" "b") {
        $bad = ($bad | append "selftest: use-digest is not stable for one pair")
    }
    if (use-digest "a" "b") == (use-digest "x" "b") {
        $bad = ($bad | append "selftest: use-digest ignores a changed `use` — a rewritten gesture would keep the review of the old one")
    }
    # the control that separates this record from why-review.nuon: a review
    # says "this prose matches that spec", so re-pointing an entry at a
    # different spec has to invalidate it. Make the digest blind to `source`
    # and this is what says so.
    if (use-digest "a" "b") == (use-digest "a" "c") {
        $bad = ($bad | append "selftest: use-digest ignores a changed `source` — an entry could be re-pointed at a different PRD and keep a review that read it against the old one")
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
    # the value-shape predicates. The hole they close was present-but-empty, so
    # the controls that matter are the empty ones: each of these was a live
    # exit-0 before 2026-08-21.
    if (bad-string "a real value") != "" {
        $bad = ($bad | append "selftest: bad-string rejects an ordinary non-empty string")
    }
    if (bad-string "") == "" {
        $bad = ($bad | append "selftest: bad-string accepts the empty string — this is the hole R2 named, `verify: [{kind: \"command\", name: \"\"}]` exiting 0")
    }
    if (bad-string "   ") == "" {
        $bad = ($bad | append "selftest: bad-string accepts whitespace — a value that trims to nothing is nothing")
    }
    if (bad-string 5) == "" {
        $bad = ($bad | append "selftest: bad-string accepts a non-string — `well-typed` has to mean the type too")
    }
    if (bad-string null) == "" {
        $bad = ($bad | append "selftest: bad-string accepts null")
    }
    if (bad-string-list ["a" "b"]) != "" {
        $bad = ($bad | append "selftest: bad-string-list rejects an ordinary list of strings")
    }
    if (bad-string-list []) == "" {
        $bad = ($bad | append "selftest: bad-string-list accepts an empty list")
    }
    if (bad-string-list ["a" ""]) == "" {
        $bad = ($bad | append "selftest: bad-string-list accepts a list with an empty element — `also: [\"\"]` would point at nothing while looking populated")
    }
    if (bad-string-list "a") == "" {
        $bad = ($bad | append "selftest: bad-string-list accepts a bare string where a list is required")
    }
    if (bad-field "also" "not-a-list") == "" {
        $bad = ($bad | append "selftest: bad-field does not apply the list shape to `also`")
    }
    if (bad-field "title" "") == "" {
        $bad = ($bad | append "selftest: bad-field does not apply the string shape to `title`")
    }
    if (bad-field "title" "Jump to a tab") != "" {
        $bad = ($bad | append "selftest: bad-field rejects a good title")
    }
    # the `verify` element shape. Before 2026-08-21 the first of these returned
    # "" and the string then reached `$t | columns`, which threw
    # `only_supports_this_input_type` — the one boundary in this file that
    # crashed instead of reporting.
    if (bad-field "verify" ["foo"]) == "" {
        $bad = ($bad | append "selftest: bad-field accepts a `verify` element that is a string — that element reaches `$t | columns` and crashes the run, so one bad entry hides the whole corpus")
    }
    if (bad-field "verify" [{kind: "prose"}]) != "" {
        $bad = ($bad | append "selftest: bad-field rejects a well-formed `verify` list")
    }
    if (bad-record {kind: "prose"}) != "" {
        $bad = ($bad | append "selftest: bad-record rejects an ordinary record")
    }
    if (bad-record 5) == "" {
        $bad = ($bad | append "selftest: bad-record accepts an int")
    }
    if (bad-record null) == "" {
        $bad = ($bad | append "selftest: bad-record accepts null")
    }
    # the `use` vacuity floor. The first control is the escape the node names
    # by hand; the second is the shortest `use` the live manual actually
    # carries, and it must stay under the floor's ceiling.
    if (too-thin "x") == "" {
        $bad = ($bad | append "selftest: too-thin accepts a one-word `use` — that is the `capsule list` escape, exiting 0")
    }
    if (too-thin "Press `<leader>w` to save the buffer and `<leader>q` to close the window") != "" {
        $bad = ($bad | append "selftest: too-thin fires on a real `use` — the floor has risen above something someone wrote, and the measurement in the comment above it is stale")
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
            if not ($f in $cols) {
                $errors = ($errors | append $"topics.nuon: topic ($t.id? | default '?') is missing `($f)`")
                continue
            }
            let b = (bad-string ($t | get -o $f))
            if $b != "" { $errors = ($errors | append $"topics.nuon [($t.id? | default '?')]: `($f)` ($b)") }
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

            # R2 — and well-typed. Presence above, shape here: a field that is
            # present but holds "" or the wrong type used to pass.
            for f in $cols {
                let b = (bad-field $f ($e | get -o $f))
                if $b != "" { $errors = ($errors | append $"($at): `($f)` ($b)") }
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
            # the shape pass above already reported an absent or non-string
            # title, so these read a value they know is a non-empty string
            if ("title" in $cols) and ((bad-string $e.title) == "") {
                if ($e.title | str contains "\n") { $errors = ($errors | append $"($at): title spans more than one line") }
                if ($e.title | str ends-with ".") { $errors = ($errors | append $"($at): title ends with a period") }
                let mood = (non-imperative $e.title)
                if $mood != "" { $errors = ($errors | append $"($at): title is not imperative — it ($mood)") }
            }
            if ("use" in $cols) and ((bad-string $e.use) == "") {
                let thin = (too-thin $e.use)
                if $thin != "" { $errors = ($errors | append $"($at): use ($thin)") }
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
                        # a non-record element is reported and skipped, never
                        # walked into: `$t | columns` on a string used to throw
                        # `only_supports_this_input_type` and take the whole run
                        # with it, so one bad element hid every other violation
                        # in the corpus.
                        let bt = (bad-record $t)
                        if $bt != "" {
                            $errors = ($errors | append $"($at): verify target ($bt)")
                            continue
                        }
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
                                continue
                            }
                            # every field of every verify target is a non-empty
                            # string — an empty one is a target that resolves
                            # to nothing while looking well-formed, the hole
                            # R2 named: `[{kind: "command", name: ""}]` passed.
                            # The exception is a `nullable` field written as an
                            # explicit null, which is an assertion, not a gap.
                            let val = ($t | get -o $f)
                            if not (($val == null) and ($f in $shape.nullable)) {
                                let b = (bad-string $val)
                                if $b != "" { $errors = ($errors | append $"($at): ($t.kind) target's `($f)` ($b)") }
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

    # R5 — the `why` restatement clause, held by a recorded review because no
    # lexical proxy separates the defects (see `why-digest` above). What is
    # gated here is that the review exists and is current for the exact text
    # that is on disk.
    let review_path = ($dir | path join "why-review.nuon")
    if not ($review_path | path exists) {
        $errors = ($errors | append "why-review.nuon: missing — every `why` is held by a recorded review, and with no record there is nothing holding R5's restatement clause")
    } else {
        let review = (open $review_path)
        if ($review | is-empty) {
            print -e "why-review.nuon records no reviews — refusing to pass a check with nothing to check"
            exit 1
        }
        mut seen = []
        for r in $review {
            let rc = ($r | columns)
            for f in ["id" "file" "digest" "reviewer" "date"] {
                if not ($f in $rc) { $errors = ($errors | append $"why-review.nuon: a row is missing `($f)`") }
            }
            for f in $rc {
                if not ($f in ["id" "file" "digest" "reviewer" "author" "date" "note"]) {
                    $errors = ($errors | append $"why-review.nuon [($r.id? | default '?')]: unknown field `($f)`")
                    continue
                }
                let b = (bad-string ($r | get -o $f))
                if $b != "" { $errors = ($errors | append $"why-review.nuon [($r.id? | default '?')]: `($f)` ($b)") }
            }
            # laws.md 2, rung 3: "an independent reviewer is asked to refute
            # each claim". `author` records the session that wrote or last
            # revised the pair; where it is recorded, a reviewer who is that
            # session is the record vouching for its own writing, and this
            # refuses it rather than filing it as a softer note.
            #
            # Optional, and the residual is named rather than dressed up:
            # omitting `author` is not detectable from the data, so this
            # hardens an honest record, it does not defeat a careless one.
            # Rows written before the field existed do not carry it, because
            # inventing an author for them would be the same false record in
            # the other direction.
            if ("author" in $rc) and ($r.author? == $r.reviewer?) {
                $errors = ($errors | append $"why-review.nuon [($r.id? | default '?')]: reviewer and author are both ($r.reviewer?) — a `why` reviewed by the session that wrote it is the record vouching for itself; it needs a reader who did not write it")
            }
            $seen = ($seen | append $"($r.file?)|($r.id?)")
        }
        # matched by (file, id) with `where`, never by a record key: ids carry
        # dots and spaces (`cc [...args]`), and a cell-path lookup would split
        # them.
        let with_why = ($all | where {|r| "why" in ($r.entry | columns) })
        for row in $with_why {
            let hit = ($review | where {|r| ($r.file? == $row.file) and ($r.id? == $row.id) })
            if ($hit | is-empty) {
                $errors = ($errors | append $"($row.file) [($row.id)]: carries a `why` with no row in why-review.nuon — read it against its `use` for restatement, then record the pair")
                continue
            }
            let want = (why-digest $row.entry.use $row.entry.why)
            let got = ($hit | first | get digest)
            if $got != $want {
                $errors = ($errors | append $"($row.file) [($row.id)]: `use`/`why` changed since the recorded review — re-read the pair for restatement, then set digest to ($want)")
            }
        }
        let live_keys = ($with_why | each {|r| $"($r.file)|($r.id)" })
        for k in $seen {
            if not ($k in $live_keys) {
                $errors = ($errors | append $"why-review.nuon: row `($k)` reviews a `why` that no entry carries any more — delete it, or the record starts vouching for text that is gone")
            }
        }
    }

    # R2's `use` sub-box and R5's gesture clause, held the same way `why` is
    # held just above — see `use-digest` for why this is decidable here and
    # what the digest keys on.
    #
    # The one structural difference from the block above: `why` is optional, so
    # only `why`-carrying entries need a row. `use` is REQUIRED, so **every**
    # entry needs a current row, and an entry with none is a violation. That
    # makes this record complete by construction rather than by whoever
    # remembered.
    let use_review_path = ($dir | path join "use-review.nuon")
    if not ($use_review_path | path exists) {
        $errors = ($errors | append "use-review.nuon: missing — every `use` is held by a recorded reading against its `source` PRD, and with no record there is nothing holding R2's `use` clause or R5's gesture clause")
    } else {
        let ureview = (open $use_review_path)
        if ($ureview | is-empty) {
            print -e "use-review.nuon records no reviews — refusing to pass a check with nothing to check"
            exit 1
        }
        mut useen = []
        for r in $ureview {
            let rc = ($r | columns)
            for f in ["id" "file" "digest" "reviewer" "date"] {
                if not ($f in $rc) { $errors = ($errors | append $"use-review.nuon: a row is missing `($f)`") }
            }
            for f in $rc {
                if not ($f in ["id" "file" "digest" "reviewer" "author" "date" "note"]) {
                    $errors = ($errors | append $"use-review.nuon [($r.id? | default '?')]: unknown field `($f)`")
                    continue
                }
                let b = (bad-string ($r | get -o $f))
                if $b != "" { $errors = ($errors | append $"use-review.nuon [($r.id? | default '?')]: `($f)` ($b)") }
            }
            # same rule and same reason as why-review.nuon's: a reader who is
            # the writer is the record vouching for its own writing.
            if ("author" in $rc) and ($r.author? == $r.reviewer?) {
                $errors = ($errors | append $"use-review.nuon [($r.id? | default '?')]: reviewer and author are both ($r.reviewer?) — a `use` reviewed by the session that wrote it is the record vouching for itself; it needs a reader who did not write it")
            }
            $useen = ($useen | append $"($r.file?)|($r.id?)")
        }
        # matched by (file, id) with `where` for the same reason as above: ids
        # carry dots, spaces and brackets (`cc [...args]`, `capsule [dir]`).
        for row in $all {
            let hit = ($ureview | where {|r| ($r.file? == $row.file) and ($r.id? == $row.id) })
            if ($hit | is-empty) {
                $errors = ($errors | append $"($row.file) [($row.id)]: has no row in use-review.nuon — read the `use` against ($row.entry.source? | default 'its source PRD') and the live route, then record the reading with digest (use-digest ($row.entry.use? | default '') ($row.entry.source? | default ''))")
                continue
            }
            let want = (use-digest $row.entry.use $row.entry.source)
            let got = ($hit | first | get digest)
            if $got != $want {
                $errors = ($errors | append $"($row.file) [($row.id)]: `use`/`source` changed since the recorded reading — re-read the gesture against the spec, then set digest to ($want)")
            }
        }
        let ulive_keys = ($all | each {|r| $"($r.file)|($r.id)" })
        for k in $useen {
            if not ($k in $ulive_keys) {
                $errors = ($errors | append $"use-review.nuon: row `($k)` reviews a `use` that no entry carries any more — delete it, or the record starts vouching for text that is gone")
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
