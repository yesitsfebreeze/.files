# spec04 — M-1, M-3 and M-17: the three factual errors

est: 0.6h

Closes ticket **R4**.

## Goal

Three corrections, one of which turns out to need no edit at all.

### M-17 — **already discharged. No edit.**

The ticket says "the epic says 13 files; there are 14". It does not. The epic's
Purpose reads, today, at `.mi/prds/03-editor/prd.md:16`:

> lazy.nvim + telescope + blink.cmp + native 0.11 LSP, ~680 lines across 14
> files.

`grep -rn '13 files' .mi/` returns nothing outside the backlog's own M-17 row
and this ticket's R4 text. The count is right:
`find ~/.config/nvim -name '*.lua' | wc -l` → **14** (measured 2026-08-21).
`.mi/gantt/repair-2026-08-21/plan.proposed.md:4176` reached the same
conclusion independently. **Do not invent an edit to close this box.** Mark
R4's M-17 clause discharged and cite the count.

The one thing worth changing on that line is `~680` → the measured **683**
(`wc -l` over the same 14 files). Cheap, and it makes the sentence a
measurement rather than an approximation.

### M-1 — the `scrolloff=999` overclaim

`01-options` R3 says `scrolloff=999` "keeps the cursor line vertically
centered **at all times**", and its first acceptance line says it "sits
centered and stays centered while moving". Both overclaim. `scrolloff` is a
*minimum distance from the window edge*, so within the first and last
half-screen of a buffer there is nothing left to scroll and the cursor
necessarily walks up or down inside the window. This is `scrolloff`'s
definition, not a bug, and the correction is to say so — the acceptance line
as written fails on any file opened at line 1, which is most of them.

Only two of M-1's "three statements" are in this ticket's footprint. The
third is `.mi/docs/capabilities-nvim.md:17` ("cursor line permanently
centered"), which belongs to `w0-4-s2-corrections/docs-inventories` (W0.4a)
and is running concurrently. **Do not edit it here**; it is reported upward.

### M-3 — the version baseline, and the deprecated API it licenses

Two separate things wear one id.

**The floor is not wrong.** `05-platform/02-package-provisioning/packages-installer`
R6 already records "requires ≥ 0.11 (native `vim.lsp.enable`, blink.cmp) — in
practice the live machine runs 0.12.x", and the epic already carries an
invariant saying this epic references that floor "rather than restating a
version number". The epic then restates it anyway, twice (Purpose line 16,
invariant I2). That is the epic contradicting its own invariant, and it is the
part of M-3 worth fixing structurally.

**The consequence is real.** `03-autocmds` R1 prescribes
`vim.highlight.on_yank`. The live binary is **0.12.4** (`nvim --version`,
2026-08-21), where `vim.highlight` is deprecated in favour of `vim.hl`; the
live `lua/config/autocmds.lua:8` still calls the old name. Checked headless
on the live binary the same day: `vim.hl.on_yank ~= nil` → **true**, and
`vim.highlight ~= nil` → **true** (still present, still deprecated). So the
new spelling is available at the target and the old one is on a removal
clock.

Floor vs. target is the distinction the epic is missing, and it is what makes
this decidable: the **floor** is what the config must not require below, and
stays ≥ 0.11 unchanged; the **target** is the binary every acceptance check in
this epic is executed against, which is 0.12.4. A 0.12 deprecation binds the
rebuild even though the floor is lower.

`vim.hl` is the 0.11+ spelling, so writing `vim.hl.on_yank` does not raise the
floor. That is stated from the deprecation's own direction (the rename landed
with the deprecation) and **has only been executed against 0.12.4** — the
implementer confirms it at the floor version before relying on it, and if it
turns out `vim.hl` is 0.12-only, the fix is a `vim.hl or vim.highlight`
fallback, not reverting to the deprecated name.

## Files touched

- `.mi/prds/03-editor/01-options/prd.md` — R3 and the first acceptance line.
- `.mi/prds/03-editor/03-autocmds/prd.md` — R1 only.
- `.mi/prds/03-editor/prd.md` — Purpose line 16, invariant I2, and the
  version-floor invariant (numbered **I6** by spec02 — apply spec02 first).

