# spec03 — Unwind the deferral where a reader looks for it: README and SYSTEM.md

est: 0.5h

## Goal

`SYSTEM.md` requires that an exclusion decision is recorded "in the epic's
Non-goals and the README's exclusion list, not just in the inventory". The
tinty deferral was recorded that way, so the **reversal** has to be unwound
the same way — and it was recorded in more places than the inventory. Checked,
not assumed:

- `.mi/prds/README.md`'s `## Excluded` section opens its `DEFER` line with
  "theme switcher (tinty + tv)". That is the canonical exclusion list, and it
  now excludes something the human put back.
- `.mi/SYSTEM.md`'s `## Known gaps` still says three scope decisions are
  blocked on the human. **All three of its clauses are dead, so the honest
  count is zero, not two:** burrito/tabs was resolved 2026-08-20 (burrito
  deleted by the user, WezTerm's self-healing nine-tab floor owns panes and
  tabs with no competing multiplexer — `plan.json`'s W0.1/W0.2 notes record it,
  and D.1a and T.5 were removed rather than resolved); tinty is settled by this
  node; and fzf was settled the same day, accepted as a documented exception.
  The orchestrator handed this node the **whole bullet** on 2026-08-21 — it is
  the last of the three D.1 decisions to land, and three tickets each cutting
  their own clause would leave each other's text half-stale. A stale gap
  invites a second round of questions already answered.
- `.mi/SYSTEM.md`'s `## Scope decisions already made` states **"The terminal
  owns the palette. WezTerm's scheme is the base"** — and that is not a
  wording nit, it is the defect finding T-3 raised: WezTerm *reads* what
  `tinty apply` writes, so the base is tinty's and the terminal is its first
  reader. The decision resolves the tension in T-3's favour, which makes the
  working contract's own sentence wrong about the architecture every downstream
  node inherits. Two of the four gated nodes (E.5 R6, and T.1's future re-spec)
  restate that inheritance, so leaving it inverted in the contract is how it
  gets restated inverted again.

`AGENTS.md` and `CLAUDE.md` at the repo root are **symlinks to
`.mi/SYSTEM.md`** — edit the target, never the links.

## Files touched

- `.mi/prds/README.md` — the `## Excluded` section only.
- `.mi/SYSTEM.md` — one bullet corrected under `## Scope decisions already
  made`, and one bullet deleted outright under `## Known gaps`.

### Ownership hazards, read before writing

- **`.mi/prds/README.md` is W0.4g's file** (`w0-4-s2-corrections/delivery`,
  `state: open`), and its R4 rewrites the exclusions because they are
  currently stated twice; **W0.2 R6** also updates the README tree and build
  order. Put the new paragraph **only inside `## Excluded`**, never in the
  prose exclusion pointer elsewhere in the file, so W0.4g's de-duplication has
  nothing of ours to delete. If either has already landed, match the shape it
  left behind rather than restoring this spec's assumed wording.
- **`.mi/SYSTEM.md`'s `## Known gaps` bullet on the three D.1 decisions is
  this node's outright** (orchestrator, 2026-08-21), and it is **deleted**, not
  rewritten. Do not touch the `02-terminal` or `03-editor/14` bullets; after
  the deletion the section holds **two** `- **` bullets. It holds three going
  in: `decisions/odin-toolchain` removed the `01-capsule/02` bullet earlier the
  same day.
- **A stale guard in a finished ticket — record it, do not fix it.**
  `decisions/odin-toolchain` is `state: done`, and its `specs/spec02.md` verify
  carries `grep -qF "and is fzf an accepted" .mi/SYSTEM.md` as a don't-disturb
  guard on the neighbouring bullet. This deletion makes that guard fail on any
  re-run, and that is the correct trade: keeping the substring alive would
  force the working contract to keep asserting a fork that is closed, purely to
  keep a dead guard green. The orchestrator records the supersession in D.2's
  closing note. **Do not edit another ticket's spec.**
- `decisions/fzf` (D.1c) landed the same day and `wallpaper-opacity` (D.1d) is
  still open; neither writes this bullet, because the whole bullet is ours.
- Do not add anything to `## Scope decisions already made` beyond the
  correction described below: that section's last bullet says the canonical
  exclusion list is the README's and forbids duplicating it here.

## What to write

### 1. `.mi/prds/README.md` — `## Excluded`

The `DEFER` paragraph currently reads:

