# spec05 — Reconcile the editor, and record how far the inheritance reaches

est: 0.75h

## Goal

`03-editor/11-colorscheme` (E.5) and `03-editor/13-statusline` (E.13) are
gated on this decision because both derive every color from a base16 palette
that tinty owns. The answer keeps that owner, so neither node loses anything —
but E.5's R6 states the ownership **backwards** ("the WezTerm side owns the
actual background"), which is the same inversion finding T-3 raised, and a
child restating the contract's old wording is exactly how an inverted
architecture survives a correction.

There is also a fact both nodes need and neither states, read off the live
config rather than assumed:

- `~/.config/nvim/lua/plugins/colorscheme.lua` sets a **static**
  `default_scheme = "base16-gruvbox-dark-hard"`.
- tinted-nvim ships a `selector` — the feature that would follow tinty — and
  it is `enabled = false` by default
  (`~/.local/share/nvim/lazy/tinted-nvim/lua/tinted-nvim/config.lua:252-259`),
  and the live config does not enable it.
- So a live `tinty apply` changes the editor's **background** (through
  `ui.transparent = true`, since the terminal repaints underneath) and does
  **not** change its syntax colors.

Left unwritten, that reads as a bug the first time somebody switches a scheme
and the editor stays gruvbox. Written down with its reason, it is a boundary.

## Files touched

- `.mi/prds/03-editor/11-colorscheme/prd.md` — R6's text, one new
  requirement, one new acceptance box, a new `## Decisions` section.
- `.mi/prds/03-editor/13-statusline/prd.md` — a new `## Decisions` section
  only. Its requirements are correct as written and change by nothing.

**Do not edit either frontmatter block.**

### Ownership hazards and things not to fix here

- `11-colorscheme/prd.md` is in **W0.4c**'s (`w0-4-s2-corrections/editor`)
  `files` list, `state: open`. Its editor corrections (L-6, L-8, L-9, M-3,
  M-12) do not touch R6 or the palette-source question, so the edits are
  disjoint — but one writer per file: do not run them concurrently.
  `13-statusline/prd.md` is in no other task's file list.
- **Do not fix E.5's truncated header line.** It reads
  `· source: "Colorscheme +` with the quote never closed, which is a real
  defect — but it is a header/rating-line defect in W0.4c's file, and the
  contract's rating rules make the header W0.4c's business. It is flagged to
  the conductor in this ticket's report rather than fixed here.
- Do not touch E.5's R1–R5 or E.13's R1–R6.

## What to write

### 1. `11-colorscheme/prd.md` — replace R6's text

Keep the number and the open box. Replace with:

- [ ] **R6** — **Terminal coupling, and who owns the palette.** tinty owns it:
      `tinty apply` writes `~/.config/wezterm/colors.lua`, WezTerm reads that
      file and paints the background, and `ui.transparent = true` is how this
      config inherits the result without holding a single hex value. The
      direction matters — the terminal is the palette's first *reader*, not
      its owner (finding T-3, settled 2026-08-21), so a live retint there
      reaches the editor with no change here.

### 2. `11-colorscheme/prd.md` — add R7

Append after R6, box open:

- [ ] **R7** — **Where the inheritance stops.** The syntax palette is
      deliberately static: tinted-nvim paints `default_scheme` (R2), and its
      `selector` — the feature that would follow tinty live, `mode = "file"`
      watching `~/.local/share/tinted-theming/tinty/current_scheme` — stays
      `enabled = false`. A `tinty apply` therefore changes the editor's
      background and **not** its syntax colors, and that is specified, not
      broken. Two reasons, both worth keeping: turning the selector on is
      net-new behaviour that would make every scheme in the base16 catalog
      this config's readability problem; and the env route is a trap —
      tinted-nvim's env mode reads `TINTED_THEME` while tinty's tinted-shell
      artifact exports `BASE16_THEME`, so wiring it that way silently does
      nothing. Enabling the selector is a change with a PRD behind it, not a
      config tweak.

### 3. `11-colorscheme/prd.md` — add an acceptance box

- [ ] With the editor open, `tinty apply` a different base16 scheme: the
      background follows the terminal and the syntax colors do not. Both
      halves of that are the specified behaviour (R6, R7).

### 4. `11-colorscheme/prd.md` — a `## Decisions` section

Append at the end:

> ## Decisions
>
> **Decided 2026-08-21 (user): tinty stays as palette owner and its `DEFER`
> "cosmetic" verdict is withdrawn.** Recorded from
> [`00-delivery/decisions/tinty`](../prd.md);
> the backlog copy is open decision 2 of
> [the corrections backlog](../../../corrections/prd.md). This node
> keeps every requirement it had — the answer changes R6's *direction* (the
> terminal reads the palette, tinty owns it) and adds R7, the boundary of
> what actually follows a live switch.

### 5. `13-statusline/prd.md` — a `## Decisions` section

Append at the end. Nothing else in the file changes:

