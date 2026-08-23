# spec03 — Make `help` teach the exception instead of contradicting it

est: 1.5h

## Goal

The recorded answer names this as the second of the two places the exception
must be written down, and gives the reason: *"otherwise the manual teaches an
invariant the environment does not honour, which is exactly the failure mode
`06-help` exists to prevent."*

That is not hypothetical. The manual already exists, and it is already wrong
in two places — measured against `home/dot_config/nushell/help/shell.nuon` at
the time of speccing:

| where | what it says today | why it is now false |
|---|---|---|
| `[tv channel]` `why` | "One rule keeps the picker surface from sprawling: television owns every picker screen." | Stated without qualification, so a reader who then watches `zi` open fzf concludes the manual is decorative. |
| `[idioms]` `use` | "Pick with television (`tv`), not fzf." | Addressed **to agents**, in the `agents` topic. It tells an agent that reaching for fzf is a mistake, in an environment where fzf is a required package and `zi` is built on it. |
| `[zi]` (no `why`) | "the zoxide database opens as a picker, ordered by frecency" | Names no program, so the exception is invisible at the one entry that creates it. |

Three surgical prose edits fix all three. **Do not add a fourth, standalone
"fzf exception" entry.** There is nothing to run, the rule already has a home
(`[tv channel]`, a `verify: prose` concept entry), and a floating entry would
be the fourth copy of a fact the tree's own cross-link rule limits to one.

## Contention — read this before claiming

**These files are being written by another agent right now.**
`06-help/01-content-model` is `state: claimed` by `impl-H-1`, and at the time
of speccing `git status --short` showed uncommitted modifications to
`home/dot_config/nushell/help/{shell,nvim,terminal,capsule}.nuon`,
`why-review.nuon`, `README.md` and `tests/help-content-model.nu`. The gate is
mid-change: `nu tests/help-content-model.nu` reports one violation,
`use-review.nuon: missing`, because the check for that file has landed and
the file has not.

Consequences, all binding:

1. **This spec must not be dispatched until `06-help/01-content-model` is
   released.** One writer per file.
2. When you do start, **re-read all three entries and both review files** —
   line numbers, `use` text and digests in this spec are from before H.1
   landed and may all have moved.
3. `use-review.nuon` may exist by then. If it does, editing `[idioms]`'s
   `use` invalidates its row there as well as in `why-review.nuon`. Both
   records must be refreshed.
4. Do not edit `tests/help-content-model.nu`. Nothing here needs a new check;
   the existing gate already enforces every record this spec creates.

## The two-session constraint, which is not optional

`tests/help-content-model.nu` fails any `why-review.nuon` (and
`use-review.nuon`) row where `author == reviewer`, with the message *"a `why`
reviewed by the session that wrote it is the record vouching for itself"*.
All three entries here get new or rewritten prose, so all three need rows the
writing session **cannot** sign.

So this spec completes in two passes:

- **Pass A (writer).** Make the three prose edits. Add/refresh the three
  `why-review.nuon` rows with `author: <your session id>`, `date:
  2026-08-21`, the digest the gate prints, and a `note` giving the actual
  reading. Leave `reviewer` for pass B — but note the gate rejects an empty
  `reviewer`, so the gate is *expected to be red at the end of pass A*. Say
  so in your handoff rather than papering over it.
- **Pass B (a different session).** Read each `use`/`why` pair against R5's
  restatement rule and against `04-shell/prd.md` I3 as spec02 left it, then
  set `reviewer: <your session id>` and extend the `note` with what you
  actually read. Only pass B may tick this spec's acceptance.

`author` is optional in the schema — the known hole recorded in
`06-help/01-content-model` R5's stub 2 amendment. **Set it anyway on all
three rows.** Omitting it would let one session write and sign its own work
invisibly, which is the precise failure the field was added to catch, and
this spec's verify asserts the field is present for exactly that reason.

## Files touched

- `home/dot_config/nushell/help/shell.nuon` — three prose fields, listed
  below. No other entry, no schema change, no reordering.
- `home/dot_config/nushell/help/why-review.nuon` — the rows for `zi` (new),
  `tv channel` (refresh) and `idioms` (refresh).
- `home/dot_config/nushell/help/use-review.nuon` — **only if it exists** by
  the time you run: the row for `idioms` (its `use` changes). `zi` and
  `tv channel` keep their `use` byte-identical, so their rows must not move.

Nothing else. In particular not `tests/help-content-model.nu`, not the other
three `.nuon` surfaces, not `README.md`.

## What to write

### 1. `[zi]` — give it a `why`

It has none today. Insert one between `also` and `verify`, matching the field
order the file already uses:

> why: "The picker `zi` opens is **fzf**, not television: it shells out to
> `zoxide query --interactive`, which spawns it. That is the one accepted
> exception to the rule that television owns every picker screen — a cable
> channel would have to reimplement zoxide's frecency ranking to own this one
> list — so fzf is installed as zoxide's dependency and is not a picker to
> reach for anywhere else."

R5 compliance to check yourself before recording it: the `use` says *what you
do* (run it, pick a row, land there); the `why` says *what draws the screen
and why that is allowed*. No sentence of one is a restatement of the other.
Leave `use`, `title`, `topic`, `mode`, `also` and `verify` untouched — a
`use` edit would drag `use-review.nuon` in for no reason.

### 2. `[tv channel]` — qualify the rule where it is stated

Its `why` opens *"One rule keeps the picker surface from sprawling:
television owns every picker screen."* Keep that sentence — the rule is
real — and keep the curated channel list and the ANSI-theme sentence
unchanged. Add, after the curated list:

