# spec04 — Reconcile the shell: keep the palette re-assert, un-defer the switcher

est: 0.75h

## Goal

`04-shell/01-core-config` (S.1) is on the critical path and is the node the
decision's own text singles out: "the tinty palette re-assert in `config.nu`
is **kept**, not orphaned". Today S.1 does not mention it at all — the backlog
lists it under `## S2 — coverage gaps found` as live behaviour no PRD covers,
with the parenthetical "orphaned if theme is dropped". The answer settles the
condition, so the behaviour needs a requirement, and it must be written with
the reason it exists, because the reason is the expensive part: **nothing
re-emitted the palette's OSC sequences at shell start, so every new terminal
looked like plain gruvbox no matter what had been applied.**

The epic above it also still lists the theme switcher as shed cosmetic
surface, in two places, which now contradicts the decision.

Everything in this spec was read off the deployed tree (canonical per open
decision 4), not the chezmoi source: `~/.config/nushell/config.nu:644-674`.

## Files touched

- `.mi/prds/04-shell/prd.md` — the Goal paragraph, `## Requirements`
  (one new invariant), and `## Out of scope`.
- `.mi/prds/04-shell/01-core-config/prd.md` — `## Requirements` (one new
  requirement), `## Acceptance` (two new boxes), and a new `## Decisions`
  section.

**Do not edit either file's frontmatter block.** The `deps` entry naming this
decision node stays until the orchestrator clears it.

### Ownership hazard, read before writing

Both files are in **W0.4b**'s (`w0-4-s2-corrections/shell`) `files` list, and
W0.4b is `state: open`. It edits `01-core-config` for L-3 (`rcwd` →
`recent-dirs`) and absorbs uncovered live behaviour under its R6 — a list that
deliberately does **not** include the tinty re-assert, because while this
decision was open nobody could say whether it survived. The two edits are
disjoint: R1–R9 and the epic's existing bullets are untouched here, and the
re-assert is untouched there. Run them in either order, but not concurrently —
one writer per file. If W0.4b has landed first, append after whatever
requirement number it left as the highest.

## What to write

### 1. `04-shell/prd.md` — the Goal paragraph

It currently ends "…and sheds the WIP and cosmetic surface (leader mode,
overlay, theme/opacity pickers)". Replace the parenthetical with
`(leader mode, overlay, the opacity picker)`. The theme picker is no longer
shed.

### 2. `04-shell/prd.md` — a new architecture invariant

Add after I4, keeping the box open:

- [ ] **I5** — **The palette comes from tinty, and no child hardcodes one.**
      `tinty apply` is the source of truth: it writes both the WezTerm palette
      and the tinted-shell artifact this epic re-asserts at shell start
      (`01-core-config` R10), and television inherits it by running the
      `default` ANSI theme (`04-television` R6) rather than a hex theme.
      Decided 2026-08-21 — see
      [`decisions/tinty`](../prd.md).

### 3. `04-shell/prd.md` — `## Out of scope`

Replace the bullet "Theme switcher and opacity picker (`DEFER` — cosmetic,
revisit later)." with:

- The opacity picker (`DEFER` — cosmetic; its fate is the still-open
  `wallpaper-opacity` decision), and the theme switcher's background-override
  ladder and R/G/B tuner, which the 2026-08-21 `SIMPLIFY` drops. The theme
  switcher itself is **not** out of scope any more: tinty owns the palette
  (I5): `theme.nu` (the A/B slots, `_theme_toggle`, the tv scheme picker) is
  [`09-theme-switcher`](../../../../04-shell/09-theme-switcher/prd.md)'s, created 2026-08-21 when
  this decision landed, and the F6 binding that calls it is
  `w0-2-terminal-respec` R5's to place.

Do not touch the other two bullets.

### 4. `01-core-config/prd.md` — a new requirement R10

Append after R9, keeping R1–R9 and their numbers exactly as they are (other
documents cite requirements by number):