> **`DEFER` — real, but not in the minimal base:** theme switcher (tinty +
> tv) · opacity picker · smear cursor · `cl` goal-loop and `jj` journal
> launchers · the long tail of tv cable channels.

Remove `theme switcher (tinty + tv) · ` from it and **leave every other item
alone** — the opacity picker in particular is `wallpaper-opacity` (D.1d)'s
subject, still open.

Then add a dated paragraph as the **last** paragraph of `## Excluded`,
immediately after that `DEFER` line, in the shape the burrito and Odin entries
above already established:

> **Retained — the tinty theme switcher**, decided 2026-08-21: it does not
> leave the minimal base after all. `tinty apply` is the palette source of
> truth; WezTerm `dofile`s the `colors.lua` it writes, `config.nu` re-asserts
> its tinted-shell artifact in every new shell, F6 delegates the switch to
> `theme.nu`, and Neovim (base16 + transparent) and television (`default`
> ANSI theme) inherit downstream. Dropping it would have left four scheduled
> nodes with no palette owner, so the `DEFER` came off and the inventory
> verdict is now `SIMPLIFY`: the palette-owning core is in, the background
> override ladder and its tuner stay out. Recorded in
> [`00-delivery/decisions/tinty`](../prd.md) and open
> decision 2 of the
> [corrections backlog](../../../corrections/prd.md). It still owes a node:
> `theme.nu` has no child in `04-shell`, and the F6 binding is
> `w0-2-terminal-respec` R5's to place.

### 2. `.mi/SYSTEM.md` — `## Scope decisions already made`

Replace the bullet that begins "**The terminal owns the palette.**" with:

> - **tinty owns the palette; the terminal is its first reader.** `tinty
>   apply` writes `~/.config/wezterm/colors.lua`, WezTerm `dofile`s it (never
>   `require` — it caches by module name and would hand back the *first*
>   palette on a second apply) and re-tints every window at once because
>   `config.colors` is WezTerm-wide; `config.nu` sources tinty's tinted-shell
>   artifact so a new shell re-asserts the same scheme; Neovim (base16 +
>   transparent) and television (`default` ANSI theme) inherit downstream.
>   Nothing below WezTerm hardcodes hex values. This corrects the earlier
>   "the terminal owns the palette" wording, which had the direction
>   backwards — see finding T-3 and open decision 2 in the
>   [corrections backlog](../../../corrections/prd.md).

Keep the bullet in its current position in the list.

### 3. `.mi/SYSTEM.md` — `## Known gaps`

**Delete the three-decisions bullet in full**, all four of its lines:

> - **Three scope decisions are blocked on the human** (task D.1): does burrito
>   or WezTerm own tabs/panes, does tinty stay (it owns the palette everything
>   else inherits, yet is deferred as cosmetic), and is fzf an accepted
>   exception to "tv owns every picker" or replaced.

Delete, do not rewrite in place, and **add no replacement** — not one bullet,
and not three. The reasons are structural, not tidiness:

- The section's own opening line scopes it to things "recorded so nobody
  mistakes them for finished work". Three answered questions are finished work,
  and a rewritten stub would re-advertise them as live.
- `## Scope decisions already made` closes by saying the canonical exclusion
  list is the README's and "don't duplicate it here". Step 1 put the tinty
  answer in the README; the burrito and fzf answers are recorded where they
  belong; and step 2 corrects the one architectural sentence that was actually
  *wrong* rather than merely settled. Nothing else is owed here.
- `decisions/odin-toolchain` set exactly this precedent earlier the same day:
  it deleted its own Known-gaps bullet and added no replacement.

After the deletion the section holds two bullets — `02-terminal` and
`03-editor/14`. Leave both alone. (Flagged, not fixed: the `03-editor/14`
bullet may itself be stale, since `decisions/shift-select-scope` is
`state: done`. That is that node's to settle, not this one's.)


Do not mark any box `[x]` or `[~]` in either file.

## Acceptance

- [ ] `README.md`'s `## Excluded` `DEFER` line no longer lists the theme
      switcher, and still lists `opacity picker`, `smear cursor` and the tv
      cable-channel tail.
- [ ] `## Excluded` carries a dated `Retained` paragraph naming `tinty`,
      `2026-08-21`, `SIMPLIFY`, and linking `decisions/tinty`.
- [ ] That paragraph appears once, inside `## Excluded`, and nowhere else in
      the README.