**Do not edit any frontmatter.** Not touched: `.mi/docs/capabilities-nvim.md`
(W0.4a's), `.mi/prds/05-platform/**` (W0.4f's), `~/.config/nvim` (not this
repo's to edit).

## What to write

### 1. `01-options` R3

> - [ ] **R3** — **Centered editing.** `scrolloff=999`, `sidescrolloff=8`,
>       `wrap=false`. `scrolloff` is a minimum distance from the window edge,
>       not a centering command: it holds the cursor line centered everywhere
>       **except** the first and last half-screen of the buffer, where there
>       is nothing left to scroll and the cursor necessarily walks toward the
>       edge. Correction M-1 — the earlier wording said "at all times", which
>       is false at the top of every file and would have made the acceptance
>       check below fail on a correct implementation.

### 2. `01-options` first acceptance line

> - [ ] Open a file **mid-document** (`nvim +200 <file>` on a long file): the
>       cursor line sits centered and stays centered while moving. Then
>       `gg` — it does not, and must not; that is `scrolloff`'s definition
>       (R3, M-1), not a defect.

### 3. `03-autocmds` R1

> - [ ] **R1** — **Highlight on yank.** `TextYankPost` → `vim.hl.on_yank`,
>       150 ms. **Not `vim.highlight.on_yank`**: that is the deprecated
>       spelling, and the live `lua/config/autocmds.lua:8` still uses it
>       (correction M-3). The target binary is 0.12.4, where `vim.highlight`
>       is deprecated in favour of `vim.hl` and on a removal clock; the
>       version *floor* is unchanged and is not restated here — see the
>       epic's version invariant. Confirm `vim.hl.on_yank` resolves at the
>       floor version before relying on it; if it does not, guard with
>       `(vim.hl or vim.highlight).on_yank`, never fall back to the
>       deprecated name outright.

### 4. The epic

Purpose line 16 — drop the restated version, and make the count a
measurement:

> the live config in `~/.config/nvim` is a newer, different setup — lazy.nvim
> + telescope + blink.cmp + Neovim's native LSP API, 683 lines across 14
> files. Only the

I2 — reference the floor rather than restate it:

> - [ ] **I2** — **Lean on Neovim's built-ins.** `gc` commenting, and the
>       default LSP and diagnostic maps, ship in core at or below the version
>       floor (see I6). Add only what's missing — never a plugin that
>       duplicates core.

I6 (the invariant spec02 numbers) — append the floor/target paragraph:

> The floor is what the config may not require below. The **target** — the
> binary every acceptance check in this epic is executed against — is the
> live 0.12.4, so a 0.12 deprecation binds even where the floor is lower:
> `vim.highlight.*` is deprecated in favour of `vim.hl.*`, and
> [`03-autocmds`](../../../../../03-editor/03-autocmds/prd.md) R1 is written to the new name
> (correction M-3).

## Acceptance

- [ ] `01-options` R3 no longer claims centering "at all times" and names the
      first/last half-screen exception.
- [ ] `01-options` R3 cites M-1.
- [ ] The `01-options` acceptance line says the top-of-file behaviour is
      correct rather than a defect.
- [ ] `03-autocmds` R1 prescribes `vim.hl.on_yank`.
- [ ] `03-autocmds` R1 explicitly rejects `vim.highlight.on_yank` and says
      why, citing M-3.
- [ ] `03-autocmds` R1 still specifies 150 ms and `TextYankPost`.
- [ ] The epic's Purpose no longer carries a bare version number, and states
      683 lines across 14 files.
- [ ] The epic's I2 no longer restates a version number.
- [ ] The epic's version invariant names 0.12.4 as the target and states that
      the floor is unchanged.
- [ ] No `13 files` string was introduced anywhere — M-17 closes on evidence,
      not on an edit.
- [ ] Every box in all three files is still open — no `[x]`, no `[~]`.
- [ ] `.mi/docs/capabilities-nvim.md` is untouched by this spec.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports: R3 still claims "at all times", does
not name the half-screen exception, does not cite M-1; the acceptance line does
not exempt the top of the buffer; `03-autocmds` R1 does not prescribe
`vim.hl.on_yank` and does not cite M-3; the epic Purpose still restates a
version and does not state 683 lines; epic I2 still restates 0.11; and the epic
has no numbered I6, followed by its three content clauses on the empty string.
Exit 1.

Regression guards that pass today: `scrolloff=999`, `TextYankPost`, `150`,
`14 files`, all boxes open, and the `13 files` negative — the last one exists
because M-17 closes on evidence and the failure mode to guard against is an
implementer "fixing" a count that was already right.

`capabilities-nvim.md` is checked with a **NOTE**, never a FAIL: W0.4a is
editing it concurrently by design, so a dirty worktree there is expected and
must not fail this ticket's gate.

The requirement extractor is parameterised (`req <file> <Rn>`) and matches
`**Rn**` as an anchored pattern, so `R1` does not also select `R10`; each
requirement is whitespace-normalised before matching because these files wrap
at 78 columns and every asserted phrase straddles a break.

## Spent proof

`prds/03-editor/01-options` and `03-autocmds` have since been implemented
and their boxes closed, and the run's own `NOTE` line already records that
`docs/capabilities-nvim.md` is dirty under a concurrent lane rather than
under this node.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; O=prds/03-editor/01-options/prd.md; A=prds/03-editor/03-autocmds/prd.md; E=prds/03-editor/prd.md; req() { awk -v n="$2" "BEGIN{p=\"\\\\*\\\\*\" n \"\\\\*\\\\*\"} \$0 ~ p {r=1} r && /^- \[.\] \*\*[RI][0-9]/ && \$0 !~ p {r=0} r && /^## / {r=0} r" "$1" | tr "\n" " " | tr -s " "; }; r3=$(req "$O" R3); [ -n "$r3" ] || { echo "FAIL: 01-options has no R3"; rc=1; }; printf "%s" "$r3" | grep -qF "at all times" && { echo "FAIL: 01-options R3 still claims centering at all times"; rc=1; }; printf "%s" "$r3" | grep -qE "half-screen|first and last" || { echo "FAIL: 01-options R3 does not name the uncentered first/last screen"; rc=1; }; printf "%s" "$r3" | grep -qF "M-1" || { echo "FAIL: 01-options R3 does not cite M-1"; rc=1; }; printf "%s" "$r3" | grep -qF "scrolloff=999" || { echo "FAIL: 01-options R3 lost scrolloff=999"; rc=1; }; oacc=$(awk "/^## Acceptance/{r=1;next} r&&/^## /{r=0} r" "$O" | tr "\n" " " | tr -s " "); printf "%s" "$oacc" | grep -qE "must not|not a defect|not a bug" || { echo "FAIL: the 01-options acceptance line does not exempt the top of the buffer"; rc=1; }; ar1=$(req "$A" R1); [ -n "$ar1" ] || { echo "FAIL: 03-autocmds has no R1"; rc=1; }; printf "%s" "$ar1" | grep -qF "vim.hl.on_yank" || { echo "FAIL: 03-autocmds R1 does not prescribe vim.hl.on_yank"; rc=1; }; printf "%s" "$ar1" | grep -qE "Not .vim.highlight|not .vim.highlight|deprecated" || { echo "FAIL: 03-autocmds R1 does not reject the deprecated spelling"; rc=1; }; printf "%s" "$ar1" | grep -qF "M-3" || { echo "FAIL: 03-autocmds R1 does not cite M-3"; rc=1; }; printf "%s" "$ar1" | grep -qF "TextYankPost" || { echo "FAIL: 03-autocmds R1 lost TextYankPost"; rc=1; }; printf "%s" "$ar1" | grep -qF "150" || { echo "FAIL: 03-autocmds R1 lost the 150 ms timeout"; rc=1; }; pur=$(awk "/^Purpose:/{r=1} r&&/^Goal:/{r=0} r" "$E" | tr "\n" " " | tr -s " "); printf "%s" "$pur" | grep -qE "0\.1[0-9]" && { echo "FAIL: the epic Purpose still restates a version number"; rc=1; }; printf "%s" "$pur" | grep -qF "683 lines" || { echo "FAIL: the epic Purpose does not state the measured 683 lines"; rc=1; }; printf "%s" "$pur" | grep -qF "14 files" || { echo "FAIL: the epic Purpose lost the 14-file count"; rc=1; }; i2=$(req "$E" I2); printf "%s" "$i2" | grep -qE "0\.11" && { echo "FAIL: epic I2 still restates a version number"; rc=1; }; i6=$(req "$E" I6); [ -n "$i6" ] || { echo "FAIL: epic has no numbered version-floor invariant I6 (apply spec02 first)"; rc=1; }; printf "%s" "$i6" | grep -qF "0.12.4" || { echo "FAIL: epic I6 does not name 0.12.4 as the target"; rc=1; }; printf "%s" "$i6" | grep -qE "target" || { echo "FAIL: epic I6 does not distinguish floor from target"; rc=1; }; printf "%s" "$i6" | grep -qF "vim.hl" || { echo "FAIL: epic I6 does not record the vim.hl deprecation"; rc=1; }; grep -rqF "13 files" prds/03-editor/ && { echo "FAIL: a 13-files claim was introduced"; rc=1; }; for f in "$O" "$A" "$E"; do grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; done; git diff --quiet -- docs/capabilities-nvim.md || { echo "NOTE: capabilities-nvim.md has uncommitted changes - W0.4a is concurrent, not this specs doing"; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