- [ ] **R10** — **Live palette re-assert.** An interactive shell re-asserts
      the active tinty scheme by sourcing tinty's cached tinted-shell artifact
      (`$XDG_DATA_HOME/tinted-theming/tinty/artifacts/tinted-shell-scripts-file.sh`,
      defaulting `XDG_DATA_HOME` to `~/.local/share`), falling back to
      `tinty init` only when that artifact does not exist yet. Constraints,
      each with its reason:
      **(a)** It is needed because WezTerm's own scheme is only the *base*
      palette — tinty persists the pick in `current_scheme` and tinted-shell
      delivers it as OSC sequences the terminal applies at runtime, and
      nothing re-emitted those at shell start, so every new terminal looked
      like plain gruvbox whatever had been applied.
      **(b)** Source the artifact, do not run `tinty init`: the artifact is
      the very file `init` sources, but `init` also spawns the tinty binary
      and its whole hook chain (~65 ms) for hooks that are no-ops on an
      unchanged scheme, against ~5 ms for one `bash` spawn — on every shell
      start. `init` survives only as the fresh-machine fallback.
      **(c)** Guard it on stdout being a terminal. The artifact writes its
      escapes to `$TTY` itself and no-ops when that is not a writable
      terminal, so this is already inert under `nu -c`; the guard is there to
      skip the spawn.
      **(d)** It is a no-op until something has been applied, so a machine
      that has never picked a scheme keeps the terminal's base scheme.
      **(e)** It runs *before* anything that defines the `theme` command, so
      the re-assert is what a new shell sees first.
      This is a deliberate exception to R9's "generated integrations are
      produced at chezmoi-apply time": the active scheme changes at runtime,
      so nothing generated at apply time can carry it.

### 5. `01-core-config/prd.md` — two acceptance boxes

Append to `## Acceptance`, both open:

- [ ] `tinty apply base16-<some-other-scheme>`, then open a new pane: the new
      shell comes up in that scheme with no second apply, and an already-open
      pane is not left on the old one.
- [ ] `nu -c 'print hi'` from a non-terminal stdout emits no escape sequence
      and spawns no `bash` for the artifact.

### 6. `01-core-config/prd.md` — a `## Decisions` section

Append at the end of the file, matching the convention
`w0-6-live-bugs/prd.md` uses:

> ## Decisions
>
> **Decided 2026-08-21 (user): tinty stays as palette owner and its `DEFER`
> verdict is withdrawn.** Recorded from
> [`00-delivery/decisions/tinty`](../prd.md);
> the backlog's copy is open decision 2 of
> [the corrections backlog](../../../corrections/prd.md). R10 is what
> that answer adds to this node — the re-assert was previously listed as an
> uncovered live behaviour that would be orphaned if the theme surface was
> dropped. The `theme` command itself is not this node's — it belongs to
> [`04-shell/09-theme-switcher`](../../../../04-shell/09-theme-switcher/prd.md), which this node
> only has to leave a working palette re-assert underneath.

## Acceptance

- [ ] `04-shell/prd.md`'s Goal no longer sheds the theme picker; it still
      sheds leader mode, the overlay and the opacity picker.
- [ ] `04-shell/prd.md` has an open invariant box `I5` naming tinty as the
      palette source and citing `01-core-config` R10.
- [ ] Its `## Out of scope` no longer excludes the theme switcher, still
      excludes the opacity picker, and names the missing node plus
      `w0-2-terminal-respec` R5 for the F6 half.
- [ ] I1–I4 keep their numbers and text.
- [ ] `01-core-config/prd.md` has an open requirement box `R10` that names the
      artifact path, `tinty init` as the fallback only, and carries reasons
      (a)–(e) — including the "every new terminal looked like plain gruvbox"
      cause and the `init` spawn cost.
- [ ] R1–R9 keep their numbers and text; no requirement is renumbered.
- [ ] Its `## Acceptance` gained the two boxes above, both open.
- [ ] It ends with a `## Decisions` section containing
      `Decided 2026-08-21 (user)` and linking `decisions/tinty`.