> The rule has exactly one exception, and it is named rather than tolerated:
> `zi`/`cdi` reach fzf through `zoxide query --interactive`. A second picker
> outside tv would be a new decision, not an appeal to that one.

### 3. `[idioms]` — stop telling agents a false rule

Its `use` currently reads *"Pick with television (`tv`), not fzf."* Replace
that clause only; the other three rules (`rg`/`fd`, `| where` not `| grep`,
`cd` creating its target) and the opening *"Nothing to run — four rules that
stop an agent guessing"* stay exactly as they are. Write:

> Pick with television (`tv`) — the single exception is `zi`, which opens
> fzf, and it is the only place fzf belongs.

This keeps the entry at four rules and keeps `fzf` in the text, so an agent
grepping the manual for `fzf` still lands here. Do not touch its `why` text
itself — but note that its digest changes anyway, because `why-digest` keys
on the `use`/`why` pair.

### 4. Record the reviews

Run `nu tests/help-content-model.nu`; it prints the digest each row needs.
Rows go in the `# shell.nuon` block, in entry order — `zi` sits between
`z <query>` and `cd <path>`.

## Acceptance

- [x] `[zi]` carries a `why` naming `fzf` and calling it an exception; its
      `use`, `title`, `topic`, `mode` and `verify` are byte-identical to
      before.
- [x] `[tv channel]`'s `why` names `fzf`, still contains "television owns
      every picker screen", and still lists the curated channel set and the
      `default` ANSI theme sentence.
- [x] `[idioms]`'s `use` no longer contains `not fzf`, names both `fzf` and
      `zi`, and still states four rules.
- [x] The string `owns every picker screen` still appears in `shell.nuon` —
      the invariant is qualified, never deleted.
- [x] `why-review.nuon` has rows for `zi`, `tv channel` and `idioms`, each
      with a non-empty `reviewer`, an `author` different from it, a `note`
      recording the actual reading, and a digest the gate accepts.
- [x] If `use-review.nuon` exists: `[idioms]`'s row is refreshed; `[zi]`'s
      and `[tv channel]`'s rows are unchanged.
- [x] `nu tests/help-content-model.nu` reports **no violation naming
      `[zi]`, `[tv channel]` or `[idioms]`**. (The gate as a whole is
      `06-help/01`'s to close; this spec is answerable only for its own
      three entries and their rows.)
- [x] Entry count is unchanged — no entry added, none removed.
- [x] `tests/help-content-model.nu` is unmodified by this spec.
- [x] The `why` written in step 1 was read by a session that did not write
      it, and that session's id is the `reviewer` on all three rows.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; h=home/dot_config/nushell/help; rc=0; t=$(printf "\140"); B() { awk -v k="$1" "\$0 == \"        cmd: \\\"\" k \"\\\"\" {q=1} q{print} q&&/^    }/{exit}" "$h/shell.nuon"; }; B zi | grep -qE "^ +why:.*fzf" || { echo "FAIL: the zi entry has no why naming fzf"; rc=1; }; B zi | grep -qE "^ +why:.*[Ee]xception" || { echo "FAIL: the zi entry does not call it an exception"; rc=1; }; B "tv channel" | grep -qE "^ +why:.*fzf" || { echo "FAIL: tv channel still states the picker rule with no exception"; rc=1; }; B idioms | grep -qF "not fzf" && { echo "FAIL: idioms still tells an agent the rule has no exception"; rc=1; }; B idioms | grep -qE "^ +use:.*fzf" || { echo "FAIL: idioms does not name fzf"; rc=1; }; B idioms | grep -qE "^ +use:.*${t}zi${t}" || { echo "FAIL: idioms does not name zi as the exception"; rc=1; }; grep -qF "owns every picker screen" "$h/shell.nuon" || { echo "FAIL: the picker invariant was deleted rather than qualified"; rc=1; }; for id in "zi" "tv channel" "idioms"; do r=$(grep -F "{id: \"$id\", file: \"shell.nuon\"" "$h/why-review.nuon"); [ -n "$r" ] || { echo "FAIL: why-review.nuon has no row for [$id]"; rc=1; continue; }; echo "$r" | grep -qF "author:" || { echo "FAIL: why-review.nuon [$id] has no author, so reviewer-is-not-author is not engaged"; rc=1; }; done; g=$(nu tests/help-content-model.nu 2>&1); echo "$g" | grep -E "\[(zi|tv channel|idioms)\]" && { echo "FAIL: gate reports violations on the touched entries"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

The `idioms` check looks for a backtick-quoted `zi` in the `use` prose. The
backtick is built with `t=$(printf "\140")` rather than written literally, so
the whole command survives being pasted inside a shell string or a markdown
code span — do not "simplify" it back to a literal backtick. If you edit this
verify at all, re-run it against an unmodified tree first and confirm it
still reports the same eight failures.

**Proven RED against the current tree before being written here.** Eight
failures, exit 1: the two `[zi]` `why` checks, `tv channel still states the
picker rule with no exception`, `idioms still tells an agent the rule has no
exception`, `idioms does not name zi as the exception`, `why-review.nuon has
no row for [zi]`, and the missing `author` on both the `[tv channel]` and
`[idioms]` rows. Two checks already pass and are survivor guards, there to
fail if the implementer overreaches: `idioms` must keep naming `fzf`, and
`owns every picker screen` must stay in the file. The gate check also passes
today — the gate's one current violation (`use-review.nuon: missing`) is
`impl-H-1`'s in-flight work and is deliberately outside this filter.
