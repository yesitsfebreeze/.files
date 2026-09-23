# tmux

> The multiplexer base — what each non-obvious line in tmux.conf is defending against.

`tmux.conf` is the portable half of the environment. Nothing in it may assume
WezTerm, macOS or Homebrew: the whole point is that it is the same file on a
box reached by ssh ten minutes ago.

Everything below was measured on **tmux 3.7c** unless another version is named.

## The terminal-integration floor

### `default-terminal` is probed, not asserted

`tmux-256color` is the correct entry and is **absent** on plenty of minimal
hosts — Debian slim, Alpine, a container from a base image. A
`default-terminal` naming a terminfo entry that does not exist is not a soft
failure: **tmux refuses to create the session at all**. So the entry is probed
at parse time and `screen-256color`, which every ncurses install carries, is
the floor.

`if-shell` in a config file runs **synchronously** — the branch is taken before
the command line's `new-session` runs — which is what makes this safe to write
as a conditional rather than a background job that lands too late.

### Truecolour and undercurl are features, not reads

`*:RGB` tells tmux the *client* terminal can take direct-colour SGR, so 24-bit
colour set inside a pane survives the trip out. Without it every palette this
environment ships is quantised to 256 colours.

Undercurl and coloured undercurl (`Smulx`/`Setulc`) have no standard terminfo
capability, but tmux carries both under the `usstyle` feature — that is what
Neovim's diagnostic underlines ride on. TRAP: hand-writing the two capability
strings instead prints their own operands into the pane the moment a `%` is
missing — a run of `256/256{` next to every diagnostic, cleared on the next
redraw, which is what makes it read as a rendering glitch rather than a config
error.

### Hyperlinks are dropped unless the *client* feature is on

`*:hyperlinks` under `terminal-features` sets the `Hz` capability on the
outer terminal's description, and that is what makes tmux re-emit an OSC 8
link it received from a pane instead of stripping it. Without it the link is
in the pane buffer (`capture-pane -e` shows it) but never reaches WezTerm, so
there is nothing at the cursor to shift-click — measured 2026-08-31 on
tmux 3.7c with WezTerm attached as `xterm-256color`.

### Redraws are synchronized

`sync` makes tmux wrap every redraw in DEC mode 2026, so WezTerm paints only
finished frames. Without it a pane-header redraw is an erase then a rewrite,
and the two reach the screen separately: the header bar flickers every time a
header repaints (a `#(tmux-git)` tick, a Claude state report). The four client
features sit in two indexed entries, `terminal-features[3]` and `[4]`: `set -a`
appended them again on every reload, and the list had reached 76 entries.

tmux-claude-state only repaints on a change: setting a pane option redraws
every header and the bar on every client, so a repeated report is skipped
inside the same single `tmux if -F` call.

TRAP: features are resolved **once, at client attach**. `tmux source-file`
updates the `terminal-features` option (visible in `tmux show -s`) but an
already-attached client keeps the set it was attached with — reloading is not
enough, the client must detach and come back. Check the live value with
`tmux display -p '#{client_termfeatures}'`; `hyperlinks` has to be in it.

### `escape-time 10`

tmux waits this long after an `Esc` for the rest of an escape sequence.
Anything larger is felt directly as a delay leaving insert mode in nvim. 3.7c
already defaults to 10 (it was 500 for years) — it is stated anyway, because
the conf must be right on the older tmux a minimal host actually ships.

### `allow-passthrough` is a window option

A DCS-wrapped sequence from inside a pane reaches the outer terminal. This is
the channel both the palette's OSC 4/10/11 and the clipboard's OSC 52 ride,
and it is **off** by default. Being a window option, `-g` sets the global
window default and every window created afterwards inherits it.

## Addressing

### `renumber-windows off` is the whole scheme

This is why the WezTerm reconciler died. Its slot ledger — ~320 lines and its
own test — existed because WezTerm tab indices shift when a tab closes, so a
digit was not a stable address without being *made* one. tmux indices are
stable natively, and this line is what keeps them that way: with
`renumber-windows on`, closing window 4 would slide 5–9 down and every digit
would address different content.

`off` is the default. It is stated because the entire addressing scheme
depends on it.

### Both indices start at 1

A keyboard has no `0` next to the `1`, so `base-index` and `pane-base-index`
are both 1 and the key matches the label.

## Where a new window starts

A lazily created window starts at `~`, deliberately **not** the `F5 Shift+<arrow>`
split's rule, which inherits the active pane's cwd. The two gestures disagree
on purpose: a split divides *this* work, a digit is a clean slate.

Measured with the session path, the pane's cwd and the client's cwd all set to
**different** directories — a first reading with two of them equal could not
tell them apart and got this backwards. `new-window` with no `-c` resolves its
directory from *who ran it*:

| Invoked from | Resolves to |
|---|---|
| typed into a shell | the pane's cwd |
| run from outside tmux | the client's cwd |
| **a key binding** | **the session's working directory** |

The last is the only one anybody presses, so a binding that wants `~` has to
say so. Every digit bind carries `-c ~` explicitly for that reason; **do not
add a `new-window` that leans on the session directory instead.** It used to
be able to: the session was created at `$HOME` and the digit binds inherited
it. Since 2026-09-01 the session is created at the recorded start dir (below),
so the inherited answer is no longer `~`.

