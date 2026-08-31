verify: ""

est: 40m

# spec01 — the epic: invariants, non-goals, and a real Acceptance

Goal: `02-terminal/prd.md` becomes what the children reference instead of
restating. AGENTS.md: "Epics own the invariants." Today the epic owns none —
its `## Acceptance` is a heading with nothing under it, which is precisely
the failure the board conversion existed to end.

Files: `.mi/prds/02-terminal/prd.md` — and nothing else.

**Proved RED 2026-08-21 — 12 failures.** Against the current file: the four
invariant labels, `nine-tab floor`, `tinty`, `PaneSelect`, `dofile`,
`cancel_modal` and `perform_assignment` are all absent, Acceptance holds 0
boxes, and the child count is 6.

**One guard is already green and stays that way:** no file under
`.mi/prds/02-terminal/` contains the string `burrito` (measured today: zero
hits). R2 asks for burrito's removal from the epic; it is in fact already
absent everywhere in the subtree, so the box is a regression guard rather
than an edit. Recording it that way is the honest form — R2 is met, not
worked.

## Boxes

- [x] **B1 — I1, the tab/pane model.** The self-healing nine-tab floor owns
      tabs and panes. There is no second multiplexer: burrito took
      `DO NOT PORT` on 2026-08-20 and open decision 1 records the answer.
      Children cite I1 rather than re-arguing it.
- [x] **B2 — I2, palette ownership.** tinty owns the palette and WezTerm is
      its **first reader**, not its owner. `tinty apply` writes
      `~/.config/wezterm/colors.lua`; WezTerm `dofile`s it — never `require`,
      which caches by module name and would hand back the *first* palette on
      a second apply — and re-tints every window at once because
      `config.colors` is WezTerm-wide. Nothing below WezTerm hardcodes a hex.
      The epic must not contain the sentence "the terminal owns the palette";
      that wording is inverted and is finding T-3.
- [x] **B3 — I3, `PaneSelect` is forbidden, with the reason.** A key bound in
      `config.keys` or a key table is consumed in the raw-key pass before the
      modal sees it, while an unbound key reaches the modal, which answers
      only to a complete label, `Escape` and `ctrl+g`. Nothing in Lua closes
      it: `cancel_modal` is reachable from no `KeyAssignment` and
      `PaneSelector::perform_assignment` returns false unconditionally
      (checked in this build's source and in main). This is R4, and it stays
      an epic invariant even though Q2 dropped the pane letters — the
      constraint outlives the feature that discovered it, and it is what
      stops a future lane "simplifying" the jump mode back onto the modal.
- [x] **B4 — I4, which tree is canonical.** The deployed `~/.config/wezterm/`
      is the artifact every terminal PRD is written against (open decision
      4). `~/.local/share/chezmoi` is a stale June clone whose HEAD is a git
      ancestor of the live source at `/Users/feb/dev/.files`; no terminal PRD
      may cite it as the chezmoi source. This is the invariant whose absence
      invalidated the epic in the first place.
- [x] **B5 — Non-goals, each with its reason and its rating.** The
      `Ctrl+Shift+B` wallpaper pipeline (`DO NOT PORT`, C 8 / U 3) and
      `background.png` (C 2 / U 0); the OSC-1337 `opacity` user-var; the dead
      `config.lua` (C 1 / U 1, unloaded, invalid Lua, and a decoy asserting a
      font and colorscheme a reader would believe); `wsl-clip-prime.sh`
      (C 4 / U 0); the four `solo-window.*` scripts (C 5 / U 0). Keep the
      existing carve-out sentence: none of this touches the **static**
      `window_background_opacity`, its base00 tint or
      `macos_window_background_blur`, which belong to the Appearance baseline
      and are spec02's.
- [x] **B6 — Acceptance becomes boxes.** At least three, and they must be
      checkable against the tree rather than restatements: every child cites
      a `capabilities-terminal.md` entry by name (or `net-new`); no child
      names a WezTerm config field the installed build rejects; the child
      count in the epic, the README tree and the README build order agree.
- [x] **B7 — the child count is seven.** Q3 adds `07-grid-centering`. The
      verify counts directories, so this box cannot close until spec07 has
      created the node — which is the intended coupling.

## Out of scope

- The children themselves (spec02–spec07) and `README.md` (spec08).
- `plan.json`. The new seventh child needs a task row and a build-order
  slot; both are the conductor's, and are reported rather than written.

## Spent proof

The `grep -rl burrito prds/02-terminal/` sweep now reaches the nine child
spec files the 02-terminal lanes wrote after this node closed, where
`burrito` survives only as a refused name inside gate assertions —
`prds/02-terminal/04-copy-mode/specs/spec01-copy-mode-lua.md:196` calls it
"a refused name" — and not as a live requirement.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/02-terminal/prd.md; rc=0; T="$(tr "\n" " " < "$f" | tr -s " ")"; has() { echo "$T" | grep -qF "$1" || { echo "FAIL: epic does not state: $1"; rc=1; }; }; no() { echo "$T" | grep -qF "$1" && { echo "FAIL: epic still says: $1"; rc=1; }; }; has "I1"; has "I2"; has "I3"; has "I4"; has "nine-tab floor"; has "tinty"; has "PaneSelect"; has "dofile"; has "cancel_modal"; has "perform_assignment"; no "gui-attached"; no "the terminal owns the palette"; A=$(awk "/^## Acceptance/{f=1;next} /^## /{f=0} f" "$f" | grep -c "^- \["); [ "$A" -ge 3 ] || { echo "FAIL: epic Acceptance has $A boxes, want >=3 (it is an empty section today)"; rc=1; }; B=$(grep -rl "burrito" prds/02-terminal/ 2>/dev/null | tr "\n" " "); [ -z "$B" ] || { echo "FAIL: burrito survives in: $B"; rc=1; }; C=$(find prds/02-terminal -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d " "); [ "$C" = "7" ] || { echo "FAIL: 02-terminal has $C children, want 7"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