- [ ] `SYSTEM.md` no longer contains the sentence
      `The terminal owns the palette`.
- [ ] Its replacement bullet names `tinty`, `dofile`, `config.nu`, and keeps
      `Nothing below WezTerm hardcodes hex values`.
- [ ] `## Known gaps` no longer claims **any** of the three D.1 forks is
      undecided: the section names neither `tinty` nor `fzf`, does not say
      `blocked on the human`, and does not ask who owns `tabs/panes`.
- [ ] The bullet was deleted, not rewritten: no replacement bullet stands in
      its place, and nothing was added to `## Scope decisions already made`
      beyond the palette correction in step 2.
- [ ] `## Known gaps` holds exactly two `- **` bullets — `02-terminal` and
      `03-editor/14` — and both keep their text.
- [ ] `AGENTS.md` and `CLAUDE.md` are still symlinks, not regular files.
- [ ] No box in either file is flipped to `[x]` or `[~]`.
- [ ] Neither file's frontmatter/heading structure otherwise changed; both
      still wrap at ~78 columns (tables exempt).

verify: ""

Proven RED against the current tree before being written here: it reports
`README still defers the theme switcher`, the three missing strings in
`## Excluded` (`Retained`, `SIMPLIFY`, `decisions/tinty` — `tinty` and the
date already appear there from other entries), `SYSTEM.md still inverts
palette ownership`, `SYSTEM.md does not state the corrected ownership`, three
`Known gaps still presents a settled D.1 fork as open` lines (`tinty`, `fzf`,
`blocked on the human`) and `Known gaps should hold exactly 2 bullets after
the removal, with no replacement`, exiting 1. The guards on the other DEFER
items, the two surviving gap bullets and the two root symlinks pass today and
exist to catch overreach.

## Spent proof

`AGENTS.md` is a regular file today rather than the symlink into
`.mi/SYSTEM.md` this guard pinned, because the mi retirement materialised
the working contract at the repo root and repointed `CLAUDE.md` at it — the
arrangement `AGENTS.md` now documents.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; r=prds/README.md; s=AGENTS.md; X() { awk "/^## Excluded/{x=1;next} /^## /{x=0} x" "$r"; }; X | grep -qF "theme switcher (tinty" && { echo "FAIL: README still defers the theme switcher"; rc=1; }; for k in "opacity picker" "smear cursor" "tv cable channels"; do X | grep -qF "$k" || { echo "FAIL: README DEFER line lost: $k"; rc=1; }; done; for k in "Retained" "tinty" "2026-08-21" "SIMPLIFY" "decisions/tinty"; do X | grep -qF "$k" || { echo "FAIL: README Excluded lacks: $k"; rc=1; }; done; [ "$(grep -c "Retained — the tinty theme switcher" "$r")" -le 1 ] || { echo "FAIL: the retention paragraph is stated more than once"; rc=1; }; grep -qF "The terminal owns the palette" "$s" && { echo "FAIL: SYSTEM.md still inverts palette ownership"; rc=1; }; grep -qF "tinty owns the palette" "$s" || { echo "FAIL: SYSTEM.md does not state the corrected ownership"; rc=1; }; for k in "dofile" "config.nu" "Nothing below WezTerm hardcodes hex values"; do grep -qF "$k" "$s" || { echo "FAIL: corrected palette bullet lacks: $k"; rc=1; }; done; K() { awk "/^## Known gaps/{k=1;next} /^## /{k=0} k" "$s"; }; for k in "tinty" "fzf" "blocked on the human" "tabs/panes" "scope decisions"; do K | grep -qiF "$k" && { echo "FAIL: Known gaps still presents a settled D.1 fork as open: $k"; rc=1; }; done; [ "$(K | grep -c "^- \*\*")" -eq 2 ] || { echo "FAIL: Known gaps should hold exactly 2 bullets after the removal, with no replacement"; rc=1; }; K | grep -qF "02-terminal" || { echo "FAIL: the 02-terminal gap bullet was disturbed"; rc=1; }; K | grep -qF "03-editor/14" || { echo "FAIL: the shift-select gap bullet was disturbed"; rc=1; }; [ -L AGENTS.md ] && [ -L CLAUDE.md ] || { echo "FAIL: a symlink at the repo root was replaced by a regular file"; rc=1; }; grep -qE "^- \[[x~]\]" "$r" && { echo "FAIL: a README box was closed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