`tmux.conf` cannot set a default itself — tmux has had no `default-path`
option since 1.9.

## Where the start dir is read

**04-shell R7** — a new shell opens in the last directory navigated to — is
one read, in `~/.local/bin/tmux-main`, on the session that has no parent to
inherit from. `mkcd` writes `~/.local/state/nushell/startdir.txt` on every
move; `tmux-main` passes it as `new-session -c`, falling back to `~/dev` and
then `$HOME`.

**TRAP: it must not be read per shell.** `nushell/env.nu` used to do exactly
that, unconditionally, on every interactive shell — and it ran *after* the
launcher had placed the process, so inside tmux it silently defeated every
`-c` in this file. Measured 2026-09-01: `tmux split-window -c /usr/local`
landed the pane in whatever `startdir.txt` held, which is the last directory
visited in *any* pane. Both documented behaviours above were false in
practice — a split did not inherit its parent and a digit window was not a
clean `~`; both read one global file. `env.nu` now guards on `$env.TMUX` being
empty, which keeps the old behaviour for a bare `nu` (the no-tmux fallback in
`tmux-main` execs one).

## Where a split starts

`#{E:@cwd}` — set at the top of `tmux.conf` — is the pane's real working
directory, and the only thing a gesture meaning "here" may use: the split
binds, the F3/F8 popups' `-d`, the status bar.

**TRAP: `#{pane_current_path}` is not where the pane is.** It is the pane
process's OS cwd, and nushell never changes it — `cd` moves `$env.PWD` and
leaves the process where it was launched. Measured 2026-09-01 on tmux 3.7c, a
pane whose prompt sat in `~/dev/dotfiles` reported
`pane_current_path=/Users/feb/dev/infra/pearde`, the directory it had been
started in. `#{pane_path}` is the OSC 7 report instead, which nushell emits on
every prompt.

OSC 7 is a URL — `file://<host><path>` — so `@cwd` strips the host and guards
on it. Three measurements shape the expression:

| Written | Why not the obvious spelling |
|---|---|
| `file.//` | `#{s\|a\|b\|:var}` splits on the FIRST `:`, so a literal colon in the pattern truncates the modifier and the whole format yields `""`. `.` stands in for it |
| replacement `/`, not empty | an empty replacement also yields `""` rather than the stripped string |
| `#{m:pat,str}` | `#{m\|pat\|str}` is not parsed; it comes back as literal text |

The `m:` guard is the ssh case: a pane logged into another box reports *that*
box's path, which does not exist here. Only an OSC 7 naming this host is
trusted, and anything else falls back to `#{pane_current_path}` — for an ssh
pane that is the local cwd, which is the right answer.

`#{E:@cwd}` is used rather than the expression, except in `pane-border-format`,
the pane header, which spells it out. That is not duplication for its own sake: `:...` names a
*variable*, so a substitution cannot be applied to an expanded option —
`#{s|^$HOME|~|:@cwd}` substitutes over the option's literal text and
`:E:@cwd` yields `""`. The `~` collapse therefore rides inside the branch,
chained onto the host strip with `;`, which is how one `#{}` carries two
substitutions.

One more: **`-c`'s format expands against the client's ACTIVE pane, not
`-t`.** Measured 2026-09-01 — `split-window -t %224 -c "#{E:@cwd}"` from the
command line resolved `@cwd` against the active pane and opened the split in
*its* directory. The binds are unaffected because a key is pressed in the
active pane and they pass no `-t`; a script that splits a pane it is not
sitting in must resolve the path itself first.

## `default-command`: three things, each of which cost a day

1. **Resolve `nu` on PATH, never by absolute path.** WezTerm's `default_prog`
   could hardcode `/opt/homebrew/bin` because it only ever spawned on this
   machine. This file is meant to be the same file over ssh, where nu is under
   `~/.cargo/bin`, `/usr/local/bin`, or nowhere.
2. **Fall back to something that works.** A `default-command` that fails does
   not warn — the pane opens and closes again — so a host without nu must land
   in `$SHELL` rather than in nothing.
3. **Export `XDG_CONFIG_HOME` before the exec.** `$nu.default-config-dir` is a
   **launch-time constant**; `env.nu` assigning it runs too late to move it.
   Measured on nushell 0.114.1: with `--config`/`--env-config` but no export,
   `$nu.default-config-dir` is `~/Library/Application Support/nushell` and
   reedline really does write `history.sqlite3` there, outside the managed
   tree. WezTerm did this in `set_environment_variables`; under tmux the pane
   is spawned by the tmux *server*, whose environment came from whichever
   client started it, so the export has to happen here or nowhere.

`default-command` runs through `/bin/sh -c`, so it is POSIX sh, not nushell.
`exec` in both arms keeps the pane's process the shell itself, which is what
makes `#{pane_current_command}` read `nu` — the value the status bar tints
occupied windows from.

## Key tables

### A pushed table falls back to `root`, then drops

This is the property the whole design rests on and it is not documented
anywhere obvious. A key with no binding in the pushed table is looked up **a
second time** in `root`. If root does not bind it either, it is **dropped** —
it does not reach the program in the pane.

So a mistyped letter cancels the mode and types nothing. WezTerm needed all 26
letters bound to a no-op to get this; on tmux those binds would be dead code.

