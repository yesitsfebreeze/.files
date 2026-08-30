# probe notes — 07-multiplexer/05-copy-and-clipboard

Host: macOS 25.2 (Darwin 25.2.0, arm64), tmux 3.7c (/opt/homebrew/bin/tmux),
wezterm 20240203-110809-5046fc22, pbcopy/pbpaste at /usr/bin.
Everything below was MEASURED on this host. Scripts are beside this file.

## C1 — `Ctrl+Shift+X` cannot be expressed in the legacy key encoding

`probe/01-cs-x.sh`, the F14/F15 nested fixture (outer tmux pane runs
`tmux -L inner attach`, so `send-keys` to the outer pane is a real keystroke
into the inner's key dispatch). Inner binds BOTH `C-S-x` and `C-x` and logs
which fires:

| inner `extended-keys` | format | inner saw |
|---|---|---|
| off | xterm | `PLAIN-CX` |
| on | xterm | `PLAIN-CX` |
| on | csi-u | `PLAIN-CX` |
| always | xterm | `PLAIN-CX` |
| always | csi-u | `PLAIN-CX` |

`probe/02-bytes.sh` says why, at the byte level: `tmux send-keys C-S-x`
writes the single byte `^X` to the pane, identical to `C-x`, and it does so
whether or not the pane has requested modifyOtherKeys (`CSI >4;2m`), the
kitty protocol (`CSI >1u`) or DECSET 2027. Ctrl+X and Ctrl+Shift+X are the
SAME BYTE in the legacy encoding; no option makes tmux's own encoder produce
a different one.

## C2 — but tmux DECODES both extended-key spellings, unconditionally

`probe/03-csiu-decode.sh`. Raw bytes written into the inner tmux CLIENT's
stdin (which is where a terminal emulator puts them), inner binding `C-S-x`:

| bytes | inner `extended-keys` = off / on / always |
|---|---|
| `CSI 120;6u` (kitty / CSI-u, unshifted `x`=120, mods 6 = ctrl+shift) | `CSX` / `CSX` / `CSX` |
| `CSI 27;6;120~` (xterm modifyOtherKeys) | `CSX` / `CSX` / `CSX` |

So `extended-keys` governs what tmux **sends**, never what it **accepts**.
The binding needs no option at all — it needs a terminal that emits one of
those two forms.

**Consequence, and it is the node's one open dependency.** WezTerm as this
repo configures it emits neither: `enable_kitty_keyboard = false`
(`wezterm.lua:1071`) is a matched pair with nushell's
`use_kitty_protocol = false`, with a recorded reason (reedline fires the
kitty support query at startup and leaks `^[[?...u` over the prompt), and
`enable_csi_u_key_encoding` is off by default. So on this desk `C-S-x` is
delivered as `^X` and the binding never fires. The gap closes with ONE line
in `wezterm.lua` — `Ctrl+Shift+X` → `SendString "\x1b[120;6u"` — in the very
block `08-wezterm-reduction` is already deleting. Filed for that node; not
taken here, because `wezterm.lua` and `tests/wezterm-copy-mode.sh` are
another epic's footprint and `02-terminal/04-copy-mode` is `done` with a
registered gate that asserts the current binding.

Not measured, and honestly so: what WezTerm's GUI actually puts on the pty
for Ctrl+Shift+X. Measuring it needs a real window plus synthetic keystrokes
(osascript / Accessibility), which is not a headless probe and is intrusive
on the user's machine. What IS measured is the tmux half — the decode above —
so the shim's target encoding is proven even though WezTerm's default is
inferred from its config flags.

## C3 — binding `C-S-x` costs plain `C-x` nothing

Conf binding ONLY `C-S-x` in the root table; a pane running `cat -v`
receives `^X` when `C-x` is sent. So nvim's `i_CTRL-X` completion prefix and
every readline binding are untouched. Binding `C-x` instead — the byte that
actually arrives on a legacy terminal — would have taken all of them, which
is why "just bind what arrives" is not the cheap fix it looks like.

## C4 — the selection granularities, and the trap in cycling back

`probe/04-cycle.sh`, pane content `alpha beta gamma delta`, cursor on `beta`
(x=6). Selection read back with `copy-pipe-no-clear`:

| after | selection | `selection_active` | `selection_present` |
|---|---|---|---|
| (nothing) | `` | 0 | 0 |
| `begin-selection` | `b` | 1 | **0** |
| `select-word` | `beta` | 1 | 1 |
| `select-line` | `alpha beta gamma delta` | 1 | 1 |
| `select-word` again | **`delta`** | 1 | 1 |
| `clear-selection` | `` | 0 | 0 |

Two findings in one table.

- **A one-cell selection reads `selection_present` 0** while
  `selection_active` is 1. A state machine driven off the selection desyncs
  on its own first step — which is exactly the reason
  `02-terminal/04-copy-mode` R4 gives for tracking by pane id rather than by
  reading the selection back. The reason survives the change of mechanism;
  the state lives in a per-pane option instead.
- **`select-word` after `select-line` reads `delta`, not `beta`.**
  `select-word` leaves the cursor at the word end and `select-line` at the
  line end, so a cycle that wraps back anchors wherever the last selection
  ENDED. This is the defect that makes a naive three-state cycle wrong on its
  fourth press.

## C5 — `set-mark` / `jump-to-mark` is the anchor restore, and its own trap

`probe/05-mark.sh`. `jump-to-mark` SWAPS cursor and mark (it does not copy),
so the restore idiom is `jump-to-mark` then `set-mark`:

```
anchor x=6 y=1
1 cell   sel=[b]                       x=6
2 word   sel=[beta]                    x=9
3 line   sel=[alpha beta gamma delta]  x=21
   jump-to-mark                        x=6   ← anchor restored
4 cell   sel=[b]                       x=6
5 word   sel=[beta]                    x=9
6 line   sel=[alpha beta gamma delta]  x=21
7 cell   sel=[b]                       x=6
```

**Trap:** `jump-to-mark` with NO mark set does not stay put — it moves the
cursor to x=0 y=2. So the cycle may only jump in a state that is reachable
only after the state that sets the mark, and a stale per-pane state from an
earlier copy-mode session would walk the cursor. C6 is what guards it.

## C6 — `after-copy-mode` fires on every entry path

Measured with `set-hook -g after-copy-mode 'set -pu @copy-cycle'` and a
pane option pre-set to a stale value: it is cleared after `copy-mode` AND
after `copy-mode -e` (the form the default mouse-wheel binding uses).

This is strictly better than resetting inside the `C-S-x` binding, which is
what `02-terminal/04-copy-mode` R1 does: copy mode is also entered by the
mouse wheel and by `copy-mode` typed as a command, and on those paths a
binding-side reset never runs. The R1 reason — "resetting on ENTRY is what
makes an exit by q/Esc/y unable to leave the toggle stale" — is preserved
and widened.

## C7 — `set -p` and `#{@opt}` work where the cycle needs them

`set -p @copy-cycle <v>` sets a PANE option; `#{@copy-cycle}` resolves it in
`display -p -t <pane>` and in an `if -F` inside a `copy-mode-vi` binding.
An unset option reads as the empty string, and `#{==:#{@copy-cycle},cell}`
is a usable three-way discriminator. Nested `if -F … { } { }` blocks parse
inside a `bind -T copy-mode-vi` body (verified by `list-keys`, and by the
cycle running).

## C8 — tmux DOES put OSC 52 on the wire, and `script` cannot see it

First attempt used `script -q log tmux attach` inside the outer pane, as
`01-session-and-windows` F17 does for the pty attach. **It logged zero
bytes** in every arrangement — the buffer never reaches disk before the pane
dies. The technique that works is the outer tmux's own
`pipe-pane -O -t <pane> 'cat >> log'`, which records every byte the inner
client writes to its terminal.

With that, `probe/08-osc52-matrix.sh`:

| inner `set-clipboard` | client TERM | OSC 52 on the wire |
|---|---|---|
| `external` (tmux's default) | xterm-256color | **yes** |
| `off` | xterm-256color | no |
| `on` | xterm-256color | yes |
| `on` | screen-256color | yes |
| `on` + `terminal-features ",*:clipboard"` | screen-256color | yes |
| `on` | vt100 | yes |
| `on` + `,*:clipboard` | vt100 | yes |
| `on`, via `copy-pipe-and-cancel 'cat >/dev/null'` | xterm-256color | yes |

Payload verified: `ESC ] 52 ; ; TUFSS0VSLWFscGhhLWJldGEK` — base64 of
`MARKER-alpha-beta\n`.

Three things worth carrying:

- **The `Ms` folklore is dead on 3.7c.** The standard advice is that OSC 52
  needs the terminal to advertise the `Ms` capability, hence the widely
  copied `set -as terminal-overrides ',*:Ms=\E]52;%p1%s;%p2%s\007'`. On
  3.7c the sequence goes out for `vt100`, so neither that override nor
  `terminal-features ",*:clipboard"` is doing anything here. Neither is in
  the conf. On an older tmux they may be; that is a claim about a version
  this probe did not run.
- **`external` — the default — already emits.** So deleting `set -s
  set-clipboard on` from the remote arm would NOT go red on the wire check
  alone: the F16 shape. The discriminating mutation is `off`, and the gate
  asserts the option value as well as the wire.
- **`copy-pipe-and-cancel <cmd>` emits OSC 52 too**, because it sets a paste
  buffer on the way. That is what forces C9's choice.

## C9 — `set-clipboard off` does NOT stop an application's OSC 52 on 3.7c

`probe/10-app-osc52.sh` writes a raw `ESC ] 52 ; c ; RlJPTS1BUFA= BEL` from
inside the inner pane (what remote nvim's osc52 provider does on the far end
of an ssh) and reads the outer wire:

| inner `set-clipboard` | forwarded to the outer terminal | inner paste buffer |
|---|---|---|
| `off` | **yes** | not set |
| `external` | yes | not set |
| `on` | yes | not set |

The manual describes `off` as also refusing application sequences. **That
did not reproduce on 3.7c.** It matters because it is what makes the
exclusive sink affordable: `set-clipboard off` is set only on the arm where
`pbcopy` exists — this machine, this tmux — and it costs nothing there.
Do not restore `on` locally on the strength of the manual page without
re-measuring.

## C10 — the design, driven end to end through real key dispatch

`probe/09-draft.sh`, nested fixture, entry by the raw `CSI 120;6u` bytes and
every subsequent key sent to the OUTER pane:

```
conf rc=0  sink=[pbcopy] set-clipboard=[off] mode-keys=[vi]  root C-S-x binds: 1
after C-S-x        mode=[copy-mode]
c 1  cyc=[cell] sel=[b]
c 2  cyc=[word] sel=[beta]
c 3  cyc=[line] sel=[alpha beta gamma delta]
c 4  cyc=[cell] sel=[b]            ← wrapped, anchor intact
c 5  cyc=[word] sel=[beta]
y    mode=[] cyc=[] pbcopy.out=[b]
```

(That run still had `set-clipboard on`, and the wire showed `]52;;Yg==` —
"b" — alongside the pbcopy write. Two sinks, not one. C9 is why the shipped
conf takes `off` on the local arm instead.)

## Findings for the report — defects and gaps OUTSIDE this node's scope

- **`08-wezterm-reduction` owes the `Ctrl+Shift+X` shim.** See C1/C2. One
  line, in a block it is deleting anyway, plus the matching assertion in
  `tests/wezterm-copy-mode.sh`. Without it the node's headline key does
  nothing on this desk, and there is no tmux-side fix — the terminal has to
  emit the bytes.
- **`gates/waves.tsv` still cannot register a `07-multiplexer` gate.** No
  node in the epic carries a `task:` id, so `tests/tmux-copy-and-clipboard.sh`
  joins `capsule-recents-gui.sh`, `nvim-session.sh` and
  `tmux-session-and-windows.sh` on `wave-status.sh --validate`'s
  unreferenced list. Reported, per the brief; not fixed, and no box claims
  `gates/selftest.sh` exits 0.
- **`prds/02-terminal/04-copy-mode/prd.md` is `state: done` with every
  requirement box `- [ ]`.** Already filed by the epic; re-confirmed while
  reading it, since this node ports its R1 and R4 reasons.
- **The `retired-phrases.sh` carrier is still this epic's own memo.**
  `prds/memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md` carries
  "the terminal owns the palette" (in the I2 reversal, as the phrase being
  reversed). Unchanged since `01-session-and-windows` F19 reported it.

---

## Pass two — everything below was measured AFTER `02-key-tables` appended

Mid-build, `07-multiplexer/02-key-tables` appended ~265 lines to the same
`home/dot_config/tmux/tmux.conf` — the two nodes were dispatched together
without noticing they share the file. Nothing above this line was re-taken
against the merged file except where it says so; everything below was.

## C11 — the two sections are disjoint, and that was luck

Measured on the merged file (425 lines):

- Section boundaries: `01-session-and-windows` 1–152, `02-key-tables`
  154–277, `05-copy-and-clipboard` 279–425. Nothing interleaves.
- `bind -n` keys across the whole file: `F4`, `F5`, `F6`, `C-S-x` — no
  duplicate.
- `bind -T <table> <key>` across the whole file: no duplicate.
- `set`/`set -g`/`set -s`/`set -gw` targets: the only repeat is
  `terminal-overrides`, which is `01-session-and-windows`' two deliberate
  `-as` appends (Smulx and Setulc).
- `mode-keys` is set once, by this node.

Two adjacencies that could have collided and do not, because the tables are
different: `02-key-tables` binds `c` and `g` in its **`jump`** table
(`select-pane -t :.3` and `:.7`) while this node binds `c` and reads `g` in
**`copy-mode-vi`**. And `F4`/`F5`/`F6` are root-table bindings, which are not
consulted while a pane is in copy mode — so none of them is reachable from
inside the c-cycle, and none of this node's keys is reachable from the split
or jump tables.

The full gate was re-run against the merged file: 52 checks, 0 FAIL, three
consecutive runs byte-identical.

## C12 — a `set-option` BEFORE a copy command silently suppresses the OSC 52

The expensive finding of this node, and it was found only because the gate
reads the wire rather than the paste buffer.

The first shipped shape of `y` was
`{ set -pu @copy-cycle ; if -F … 'send -X copy-selection-and-cancel' }`.
Sink arm B went red: the paste buffer held the right text, `show-buffer`
read `beta`, the binding had plainly run — and no OSC 52 was on the wire.

Bisected, in a minimal conf, one key press each, `set-clipboard on`:

| `y` binding body | paste buffer | OSC 52 |
|---|---|---|
| `send -X copy-selection-and-cancel` | set | **sent** |
| `{ send -X copy-selection-and-cancel }` | set | sent |
| `{ if -F … { copy-selection-and-cancel } { … } }` (true arm) | set | sent |
| same, false arm taken | set | sent |
| `{ set -pu @o ; send -X copy-selection-and-cancel }` | set | **NONE** |
| `{ set -p @o x ; send -X copy-selection-and-cancel }` | set | **NONE** |
| `{ send -X copy-selection-and-cancel ; set -pu @o }` | set | sent |
| `{ if -F … ; set -pu @o }` (set after the if) | set | sent |

So it is **not** `if-shell`, **not** the block form, **not** the false arm,
and **not** the option being read in the condition. It is a `set-option`
executing in the same key binding *before* the copy. Order is the whole fix.

Four blind alleys on the way, each eliminated by measurement rather than by
reading: the stub PATH (innocent — a direct `send-keys -X` copy emits under
the same stub), the client's TERM (innocent — `vt100` emits), the
`terminal-features`/`terminal-overrides` lines (innocent), and the `c`
binding's own `set-mark`/`clear-selection` (innocent — the real `c` binding
in a minimal conf emits fine).

**Why it matters more than a bug in a config file.** The failure is silent in
the worst possible place: the buffer is set, the selection is right, nothing
is logged, and the arm it breaks is the REMOTE one — the arm that exists
because this epic is about following an ssh. A gate asserting `show-buffer`
would have been green through all of it. This is the whole argument for
reading the wire.

## C13 — `copy-mode-vi v` is not a stable reading on 3.7c

`tmux -L x -f /dev/null start-server` then `list-keys -T copy-mode-vi` prints
`v  send-keys -X begin-selection`. `tmux -L x -f /dev/null new-session -d`
then the same command prints `v  send-keys -X rectangle-toggle`. Same binary,
same conf, reproduced three times each; `mode-keys` reads `vi` in both and
setting it to `emacs` changes nothing. `Space` (begin-selection) and `V`
(select-line) read the same in every arrangement.

Not chased further — the point is that a gate asserting `v` would take its
colour from how the fixture happened to start the server. The gate asserts
`Space` and `V`.

## C14 — two shell traps the gate hit, both of which made it flake

- **`v="$(cmd < file 2>/dev/null)"` cannot suppress a missing-file
  diagnostic.** Redirections are applied left to right, so the `< file`
  failure is reported before the `2>/dev/null` is in effect. It put a
  `/private/var/folders/…` path into the output, which is exactly what breaks
  the two-runs-are-byte-identical property. Sink files are pre-created and
  read through `cat file 2>/dev/null | tr -d '\n'`.
- **A single fixed sleep after `y` is not enough.** The copy travels outer
  pane → inner client → inner server → a piped command. `sink A` failed on
  one run in two with an empty file and passed on the next. The gate now
  settles before `y` (each `sel_of` leaves a `copy-pipe-no-clear` job in
  flight) and polls for the sink file afterwards. A check that is empty half
  the time is worse than a red one.

## Verdict

SPECCED. specs/spec01 (the conf section), specs/spec02 (the gate). Both are
BUILT and green: `bash tests/tmux-copy-and-clipboard.sh` → 52 PASS, 0 FAIL,
rc 0, byte-identical across three runs; `--selftest` → 22 PASS, 0 FAIL.