- [ ] Every box in both files is still open — no `[x]`, no `[~]`.
- [ ] Neither frontmatter block changed: `shasum -a 256` of each file's
      leading `---` fence, equal before and after, both pairs quoted.
      `git diff -U0` cannot carry it — the box carries no pathspec, and both
      `prd.md` files it means are untracked (`git ls-files --error-unmatch`, 2026-08-23), so "shows no
      hunk" is what an untracked pair always shows. Unprovable in retrospect:
      the pre-edit state was untracked, so git never held a copy and no `cp`
      aside was kept. What would have proved it: the two fence hashes, taken
      before the first write.
- [ ] Both files still wrap at ~78 columns.

verify: ""

Proven RED against the current tree before being written here: it reports
`shell epic Goal still sheds the theme picker`, `shell epic still excludes the
theme switcher`, `no I5 palette invariant`, the three missing I5 strings,
`shell epic does not say who places the F6 half`, `no R10 palette re-assert
requirement`, the five missing R10 strings, `no acceptance check that a new
pane picks up an applied scheme` and `core-config has no ## Decisions
section`, exiting 1. The guards on I1–I4, R1–R9, the opacity exclusion and the
open boxes pass today and exist to catch overreach.

## Spent proof

`prds/04-shell/01-core-config/prd.md` has since been implemented and its
boxes closed; the guard was written to catch a box closing during this
node's own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; e=prds/04-shell/prd.md; c=prds/04-shell/01-core-config/prd.md; grep -qF "theme/opacity pickers" "$e" && { echo "FAIL: shell epic Goal still sheds the theme picker"; rc=1; }; grep -qF "Theme switcher and opacity picker" "$e" && { echo "FAIL: shell epic still excludes the theme switcher"; rc=1; }; grep -qF "opacity picker" "$e" || { echo "FAIL: the opacity picker exclusion was lost; it is D.1d s, not ours"; rc=1; }; grep -qF "**I5**" "$e" || { echo "FAIL: no I5 palette invariant"; rc=1; }; I5() { awk "/\\*\\*I5\\*\\*/{i=1} i&&/^- \\[/&&!/\\*\\*I5\\*\\*/{i=0} i" "$e"; }; for s in "tinty" "R10" "decisions/tinty"; do I5 | grep -qF "$s" || { echo "FAIL: I5 lacks: $s"; rc=1; }; done; for s in "**I1**" "**I2**" "**I3**" "**I4**"; do grep -qF "$s" "$e" || { echo "FAIL: an existing invariant was renumbered or lost: $s"; rc=1; }; done; grep -qF "w0-2-terminal-respec" "$e" || { echo "FAIL: shell epic does not say who places the F6 half"; rc=1; }; grep -qF "**R10**" "$c" || { echo "FAIL: no R10 palette re-assert requirement"; rc=1; }; R10() { awk "/\\*\\*R10\\*\\*/{r=1} r" "$c" | awk "/^## /{exit} {print}"; }; for s in "tinted-shell-scripts-file.sh" "tinty init" "plain gruvbox" "no-op" "terminal"; do R10 | grep -qF "$s" || { echo "FAIL: R10 lacks: $s"; rc=1; }; done; for n in 1 2 3 4 5 6 7 8 9; do grep -qF "**R$n**" "$c" || { echo "FAIL: R$n went missing from core-config"; rc=1; }; done; grep -qF "tinty apply base16-" "$c" || { echo "FAIL: no acceptance check that a new pane picks up an applied scheme"; rc=1; }; grep -q "^## Decisions" "$c" || { echo "FAIL: core-config has no ## Decisions section"; rc=1; }; D() { awk "/^## Decisions/{d=1;next} /^## /{d=0} d" "$c"; }; for s in "Decided 2026-08-21 (user)" "decisions/tinty"; do D | grep -qF "$s" || { echo "FAIL: core-config ## Decisions lacks: $s"; rc=1; }; done; for f in "$e" "$c"; do grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