The same second lookup is why the double-tap needs an explicit binding. Without
`bind -T jump F5 send-keys F5`, the second `F5` misses in `jump`, hits
`bind -n F5` in `root`, and silently **re-arms** the table instead of
forwarding anything.

No timeout is needed or possible. WezTerm's jump mode carried a 5 s timeout
because its key table persisted; a tmux table is popped by the very next
keystroke whatever it is, so the mode is only ever as deep as the number of
bindings that deliberately push it again.

### Re-arming is the only thing that keeps the switcher alive

A binding that does **not** end with a `switch-client -T` therefore *ends* the
mode. That is the whole of the gesture rule and it needed no extra machinery:
a letter, a Shift+arrow split and `q` re-arm nothing and are complete on their
own, so `F5 b` is two keystrokes and you are typing again.

A plain arrow (walk to the neighbour) ends in `switch-client -T jump`, because
walking is repeated: `F5 Right Right` is one trip. A Ctrl+arrow (swap with the
neighbour) pushes a third table, `pane-move`, where every arrow swaps again and
only `Enter` or `Escape` pops back to `root`. The swap takes `-d`, since without it focus stays on the slot and lands
on the neighbour that just moved in.

The digit re-arms conditionally, and it decides **after** the jump rather than
before it:

```
bind -T jump 1 if -F '#{m:*|1|*,#{W:|#{window_index}|}}' 'select-window -t :1' 'new-window -t :1 -c ~' \
             \; if -F '#{==:#{window_panes},1}' 'switch-client -T root' 'switch-client -T jump-pane'
```

Commands in a `\;` sequence resolve their target when they run, not when the
key was pressed, so `#{window_panes}` in the second `if` reads the window
`select-window` just moved to. One pane and the gesture is finished; more than
one and the pane letter is still to come, so it pushes `jump-pane`.

`jump-pane` is a second table holding the nine letters and `Escape` and
**nothing else**. In particular it does not hold `q`. `F5 q` kills the active
pane with no confirmation and tmux keeps nothing to restore it from, so the
guard is the table the key lives in: `F5` is a deliberate press and a `q`
straight after it is deliberate too, while a `q` in the state a digit leaves
you in is the first letter of a word you were about to type into the window you
just landed on. The nine letter binds are written out twice for the same
reason — tmux cannot forward a key from one table to another, and the
duplication is cheaper than the hazard.

Measured 2026-09-01 by attaching the session from a pane of a second tmux
server and reading `#{client_key_table}` after each key: `F5`→`jump`,
digit onto a one-pane window→`root`, digit onto a two-pane window→`jump-pane`,
letter→`root`, arrow→`root` (then a split; walking re-arms since), `q`→`root` with the pane gone. `F5` then `z` put
no byte on the pane's pty, which is the drop above, measured rather than read.

### The delimiter must not be a glob metacharacter

The window-existence test loops the window list and matches the index inside
delimiters:

```
#{W:|#{window_index}|}   →  |1||4||7|
```

`#{m:}` is **fnmatch**, and `[` opens a character class. So the natural
`#{m:*[1]*,#{W:[#{window_index}]}}` answers **true for window 11** when asked
about window 1, and the binding then selects a window that does not exist.
Measured. `|` is inert to fnmatch.

The same trap governs the status bar's occupancy test, where the pane's command
becomes the pattern and the shell list is the string: the bracket form answers
true for `nushell` when asked about `nu`.

`if-shell -F` tests a *format*, so no `/bin/sh` is spawned per keypress.

### Pane borders

`pane-border-lines single` uses tmux's default straight separators.
`pane-border-status top` shows a label above every pane, including a window
with only one pane. Stock tmux 3.7c rejects `rounded` for pane borders;
rounded corners are available for popups only.

### Pane letters are only honest with the border

tmux **renumbers panes** when one is killed, so a letter does not keep its pane
for life. `pane-border-format` derives the uppercase letter from the same
index the jump key uses: `#{a:N}` converts a character code and
`#{e|+|:64,#{pane_index}}` makes pane 1 read `A`, pane 9 `I`.
The bindings remain lowercase: `F5 a` selects pane A.

The label is plain text on the border line, like a popup's title:
`A  ~/dev main* ↑2  3 hours ago`. It uses the same local-host OSC 7 check as
the status bar, falling back to `pane_current_path` and shortening the home
directory to `~`. Nushell does not update its process cwd, so OSC 7 is needed
to follow `cd`. There are no fills and no reverse video: focus is the border's
own colour (`pane-active-border-style`, the scheme's accent `base0D`; inactive
borders are `base03`), so a header repaint only rewrites text. Tinty sets both
border colours, so a palette switch updates them together.

Both `window-style` and `window-active-style` are `default`: pane contents
retain the terminal and application colours regardless of focus. Only the
title indicates an inactive pane; the content is never dimmed by tmux.

### `F6` is never forwarded

`F6` gets no table and no `send-keys` anywhere, deliberately: the palette
belongs to the **outermost** terminal, because that is the process that owns
the ANSI colours and reads the OSC. An `F6` forwarded into a nested session
could only retint a session that does not own them.

It is bound in the multiplexer rather than the shell because a full-screen TUI
would swallow a shell-level binding. `-b` so the tmux server is not blocked for
the length of a `tinty apply`.