> ## Decisions
>
> **Decided 2026-08-21 (user): tinty stays as palette owner and its `DEFER`
> "cosmetic" verdict is withdrawn.** Recorded from
> [`00-delivery/decisions/tinty`](../prd.md).
> R1–R6 stand unchanged: the palette this statusline builds its theme from is
> the one [`11-colorscheme`](../../../../03-editor/11-colorscheme/prd.md) applies, which is
> tinty's downstream copy, so `get_palette()` stays the only source and no hex
> value is written here. The same boundary applies as in `11-colorscheme` R7 —
> a live `tinty apply` does not restyle the statusline, because the editor's
> scheme is static; `ColorScheme` (R6) is what rebuilds it, and that fires on
> an editor-side switch.

Do not mark any box `[x]` or `[~]` in either file.

## Acceptance

- [ ] E.5's R6 no longer says the WezTerm side owns the background; it names
      tinty as owner and the terminal as reader, and cites T-3.
- [ ] E.5 has an open `R7` box naming `selector`, `enabled = false`,
      `TINTED_THEME` and `BASE16_THEME`.
- [ ] E.5's R1–R5 keep their numbers and text.
- [ ] E.5's `## Acceptance` gained a box that checks a live `tinty apply`
      moves the background and not the syntax colors.
- [ ] E.5 ends with a `## Decisions` section carrying
      `Decided 2026-08-21 (user)` and linking `decisions/tinty`.
- [ ] E.13 has a `## Decisions` section carrying the same dated line, linking
      `decisions/tinty`, and stating R1–R6 are unchanged.
- [ ] E.13's requirements are otherwise byte-identical: `R1`–`R6` all present,
      `theme = "auto"` still forbidden by R3, and `gruvbox_dark` still the R5
      fallback.
- [ ] E.5's header line is untouched (still the truncated
      `source: "Colorscheme +` — W0.4c's to fix, flagged not fixed).
- [ ] Every box in both files is still open — no `[x]`, no `[~]`.
- [ ] Neither frontmatter block changed.

verify: ""

Proven RED against the current tree before being written here: it reports
`E.5 R6 still inverts palette ownership`, the three missing R6 strings, `E.5
has no R7 inheritance-boundary requirement`, the five missing R7 strings, `E.5
has no acceptance check for a live apply`, and `no ## Decisions section` plus
the two missing strings for **both** files, exiting 1. The guards on R1–R5,
E.13's six requirements, its `auto`/`gruvbox_dark` constraints, the untouched
E.5 header and the open boxes pass today and exist to catch overreach.

## Spent proof

`prds/03-editor/11-colorscheme/prd.md` and `13-statusline/prd.md` have since
been implemented and their boxes closed; the guard was written to catch a
box closing during this node's own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; a=prds/03-editor/11-colorscheme/prd.md; b=prds/03-editor/13-statusline/prd.md; grep -qF "WezTerm side owns the actual background" "$a" && { echo "FAIL: E.5 R6 still inverts palette ownership"; rc=1; }; R6() { awk "/\\*\\*R6\\*\\*/{r=1} r&&/\\*\\*R7\\*\\*/{exit} r" "$a"; }; for s in "tinty owns it" "T-3" "reader"; do R6 | grep -qF "$s" || { echo "FAIL: E.5 R6 lacks: $s"; rc=1; }; done; grep -qF "**R7**" "$a" || { echo "FAIL: E.5 has no R7 inheritance-boundary requirement"; rc=1; }; R7() { awk "/\\*\\*R7\\*\\*/{r=1} r" "$a" | awk "/^## /{exit} {print}"; }; for s in "selector" "enabled = false" "TINTED_THEME" "BASE16_THEME" "current_scheme"; do R7 | grep -qF "$s" || { echo "FAIL: E.5 R7 lacks: $s"; rc=1; }; done; for n in 1 2 3 4 5; do grep -qF "**R$n**" "$a" || { echo "FAIL: E.5 lost R$n"; rc=1; }; done; A() { awk "/^## Acceptance/{x=1;next} /^## /{x=0} x" "$a"; }; A | grep -qF "tinty apply" || { echo "FAIL: E.5 has no acceptance check for a live apply"; rc=1; }; for f in "$a" "$b"; do grep -q "^## Decisions" "$f" || { echo "FAIL: no ## Decisions section in $f"; rc=1; }; D() { awk "/^## Decisions/{d=1;next} /^## /{d=0} d" "$1"; }; for s in "Decided 2026-08-21 (user)" "decisions/tinty"; do D "$f" | grep -qF "$s" || { echo "FAIL: ## Decisions in $f lacks: $s"; rc=1; }; done; grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; done; for n in 1 2 3 4 5 6; do grep -qF "**R$n**" "$b" || { echo "FAIL: E.13 lost R$n"; rc=1; }; done; grep -qF "theme = \"auto\"" "$b" || { echo "FAIL: E.13 lost the auto-theme prohibition"; rc=1; }; grep -qF "gruvbox_dark" "$b" || { echo "FAIL: E.13 lost the lualine fallback theme"; rc=1; }; grep -qF "source: \"Colorscheme +" "$a" || { echo "FAIL: E.5 header line was edited; it is W0.4c s to fix"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
