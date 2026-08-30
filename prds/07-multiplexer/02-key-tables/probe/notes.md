# probe notes — 07-multiplexer/02-key-tables

Host: macOS 25.2, tmux 3.7c (/opt/homebrew/bin/tmux). Every finding MEASURED.
Builds on 01-session-and-windows' notes (F1-F19); its F14/F15 nesting fixture
is the only way to test a binding at all and is reused throughout.

## K1 — an unbound key in a custom table is SWALLOWED, and the table resets

`probe/p1-unbound.sh`. Inner conf: `bind -n F5 switch-client -T jump`,
`bind -T jump 1 select-window -t :1`, and NOTHING else in the table. Inner
pane runs `cat > file` so every byte that reaches the pty is visible.

    F5 then z   → pane received nothing (`\n` only, from the later Enter)
                  `#{client_key_table}` back to `root`
    plain y     → pane received `y`   (the control: dispatch is working)

So tmux already does natively what WezTerm's 26 bare-cancel letter binds were
built to emulate: a key with no binding in the active table is consumed, the
client returns to `root`, and nothing leaks into the running program. The
REASON `02-terminal/03-f5-jump-mode` R2 gives still holds exactly — a mistyped
letter must cancel rather than type itself into nvim — and on this mechanism
it holds for free. 26 explicit `Nop` binds would be dead code.

That is why the control matters: without the `y` line the finding is
indistinguishable from "the fixture never delivered any key".

## K2 — CORRECTS K1's mechanism. An unbound key is retried against `root`

`probe/p2-doubletap.sh`, three arms. tmux does not simply drop a key that a
custom table does not bind: it **falls back to the root table and looks the
key up a second time**, and only drops it if root does not bind it either.
That second lookup is why nothing reaches the pane — a normal `root`-table
miss types into the program, a *second-time* miss does not.

The arm that proves it is B. Conf has `bind -n F5 switch-client -T jump` and
no `bind -T jump F5`:

    [B] F5 F5 → pane received NOTHING, and #{client_key_table} = jump

The second F5 was not dropped and not forwarded — it missed in `jump`, hit
`bind -n F5` in `root`, and pushed `jump` again. Two consequences:

1. **Q10 needs the explicit bind; it is not free.** With
   `bind -T jump F5 send-keys F5` (arm A) the pane receives `033 [ 1 5 ~` —
   a literal F5 on the wire, which is exactly what a nested tmux reads as
   F5. Without it the double-tap is a no-op that silently re-arms the table.
2. **Any `-n` root binding fires from inside a pushed table.** That is
   acceptable here (F4 from inside `jump` opening the split table is the
   sane reading) but it is a fact a sibling node must know before adding a
   root binding.

Arm C is the control: with no `bind -n F5` at all, both F5s pass straight
through and the pane reads `033 [ 1 5 ~` twice.

**Fixture trap, cost one wrong reading:** the inner pane runs `cat > file`
and the pty is in canonical mode, so nothing appears until a newline. The
first run of this probe read "pane received nothing" for ALL THREE arms and
would have concluded the forwarding did not work. Every arm now sends Enter
before reading.

## K3 — Q2's lazy create, with no shell: `#{W:}` plus `#{m:}`, and the delimiter is load-bearing

`if-shell -F` tests a FORMAT and spawns no shell, so `F5 <digit>` costs no
`/bin/sh` per press. The existence test is a loop over the window list:

    #{W:|#{window_index}|}      →  |0||4||7|
    #{m:*|1|*, <that>}          →  1 when window 1 exists, 0 when it does not

Measured working on 3.7c, which is the version question — `#{W:}` is not in
old tmux.

**The delimiter must not be a glob metacharacter, and the obvious one is.**
`#{m:}` is fnmatch, where `[` opens a character class. With `[` as the
delimiter and exactly one window, index **11**:

    #{m:*[1]*,#{W:[#{window_index}]}}   → 1     ← asks "does window 1 exist"
    #{m:*|1|*,#{W:|#{window_index}|}}   → 0     ← correct

`*[1]*` reads as "any char, then one of the set {1}, then any", so it matches
the `1`s inside `[11]` and the binding would `select-window -t :1` against a
window that is not there. `|` has no meaning to fnmatch. The `|0||11|`
doubled bars are harmless.