`sh -lc` is a **login** shell on purpose: `/etc/profile` runs `path_helper`,
which reads `/etc/paths.d/homebrew` and puts Homebrew's bin on PATH by itself,
so this file names no Homebrew path. Measured 2026-08-23:

```sh
env -i HOME=$HOME PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  /bin/sh -lc 'command -v nu; command -v tinty'
```

answers `/opt/homebrew/bin/nu`, and `tinty: NOT FOUND`. Note what
`/etc/paths.d/homebrew` names: `bin` only, never `sbin`. The two prepended
directories are the ones no login shell adds — tinty lives in `~/.local/bin` —
and both are `$HOME`-relative, so they are inert where they do not exist. Do
**not** drop the prefix on the grounds that `nu` resolves without it: the
toggle would then fail one layer deeper, on `tinty`, where the cause is far
harder to see than a missing shell.

## Copy mode

**07-multiplexer I1 governs this whole section**: every gesture here works on a
bare server with no WezTerm. Copying is the multiplexer's on purpose — that is
what makes it the same over ssh — and pasting is the terminal's by
construction, because only the program in front of the human can read that
human's clipboard. The one binding that broke the invariant is recorded below
rather than deleted quietly.

### `F4`, and the chord it replaced

**07-multiplexer I1**: every gesture in this layer works on a bare server with
no WezTerm. `Ctrl+Shift+X` did not, and it was the only keyboard entry to copy
mode from the tmux cutover until 2026-09-01.

A terminal cannot express `Ctrl+Shift+X` in the legacy encoding — both `Ctrl+X`
and `Ctrl+Shift+X` are the single byte `0x18`. It only arrives as something
distinguishable when the terminal speaks an extended-key protocol.

The measurement that made this look safe was about the wrong half. tmux 3.7c
**decodes both spellings** — `CSI 120;6u` (kitty/CSI-u) and `CSI 27;6;120~`
(xterm modifyOtherKeys) — into `C-S-x`, and does so with `extended-keys` off,
on and always alike, because that option governs what tmux **sends**, never
what it accepts. All true, and none of it load-bearing: the terminal still has
to *send* one of the two spellings, and that is a fact about the emulator, not
about tmux. Measured 2026-09-01 on this desk — WezTerm advertising `extkeys` in
`#{client_termfeatures}`, `extended-keys on`, `enable_kitty_keyboard = false` —
pressing the key did nothing at all. tmux received an unbound `C-x` in root and
passed it to the program in the pane.

So the binding is gone rather than kept as a second name for `F4`. Keeping it
would leave the manual documenting a key that works on some terminals and
silently does nothing on others, which is the exact failure I1 exists to catch:
correct on paper, silent in practice, invisible to anyone not sitting at the
one terminal it was tried on.

`F4` asks the terminal for nothing. It joins `F3` (search), `F5` (jump) and
`F6` (theme) in the row this config reserves for keys no program in a pane
wants, and carries the same nesting escape they do —
`bind -T jump F4 send-keys F4`, because a root binding is always taken by the
outermost server.

`C-b [` remains the entry that works on every terminal ever, and `copymode` is
the same mode from a shell prompt.

**The fact worth keeping from the old section**, because it is why binding a
chord was tempting: binding `C-S-x` costs plain `C-x` nothing. Measured, with
only `C-S-x` bound a plain `Ctrl+X` still reaches the pane as `0x18`, so
nvim's `i_CTRL-X` completion prefix and every readline binding were untouched.
Binding `C-x` instead — the byte that actually arrives — would have taken them
all. That is the trap for anyone who reads "it arrives as 0x18" and reaches for
the obvious fix.

### The cycle's anchor, and why it is an option

`select-word` leaves the cursor at the **end** of the word and `select-line` at
the end of the line, so a naive cycle wrapping back to cell anchors on wherever
the last selection *ended*. On `alpha beta gamma delta` with the cursor on
`beta`, cell/word/line read `b` / `beta` / the whole line, and the next `c`
without a restore reads `delta`.

`set-mark` on the first press records the anchor; `jump-to-mark` then `set-mark`
on the wrap restores it and puts the mark back — `jump-to-mark` **swaps** cursor
and mark, it does not copy.

The position is tracked in an option rather than by reading the selection back,
because a one-cell selection reads `#{selection_present}` 0 while
`#{selection_active}` is 1, so a state machine driven off the selection desyncs
on its own first step.

`jump-to-mark` with no mark set does not stay put — it moves the cursor to line
2 column 0. The cycle only ever jumps in its `line` state, which is reachable
only after the state that sets the mark. The `after-copy-mode` hook clears the
toggle on **every** entry, because copy mode is also entered by the mouse wheel
and by `copy-mode` typed as a command.

### `set-option` before a copy command silently kills the OSC 52

**The order is load-bearing and the failure is silent.** A `set-option`
anywhere in a key binding *before* a copy command suppresses the OSC 52 that
`set-clipboard on` would otherwise emit. The paste buffer is still set,
`show-buffer` reads the right text, and nothing is logged — so on a remote host
the copy looks like it worked and the clipboard never moves.

Three shapes, one fixture:

```
{ set -pu @o ; send -X copy-selection-and-cancel }    buffer set, NO OSC 52
{ set -p @o x ; send -X copy-selection-and-cancel }   buffer set, NO OSC 52
{ send -X copy-selection-and-cancel ; set -pu @o }    buffer set, OSC 52 out
```

