verify: ""

est: 1h

# spec05 — `04-copy-mode`: copy mode as it exists, plus the loose bindings

Goal: replace a node that describes a copy mode nobody built — `F3`, a
"bright cyan" cursor, a frozen buffer where "no input/output occurs",
`Ctrl+C` copying "entire visible content" — with the one that is live, and
give the four uncovered bindings from T-10 a home while the file is open.

Files: `.mi/prds/02-terminal/04-copy-mode/prd.md` — and nothing else.

**Proved RED 2026-08-21 — 18 failures**, covering every requirement in the
list below and all five `no` guards (`F3`, `bright cyan`, `immutable`, `no
input/output occurs`, `copies entire visible content`).

**Rating: C 4 / U 9** (dominant: `Copy mode: Ctrl+Shift+X plus a single-key
c cycle`), merging `Ctrl+V` native paste C 1 / U 8 · `Ctrl+C` copy-or-SIGINT
C 3 / U 9 · `StartWindowDrag` C 1 / U 7 · `Ctrl`+left-click opens the link
C 1 / U 7 · OSC 1337 `SetUserVar` triggers C 3 / U 7. The current header's
`C2 • U3 • V3` is invented — no inventory entry carries it.

**This spec corrects the PRD; [spec09](spec09.md) corrects the inventory.**
Do not re-spec from `capabilities-terminal.md:208-209`; it is wrong twice.
B3 below is the correction in PRD form, and spec09 lands the same correction
at source so the next reader of that file is not trapped by it.

## Boxes

- [x] **B1 — entry from a clean state.** `Ctrl+Shift+X` clears any stale
      selection, clears the per-pane toggle flag, then `ActivateCopyMode`.
      Resetting **on entry** is what makes an exit by `q`, `Esc` or `y`
      unable to leave the toggle stale.
- [x] **B2 — the default table is extended, never replaced.** All **54**
      builtin copy-mode motions survive, and exactly one binding is added.
- [x] **B3 — no search is promised, because copy mode has none.** The
      inventory says the "55 builtin motions and searches" survive. Measured
      against `wezterm show-keys --lua` on `20240203`: the effective
      `copy_mode` table has **55 rows in total, one of which is this
      config's own `c`** — so 54 are builtin, not 55 — and it contains **no
      search facility whatsoever**: no `/`, and no
      `NextMatch`/`PriorMatch`/`ClearPattern`/`CycleMatchType` either. Every
      one of those lives in a **separate 10-row `search_mode` table**,
      reachable only from normal mode via WezTerm's default `Ctrl+Shift+F` /
      `Cmd+F`. Requirements must say "54 builtin **motions**", and the
      manual entry must send a user looking for search to `Ctrl+Shift+F`
      rather than into copy mode. Re-speccing from that line would have
      reproduced the `02-terminal` failure exactly, which is why this node's
      Inbox routed it here.
- [x] **B4 — the single-key `c` cycle, tracked per pane id.** First press
      anchors a `Cell` selection at the cursor; second press
      `CopyTo("ClipboardAndPrimarySelection")` + `CopyMode("Close")`. Tracked
      by **pane id** rather than by reading the selection text back, because
      a selection that begins over blank cells reads as empty and would
      desync the toggle.
- [x] **B5 — the shell-driven entry, and only that one.** A nushell command
      prints an OSC 1337 `SetUserVar` named `copymode`; WezTerm parses it off
      the pty and enters copy mode (the value is ignored). This is how a
      shell command reaches a GUI-only mode. The sibling `opacity` user-var
      is **out** — open decision 5(b) drops the toggle — so the handler
      keeps one name, not two. Say so explicitly, or a lane porting the
      handler carries the dropped feature back in with it.
- [x] **B6 — `Ctrl+V` is a bracketed paste.** `PasteFrom("Clipboard")`, no
      subprocess: it is how text reaches both the shell and a running program
      (Claude, nvim), and it is what makes clipboard-based dictation land in
      the terminal.
- [x] **B7 — `Ctrl+C` copies or interrupts, never both.** If
      `window:get_selection_text_for_pane` returns a non-empty selection,
      copy to `ClipboardAndPrimarySelection` and clear it; **otherwise**
      `SendKey{ key="c", mods="CTRL" }` so the key keeps its terminal
      meaning. The fallthrough is the requirement — this gives the
      platform-native copy shortcut without ever costing an interrupt.
- [x] **B8 — the two mouse bindings, with their reasons.**
      `Ctrl+Alt+Super`+left-drag → `StartWindowDrag`, which is the **only**
      handle for repositioning the OS window because
      `window_decorations = "RESIZE"` leaves no titlebar; the heavy modifier
      combo keeps it from stealing ordinary clicks or selection drags.
      `Ctrl`+left-click → `OpenLinkAtMouseCursor` with
      `mouse_reporting = true`, which is what keeps it working while an app
      is capturing the mouse (DECSET 1002/1006) — without the flag WezTerm
      forwards the click to the app and nobody opens the URL. **Reword the
      reason:** the live comment cites burrito as the capturing app; burrito
      is gone, and nvim and other TUIs capture the same way, so the flag
      still earns its place. No terminal PRD may contain the string
      `burrito`.
- [x] **B9 — the stray editor artifact goes.** The line
      ``- Added to terminal epic via `:w …/02-terminal/04-copy-mode.md` `` at
      the foot of the file is an editor accident from an earlier session, out
      of every other ticket's footprint, and routed here by this node's
      Inbox. It disappears with the rewrite.

## Out of scope

- Grid centering, which T.4's plan row bundles with this node but which
  Q3 gives its own node (spec07).

## Spent proof

The `grep -qF opacity` guard now matches the `## Deviations` section that
`prds/02-terminal/04-copy-mode/prd.md` gained on its 2026-08-22 `claimed →
done` transition, which records that no `opacity` user-var arm survives the
wallpaper-opacity decision — a removal record the substring test cannot
distinguish from a survival.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/02-terminal/04-copy-mode/prd.md; rc=0; T="$(tr "\n" " " < "$f" | tr -s " ")"; has() { echo "$T" | grep -qF "$1" || { echo "FAIL: missing: $1"; rc=1; }; }; no() { echo "$T" | grep -qiF "$1" && { echo "FAIL: still asserts: $1"; rc=1; }; }; has "Ctrl+Shift+X"; has "54"; has "search_mode"; has "Ctrl+Shift+F"; has "ClipboardAndPrimarySelection"; has "pane id"; has "SetUserVar"; has "PasteFrom"; has "SendKey"; has "StartWindowDrag"; has "mouse_reporting"; has "OpenLinkAtMouseCursor"; no "F3"; no "bright cyan"; no "immutable"; no "no input/output occurs"; no "copies entire visible content"; no ":w /Users/feb"; no "burrito"; echo "$T" | grep -qF "opacity" && { echo "FAIL: the OSC-1337 opacity user-var is dropped by decision 5(b); only copymode survives"; rc=1; }; echo "$T" | grep -qiE "all 55 (builtin )?(motions|keys)" && { echo "FAIL: repeats the inventory 55-builtins error"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