## K4 — the built conf, driven through real key dispatch

`probe/p5-behaviour.sh`, nested fixture, three distinct directories
(session `$D/sess`, active pane `$D/pane`, client `$D/client`).

| gesture | result |
|---|---|
| `F5 4` on a session with only window 1 | windows read `1 4`, active 4 — created |
| `F5 4` again | still `1 4`, active 4 — selected, not duplicated |
| `F4 Right` with the pane cd'd elsewhere | new pane at **`$D/pane`**, focus moves to it |
| `F4 Down` | third pane appears |
| `F5 a` / `b` / `c` | pane index 1 / 2 / 3 |
| `F5 z` (unbound) | `#{client_key_table}` = root, pane unchanged |
| `F5 h` (pane 8, absent) | table = root, pane unchanged, no crash |

**The `-c ~` on the create arm turned out to be load-bearing, not decorative.**
The fixture's session path is `$D/sess`, and the created window's
`#{pane_current_path}` reads `/Users/feb`. Without `-c ~` a key-bound
`new-window` resolves the SESSION's path (01-session-and-windows F14), so it
would have landed in `$D/sess`. Q14 therefore holds against a session
somebody else created somewhere else, which is what the belt-and-braces was
for — and it is provable only because the fixture put the session path
somewhere that is not `$HOME`.

**And the two cwd rules provably disagree**, which is the point of Q14: the
same run has the digit landing at `~` and the split landing at the active
pane's directory. A fixture where the session path equalled `$HOME` could not
tell those apart.

## K5 — F4 F4 forwards SS3, not CSI, and no letter leaks