The reset in the `y`, `Enter` and `C-c` bindings is redundant —
`after-copy-mode` clears the toggle on the next entry — and it is kept anyway,
so a reader who moves it back to the top finds something here saying why it must
not be moved.

### Choosing the sink is not the same as using it

**The bug this section exists to prevent shipped for weeks.** Picking a sink
sets an option; it rebinds nothing. Every stock copy path calls
`copy-pipe-and-cancel` with **no command**:

```
copy-mode-vi Enter              send -X copy-pipe-and-cancel
copy-mode-vi MouseDragEnd1Pane  send -X copy-pipe-and-cancel
root DoubleClick1Pane           ... send -X copy-pipe-and-cancel
root TripleClick1Pane           ... send -X copy-pipe-and-cancel
```

With no command the text goes to tmux's own paste buffer and stops. Under
`set-clipboard off` — the local arm, the one this desk runs — the buffer is the
end of the line. Only `y` named `pbcopy`, so only `y` copied. Everything else
highlighted, cancelled, and left the system clipboard holding whatever it had
before: the exact shape of "I selected it and pressed the key and it did not
paste".

Measured 2026-09-01, on a session whose pane held `SENTINEL-ZZZ-9876` and whose
clipboard held `BEFORE-15647`:

```
send -X copy-pipe-and-cancel          buffer SENTINEL-ZZZ-9876, pbpaste BEFORE-15647
send -FX copy-pipe-and-cancel "#{@copy-pipe}"   pbpaste SENTINEL-ZZZ-9876
```

So the sink is an option every copy path names, and `-F` is load-bearing:
`send -X` does **not** expand formats in its arguments and would pipe to the
literal string `#{@copy-pipe}`. `-FX` is the same spelling tmux's own default
`#` binding uses for `#{copy_cursor_word}`.

The remote arm keeps the empty pipe on purpose: `copy-pipe-and-cancel ""` still
sets the buffer, and `set-clipboard on` is what turns that into the OSC 52.
One binding, both arms, the difference held entirely in `@copy-pipe`.

### Taking the mouse means owing it a clipboard

`mouse on` moves selection from the terminal to tmux, and it has to — a
terminal-level drag across a vertical split runs through the divider and takes
both panes' columns as one line. That is also what makes the gesture portable:
the selection is the multiplexer's, so it behaves the same over ssh as it does
locally, where a terminal-owned selection would be whatever the far end's
emulator happens to do.

Having taken the mouse, tmux owes it a clipboard, and `Ctrl+C` is bound in
`copy-mode-vi` because stock binds it to a bare `cancel` — the obvious gesture
threw the selection away. There are two routes to that binding and I1 requires
both to work:

- **No emulator binding in the way** (any terminal over ssh): `0x03` arrives at
  tmux directly. Unlike the retired `C-S-x`, `Ctrl+C` is perfectly spellable in
  the legacy encoding, so this route needs nothing negotiated.
- **An emulator that binds it first** (WezTerm here): its callback reads its
  own selection, finds none — `window:get_selection_text_for_pane` is **always
  empty under tmux**, since the drag never reached it — and falls through to
  sending the key down. It arrives at the same line.

The second route only stays correct while the emulator's binding falls through
on an empty selection. One that copied unconditionally, or swallowed the key,
would break copy-mode `Ctrl+C` on this desk and nowhere else — the asymmetry
worth knowing about before editing `wezterm.lua`.

`#{selection_present}` is the test that makes one key do both jobs. Note it
reads 0 for a one-cell selection while `#{selection_active}` reads 1 — the same
asymmetry the cycle's anchor section relies on — so `Ctrl+C` on a single
character leaves rather than copies. That is the acceptable end of the trade:
the alternative is a key that can never simply leave.

The manual entry for `Ctrl+C` asserted the opposite of all this until
2026-09-01 — "the multiplexer's mouse mode is off, so dragging still selects
the way it does in any other window". The mouse mode was on. The entry was
written before the tmux cutover and never re-read against the file.

### The sink is chosen by where the panes are

`pbcopy` writes the clipboard of the machine the **tmux server** runs on, which
is the machine the panes are on. That is the right clipboard when the server is
this desk and the wrong one — or no one at all — when you have ssh'd somewhere
and started tmux there. OSC 52 is the opposite: it travels out through the
client's terminal, so it reaches the clipboard of the machine you are *sitting*
at.

The two arms are **exclusive**, and that is what `set-clipboard off` buys on the
local arm: `copy-pipe-and-cancel pbcopy` under `set-clipboard on` puts the text
on the clipboard **and** emits an OSC 52 for the same text, so "picks its sink"
would have been two sinks.

`off` costs nothing here: an OSC 52 written by an *application* inside a pane
(remote nvim's osc52 provider on the far end of an ssh) is forwarded to the
outer terminal under `off`, `external` and `on` alike. **The manual is wrong
about that on this version** — do not restore `on` locally on the strength of
the man page without re-measuring.

The case this gets wrong, named rather than hidden: a tmux server on *this*
machine attached from somewhere else over ssh copies to this desk's clipboard,
not to the one in front of you. Copying out is the direction this environment is
built for; copying in was not bought.

### Both arms measured, on a host that is not this desk

I1 asks for the gestures to work on a bare server, so the remote arm was driven
rather than reasoned about. Fixture, 2026-09-01: a tmux server started with
`PATH` holding neither `pbcopy` nor `infocmp` nor `nu`, and a client attached
on a real pty whose bytes were read back.

```
sink        @copy-pipe ''  |  set-clipboard on  |  default-terminal screen-256color
termfeature bpaste,ccolour,clipboard,hyperlinks,cstyle,extkeys,focus,RGB,title
press y     OSC 52 out: 1
  raw       ;L2V0Yy96c2hyYzo4OiBjb21tYW5kIG5vdCBmb3VuZDogbG9jYWxlCg==
  decoded   /etc/zshrc:8: command not found: locale
```

Four things fell out of one run. The `infocmp` probe took the
`screen-256color` fallback. The `pbcopy` probe took the OSC 52 arm. The real
`y` binding — `send -FX copy-pipe-and-cancel "#{@copy-pipe}"` with the pipe
empty — set the buffer *and* put the base64 on the client's wire, so an empty
pipe does not suppress the OSC 52 the way a `set-option` before the copy does.
And the pane came up in **zsh**, because `nu` was not on `PATH` and
`default-command`'s `${SHELL:-/bin/sh}` fallback is real rather than
theoretical.

The decoded payload is a zsh startup error rather than anything interesting,
which is the point: it is whatever was on the top line of a deliberately
crippled host, copied by the ordinary key, read off the wire.

The local arm is the same key measured the other way: with `pbcopy` on `PATH`,
`pbpaste` returns the selection and no OSC 52 goes out. Two arms, one binding,
the difference held entirely in `@copy-pipe`.

### `mode-keys vi` is stated, not inherited

tmux picks `mode-keys` from `$EDITOR`/`$VISUAL` when it is not set, so on a host
where `EDITOR` is unset or emacs-shaped the whole copy cycle would sit on top of
a table whose motions are emacs bindings.

## The status bar

Colours are **ANSI slots, not hex**. `colour0` is base00 and `colour7` is base05
after tinted-shell's OSC 4, so they follow a `tinty apply` for free on any
terminal that honours it. The one value with no ANSI slot is base02 (the active
label's background); `colour8`/base03 stands in until `colors.conf` sets the
exact style.

The digit's **background** says which window has focus and its **foreground**
says what Claude is doing in it — "The digit wears Claude's state", below — so
the two signals never compete for one channel.

The active label's colours live in a style *option*, not inline in the format,
because a later `source-file` can replace a style option and cannot replace a
format's embedded `#[…]`.

The bar is **one row at the top** and holds only what is true of the whole
session. Left to right: the clock; **`tmux-sys`** — CPU and memory as a
five-cell bar plus percent, and the default interface's download/upload in
Mbit/s since the previous tick, every field fixed width so the chip and digits
never shift; the **key-table chip**, which appears the
instant `F5` arms the switcher and names the table (`jump`, or `jump-pane` when
a digit has been pressed and the letter is still to come); and at the right the
window digits.

Everything about a pane lives in **that pane's header** — plain text on its
top border: the jump letter, the host (over ssh), the cwd, the **git segment**
(branch, `*` when dirty, `↑n`/`↓n` against the upstream, last-commit age), and
a zoom or copy-mode flag.

The **git segment** is the one thing here that runs a command. It was left out
of the first cut on the grounds that starship prints the same facts in the
prompt one line below — which was wrong, and the counter-case is the common
one: the prompt is only on screen while a pane sits *at* a prompt. Open nvim,
tail a log, hand the pane to Claude, and the branch disappears from the screen
entirely. The bar is the surface that is always there. `~/.local/bin/tmux-git`
carries the reasons for how it asks git; the two that matter are `-uno` (a walk
of tracked entries rather than the whole tree, because this runs on a timer)
and `--no-optional-locks` (without it a polling `git status` contends for
`.git/index.lock` with the git you are running in the pane, and the failure
looks like random "unable to write index" errors that nothing points back at
the bar). `#()` runs in the background and re-runs every `status-interval`, so
a slow answer arrives late rather than freezing a redraw.

The **key-table chip** is the awesome-tmux prefix-highlight idea rebuilt on the
tables this config actually uses, there being no prefix key here to highlight —
until it existed, nothing on screen said the switcher was armed. **Trap for
anyone re-measuring it:** a real keypress redraws the status, so the chip
appears and clears instantly, but driving the same change from the CLI with
`switch-client -T jump` does *not* mark the status dirty and the chip does not
appear until the next tick. That reads exactly like a broken format and is not
one.

A second status row was dropped for the pane headers. Rows sit wherever
`status-position` says, because it is **one option for the whole bar**. Measured 2026-09-01 on **tmux 3.7c**: `status 2` with
`status-position top` drew both at screen rows 1 and 2, so tabs at the top with
the window status at the bottom is not available. Neither is an overlay at the
bottom — tmux's only overlay is a popup: it is per client, it covers pane
content rather than reserving a row, and it takes every key while it is up
(`-N` only cancels `-E`/`-k`, it does not make a popup passive).

The window list is right-aligned; the bar's left segment leads with the clock.
The clock takes the outermost cell because it is the one segment whose width
never changes, so it is the only one that can anchor a corner — a cwd in front
of it would move the time to a different column on every `cd`, which is exactly
what makes a clock hard to read at a glance. Everything that moves with a `cd`
is in the pane headers for that reason, and the host sits next to the path there
because over ssh the two are one fact.

The list is placed by **`status-justify`**, never by a format, and `right` only
reaches the terminal's right edge while `status-right` is **empty**: tmux
right-aligns the list within whatever space the two flanking segments leave, so
anything put back in `status-right` pushes the digits inward by its own width.
The two segments are written into both arms of the SSH test below rather than
composed, because tmux options do not concatenate — there is no "append to
`status-left`", and routing the hostname through a user option would nest a
format inside a format.

`status-interval` is 5 s. The clock is `HH:MM`, so a faster tick would repaint
the bar sixty times for one visible change.

"Local" cannot be read from the format language — tmux does not know where the
client is — so the hostname segment is decided once at parse time from the
**server's** environment: a tmux started over ssh inherits `SSH_CONNECTION`, one
started from a terminal on this desk does not.

`#{s|^$HOME|~|:pane_current_path}` is a format substitution, not a shell — no
process per tick. `$HOME` is expanded by tmux at parse time, so the pattern is a
literal path by the time a tick reads it.

That expansion happens in **double quotes only**. Written inside single quotes
the `$HOME` reaches the format literally, nothing matches, and the row prints
the full `/Users/...` path with no error to say why — measured 2026-09-01 while
building the cwd segment. It is why both arms of the SSH test are double-quoted.

Every pane keeps its top border label visible. The config removes the former
`window-layout-changed` hook so splitting or closing a pane cannot hide it.

## The digit wears Claude's state

The window digit's foreground is what Claude is doing in that window: **colour4
working**, **colour2 finished**, **colour3 waiting for you**, unlit when no
Claude there has reported. `waiting` beats `working` in a window running two,
because it is the one state that is asking for a human.

The report comes from Claude Code itself, through hooks. `UserPromptSubmit` and
`Stop` bracket a turn. `Notification` is the only event that fires while nothing
is running, and since `cc` passes `--dangerously-skip-permissions` there is no
permission prompt left to raise it, so here it means the **idle nudge** — a
finished turn nobody has come back to. `SessionStart` and `SessionEnd` both
clear, because the pane outlives the Claude in it and a green digit over a bare
shell is worse than no colour at all.

Nothing sniffs the panes, and the alternative is worth naming: a Claude pane
cannot be recognised by its command, because Claude Code runs as its own version
string and `#{pane_current_command}` on one reads `2.1.258` — measured
2026-09-02 — so a matcher would print a version number where a name belongs and
break at the next release.

The state is a **pane** option, `@claude`, set by `~/.local/bin/tmux-claude-state`
from `$TMUX_PANE`, which a hook inherits from the Claude that spawned it. Pane
and not window: one window holds a Claude beside a shell often enough, and a
pane option **dies with its pane**, so a Claude that is killed rather than
exited leaves nothing behind — a window option would outlive it and strand the
digit in a colour with no process left to clear it. Measured 2026-09-02: killing
a `waiting` pane dropped its window straight back to the `working` of the pane
beside it, with nothing to clean up.

The digit gathers them at draw time with `#{P:…}`, so nothing is stored per
window and no count can go stale. **Trap:** `#{P:…}` and `#{W:…}` each take two
comma-separated arguments (`#{P:other,current}`), so a top-level comma inside one
splits it rather than printing; every comma in `@claude-tint` is nested inside a
`#{?…}` and safe. **Trap:** `#{E:…}` is what expands a user option holding a
format, and a `#[fg=…]` arriving from one *is* honoured by the bar — measured
2026-09-02 on 3.7c by drawing the bar in a nested server and reading the escapes
back out of the pane it drew into.

Every hook ends in `refresh-client -S`. Without it the colour waits for
`status-interval`, and a turn that finishes in under five seconds goes green
after it has already finished — which reads as a broken hook rather than a slow
one.

The hooks live in `~/.claude/settings.json`, which chezmoi does not manage:
`run_after_install-claude-hooks.sh` merges the block in and replaces only the
entries naming `tmux-claude-state`, the same way `register-mcp` shells out
rather than writing `~/.claude.json` itself. **Trap:** every profile, not just
the root file. `cc` runs Claude under `CLAUDE_CONFIG_DIR=~/.claude/<profile>`,
and `_claude_share` *copies* settings.json into a profile at creation rather
than symlinking it — so a block written only to the root reaches no session that
`cc` ever starts, which is exactly how the first cut of this shipped and did
nothing.

## Palette delivery

`~/.config/tmux/colors.conf` holds **style options only**, never formats, so a
scheme change can never move a segment of the bar. It is sourced **last**, so it
overrides the ANSI-slot defaults; a checkout that has never applied a theme has
no such file and keeps them.

**`-q` is the existence test.** The natural spelling —

```
if-shell '[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/colors.conf" ]' …
```

— does not survive: tmux performs its own `${…}` expansion on the string and has
**no `:-` default form**, so it rejects the line with "invalid environment
variable" at load. `-q` suppresses the missing-file error, which is the whole of
what the `if-shell` was for, and costs no shell.

Both spellings of the config root are sourced because tmux itself looks in both
for this file, and the hook writes to `$XDG_CONFIG_HOME`. Sourcing the same
options twice is a no-op; sourcing neither would leave a themed machine on the
fallback slots.

## Persistence

**No tpm.** tpm exists to install and update plugins and to give a config a
place to declare them; `install.sh` clones them and two `run-shell` lines
declare them, so tpm would be a third mechanism doing a finished job.

**The guard and the run are one shell command, and that shape is forced.** The
natural spelling —

```
if-shell '[ -f "…/resurrect.tmux" ]' 'run-shell "…/resurrect.tmux"'
```

— **loads silently and runs nothing**. `run-shell`'s argument is a tmux command
string, so tmux performs its own `${…}` expansion on it first and has no `:-`
default form; the expansion fails, `if-shell` swallows the error, and the plugin
never starts with no message anywhere. Inside `run-shell '<sh>'` the whole
string is handed to `/bin/sh` and `${XDG_DATA_HOME:-$HOME/.local/share}` is the
*shell's* expansion, which works.

**What the `-x` guard is honestly worth:** without it, `run-shell` on a missing
file produces **no error anywhere** — not on stderr at load, not in
`show-messages`. So the guard does not save you from a broken config; it saves
you from spawning a shell that fails silently. A machine where `install.sh` has
not run gets a fully working tmux either way, minus persistence. That is the
honest degradation, and it is why nothing here aborts.

**Continuum goes last**, and that is a documented requirement of the plugin: its
init reads the `@continuum-*` options and schedules the save loop, so anything
set after it is not seen by the loop it started. `-b` is **not** used — a
plugin's init has to have run before the options it reads are used.

Saved state lives under `$XDG_STATE_HOME`, not `$XDG_DATA_HOME`: a session
snapshot is state a machine can lose without losing anything you chose.

`@resurrect-strategy-nvim 'session'` is **not** used. That strategy restores
with `nvim -S` only when a literal `Session.vim` sits in the pane's cwd — which
would mean writing an untracked file into every working tree the editor was ever
opened in. The **inline** strategy takes a custom restore command instead, split
on the `->` token, so persistence.nvim's session file stays in the state
directory where it belongs.

Pane **contents** are not saved. What comes back is the shape of the work —
where each pane was and what it was running — not a screenshot of its
scrollback, which would put the output of every command on disk in plaintext and
grow without bound.

## Claude Code in a pane

Two lines, both required for `Shift+Enter` to insert a newline instead of
submitting.

The repo pairs WezTerm's `enable_kitty_keyboard = false` with nushell's
`use_kitty_protocol = false` so reedline never fires the kitty support query
whose reply the WezTerm pty returns too late. Adding `extended-keys on` does
**not** disturb that pairing, because the option governs what tmux *sends* to
pane programs only at each program's own request, and nushell never asks:

- A pane program that asked for nothing receives **byte-for-byte the same
  input** with `extended-keys` off and on. Measured: plain Enter, `Ctrl+X` and
  arrow-up arrived as `\r`, `030`, `ESC[A` in both settings, across all eight
  request/feature combinations probed.
- Modified keys reach a pane only in extended form **after that pane enables
  modifyOtherKeys itself** (`CSI >4;1m`). `Shift+Enter` then arrives as
  `CSI 13;2u`, `Ctrl+X` stays the bare byte `018`, arrow-up stays `CSI A`.
- The kitty protocol tmux does not track per pane at all: a pane pushing
  `CSI >1u` still got plain `\r` for `Shift+Enter`. There is no path by which
  this line could re-arm the kitty behaviour that was turned off.

With `extended-keys` off, tmux folds **both** `Shift+Enter` spellings into the
bare `\r` of plain Enter, and Claude Code cannot tell a newline from a submit
even though the outer terminal encoded them differently.

`extended-keys-format csi-u` picks which of the two spellings tmux sends to a
requesting pane: `CSI 13;2u` rather than the `CSI 27;2;13~` of xterm's
modifyOtherKeys, which is the tmux default. pi refuses to run on the xterm
spelling and asks for this by name; Claude Code reads either. The option
governs the outbound wire only — tmux 3.7c decodes both spellings on the way
in regardless, so nothing about what the emulator may send changes.

`xterm*:extkeys` names the client terminal as extended-key capable. Measured:
with `extended-keys on`, tmux emits `CSI >4;2m` on the client wire at attach
with the feature line present **and** absent alike — on 3.7c the feature line is
belt and braces, carried because the docs require it and because an older tmux
gates the request on a matching `extkeys` feature.

## `bounded` — every wait has a deadline

`~/.local/bin/bounded SECS CMD…` runs CMD in its own process group and, at the deadline or when `bounded` itself is killed, sends TERM to the whole group and KILL to anything still there two seconds later. Exit status is CMD's, or 124 on the deadline. macOS has no `timeout(1)`, and a timeout that only stops waiting leaves the process running: on 2026-09-23 seventeen orphaned `pass show` reads were found spinning at 50% CPU each, which made every exec on the machine cost 70–250 ms.

Every detached or possibly-blocking call in this repo goes through it: the Keychain and git-credential reads in env.nu (interactive shells only) and capsule.nu. install.sh's downloads carry `curl --max-time`. The `.orly/specs/lifecycle/` checks hold all of this: no process may outlive an action.