`probe/p6-leak-and-tap.sh` against the REAL conf, inner pane running `cat` so
every byte on the pty is on disk:

    F5 F5 F4 F4  → pane received  033 [ 1 5 ~   033 O S

`033[15~` is F5 and **`033OS` is F4** — xterm puts F1-F4 on SS3 (`ESC O P/Q/R/S`)
and F5 upward on CSI. The expectation written into the first draft of the
probe was `033[14~`, which is not F4 in any terminfo this runs under. A gate
must assert the SS3 form or it fails on a correct implementation.

`F5 z`, `F5 q`, `F5 Escape`, `F5 Space`, `F5 0` each leave
`#{client_key_table}` at `root` and put nothing on the pty. `0` is worth
naming: only 1-9 are bound, so the missing digit is the one mistype a digit
user actually makes, and it cancels.

F6 appears once in `root`, zero times in `jump` and `split`, and `send-keys
F6` appears nowhere — Q10's "never forwarded", as a readable fact rather
than an absence nobody checked.

## K6 — a lone Escape immediately before a function key eats the function key. NOT this node's

Cost two wrong readings before it was isolated, and it is the reason the
first leak probe reported a `0` leaking out of `F5 0`.

    gap 0.45s   Escape F5 0   → pane got  033 033 [ 1 5 ~ 0   (F5 not seen at all)
    gap 2.0s    Escape F5 0   → pane got  033                 (F5 seen, 0 dropped)
    gap 0.45s   q      F5 0   → pane got  q                   (clean)
    gap 0.45s   Escape Escape F5 0 → pane got 033 033         (clean)

So a *single* lone Escape delivered to an attached tmux client shortly before
an escape-sequence key makes that key arrive as literal bytes; a second
Escape, an ordinary character, or two seconds all clear it.

**It is not this node's bindings.** Re-measured against an inner conf holding
`set -g status off` and `bind -n F5 new-window` and nothing else:

    F5              → a window is created
    Escape F5       → NO window is created
    q F5            → a window is created
    Escape Escape F5 → a window is created

Nothing of 02-key-tables is present in that conf. Consequences: it is
reported, not fixed; and **the gate must never put an Escape immediately
before a function key in its fixture**, or it will fail on a correct conf.

## K7 — F6 end to end, and how it was made testable

F6 was the one key nothing proved: `list-keys` reads that it is bound and
stops there. The chain is
`key → run-shell -b → sh -lc → nu -n -c "source theme.nu; _theme_toggle"`, and
its most breakable part is the quoting, which crosses the tmux conf parser,
tmux's own command parser and two shells before nu sees it.

`run-shell` inherits the SERVER's environment, and the server's comes from the
client that started it — so starting the inner tmux under
`env HOME=<scratch>` redirects `$HOME/.config/nushell/theme.nu` at a stub. The
stub is a real nushell module (`export def _theme_toggle [] { … save … }`), so
a real `nu` parses and runs it; only the contents are fake. Pressing F6 in the
nested fixture wrote the marker. What tinty then does is 04-palette-delivery's
question, not this node's.

`sh -lc` stays a LOGIN shell for the reason the WezTerm binding measured on
2026-08-23: /etc/profile runs path_helper, which puts Homebrew's bin on PATH
by itself. So the conf names no Homebrew path and stays portable, and the two
directories prepended are the ones no login shell adds — `tinty` lives in
`~/.local/bin`. Both are `$HOME`-relative and inert where absent.

## K8 — the mutation chain that reported green while planting a defect

`--selftest` reassigns `$CONF` so the nested fixture points at a mutant, and
the first `mutate` copied from `$CONF` rather than from the real conf. M3
removes `bind -T jump F5 send-keys F5`, so M5 — built on M3 — held 9 digits +
9 letters + 0 forwarders + its own planted bind = **exactly the 19 keys its
check demanded**. It printed PASS while carrying the defect it was planting.
Every mutant now copies from `$REAL`, captured once.

The same run also caught `sed -i ''` having no `\n` in an `s` replacement on
BSD: two "add a line" mutations silently produced an unchanged file, and both
checks read green for the same reason. Additive mutations now append.

## Verdict

SPECCED. specs/spec01 (the conf section), spec02 (the gate). Both are BUILT
and measured: `bash tests/tmux-key-tables.sh` is 82 PASS / 0 FAIL, byte-
identical across two runs, and `--selftest` is 12 PASS / 0 FAIL.

## Findings for the report — defects and gaps OUTSIDE this node

- **A lone Escape immediately before a function key eats that key** (K6). Not
  this node's bindings; reproduced against a two-line conf. Whether a person
  ever hits it depends on how fast Esc→F5 is typed at a real terminal, and
  that is a human check nobody has run. Worth an entry in `gates/manual/`.
- **Two sessions were appending to `home/dot_config/tmux/tmux.conf` at once.**
  `07-multiplexer/05-copy-and-clipboard`'s `bind -n C-S-x`, `mode-keys vi` and
  `copy-mode-vi` binds arrived in the working tree during this build. The
  epic's plan does say later children append to this file, but the sections
  being disjoint is luck rather than the single-writer rule. This gate passes
  with those lines present — deliberately: the root-table check counts
  function keys, not bindings.
- **`gates/waves.tsv` cannot register this gate.** Rows are keyed by `task:`
  ids from node frontmatter and no node in `07-multiplexer` carries one, so
  `gates/wave-status.sh --validate` will list `tmux-key-tables.sh` as
  unreferenced alongside the four already there. Reported, not fixed; no box
  claims `gates/selftest.sh` exits 0.
- `shellcheck -S warning` reports SC2319 on 27 lines. That is the house
  dialect — `cond; chk "…" $?` — and `tests/tmux-session-and-windows.sh` has
  the same shape. The dangerous variant, a `$( )` in the label, is what
  `status_lint` forbids and there is none.

## Implementer pass — 2026-08-29

Resumed after a dropped connection. Read prd.md, both specs, K1-K8, the conf
and the gate. Pass one is present in the working tree: the conf section
(tmux.conf lines 154-277) and `tests/tmux-key-tables.sh` (575 lines).
Next: fix spec01's verify block, then run every verify.

- spec01 verify narrowed: the gate now reads `$TKT_CONF` (falls back to the
  repo's conf), so the command names the file it proves —
  `TKT_CONF=home/dot_config/tmux/tmux.conf bash tests/tmux-key-tables.sh
  --tables|--keys`. No box asserts `gates/selftest.sh` or `just gates`.
- `--tables` rc 0, 61 PASS / 0 FAIL. `git diff -U0` on the conf: one hunk
  `@@ -152,0 +153,279 @@`, 279 insertions, 0 deletions — pure append.
  spec01 boxes 1-7 ticked.
- Next: `--keys`.
- `--keys` rc 0, 25 PASS / 0 FAIL. spec01 boxes 8-10 ticked; spec01 is 10/10.
- Next: spec02 — no-arg twice for byte-identity, then --selftest.
