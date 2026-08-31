---
complexity: 14
footprint:
  - home/dot_config/tmux/tmux.conf
---

# spec01 — the key-table section: F4 split, F5 switch, F6 theme

Appends one section to `home/dot_config/tmux/tmux.conf`, below the base that
`01-session-and-windows` owns and whose header already names this node as an
appender. Nothing in that file is edited; nothing in `wezterm.lua` is touched
(that is `08-wezterm-reduction`'s cutover).

Three keys, all `-n` so they need no prefix. `F4` pushes a `split` table where
an arrow splits in that direction inheriting the active pane's cwd; `F5`
pushes a `jump` table where `1`-`9` select or lazily create a window and `a`-`i`
select pane index 1-9; `F6` is a bare root binding that runs the theme toggle.
Each pushed table also binds its own key to `send-keys`, which is Q10's
double-tap.

**The one thing that will look wrong to a reviewer and is not:** there are no
bare-cancel letter binds. WezTerm needed 26 of them because `until_unknown`
popped its table without eating the key, so an unbound letter typed itself
into nvim. Measured on tmux 3.7c (`probe/notes.md` K1, K2): a key with no
binding in a pushed table is looked up a **second time in `root`** and dropped
when that misses too — it never reaches the program. The reason
`02-terminal/03-f5-jump-mode` R2 gives holds exactly; the mechanism is free.
Re-adding the binds would be dead config, and spec02's key counts are what
keep them out.

**Two traps that cost a reading each during the probe:**

- The digit's existence test is `#{m:*|N|*,#{W:|#{window_index}|}}`. `#{m:}`
  is fnmatch and `[` opens a character class, so the natural `[`-delimited
  form answers "window 1 exists" when only window **11** does, and the binding
  then selects a window that is not there. `|` is inert to fnmatch.
- `-c ~` on the create arm is not decorative. A key-bound `new-window` with no
  `-c` resolves the **session's** working directory, so without it Q14 is true
  only for a session this repo's launcher created at `$HOME`.

## Acceptance

- [x] `home/dot_config/tmux/tmux.conf` loads with the new section, rc 0 and
      nothing on stderr, and the section is appended below the existing base
      with no line of that base changed — `PASS tables: the conf with the key
      section loads, rc 0` and `PASS tables: nothing on stderr ()`;
      `git diff -U0` on the file is **one** hunk, `@@ -152,0 +153,279 @@`,
      `279 insertions(+)` and zero `-` lines
- [x] `list-keys -T root` binds exactly three function keys: `F4` →
      `switch-client -T split`, `F5` → `switch-client -T jump`, and `F6` once
      — `PASS tables: root F4 pushes the split table (got 'switch-client -T
      split')`, `…root F5 pushes the jump table (got 'switch-client -T jump')`,
      `…root binds F6 exactly once (got 1)`, `…root binds exactly three
      function keys (got 3)`
- [x] `list-keys -T jump` holds exactly 19 keys — nine digits, nine letters,
      one forwarder — so no bare-cancel letter bind has crept back in —
      `PASS tables: the jump table holds exactly 19 keys — 9 digits, 9
      letters, 1 forwarder (got 19)`
- [x] each digit `N` in `jump` both selects window `N` and creates it at index
      `N` with `-c ~` when absent, and tests existence with the `|`-delimited
      window loop rather than a glob character class — 27 PASS lines, three per
      digit, e.g. `PASS tables: jump 4 selects window 4 (got 'if-shell -F
      "#{m:*|4|*,#{W:|#{window_index}|}}" "select-wind')`, `…jump 4 creates
      window 4 at ~ when absent (Q2 lazy, Q14 cwd)`, `…jump 4 tests existence
      with a |-delimited window loop, not a glob class`
- [x] `a`-`i` in `jump` are `select-pane -t :.1` through `select-pane -t :.9`
      — nine PASS lines, `PASS tables: jump a selects pane 1 (got 'select-pane
      -t :.1')` through `…jump i selects pane 9 (got 'select-pane -t :.9')`
- [x] `list-keys -T split` holds exactly 5 keys: four arrows each carrying
      `-c "#{pane_current_path}"`, with `-b` on Left and Up and not on Right
      and Down, plus the F4 forwarder — `PASS tables: the split table holds
      exactly 5 keys (got 5)`, four `…splits with -c "#{pane_current_path}"`
      lines (Left reads `split-window -bh -c "#{pane_current_path}"`, Right
      `split-window -h -c …`), plus `…split Left is the BEFORE half of a
      horizontal split (-b)`, `…split Up is the BEFORE half of a vertical
      split (-b)`, `…split Right carries no -b`, `…split Down carries no -b`
- [x] `bind -T jump F5 send-keys F5` and `bind -T split F4 send-keys F4` are
      present, and no table anywhere carries `send-keys F6` — `PASS tables:
      jump F5 forwards a literal F5 inward, Q10 (got 'send-keys F5')`,
      `…split F4 forwards a literal F4 inward, Q10 (got 'send-keys F4')`,
      `…no table anywhere forwards F6 (got 0 send-keys F6)`, and the jump and
      split tables each bind no F6 (got 0)
- [x] pressed through a nested tmux, `F5 <digit>` creates then selects, the
      created window's cwd is `$HOME` while an `F4 <arrow>` pane's cwd is the
      active pane's — the two rules disagree, measured in one run against a
      session whose path is neither — `PASS keys: F5 4 on a one-window session
      creates window 4 (list reads '1 4')`, `…F5 4 a second time SELECTS — no
      duplicate window (list reads '1 4')`, `…the created window's cwd is
      $HOME, not the session path <scratch>/keys/sess (got /Users/feb)` and
      `…F4 Right opens a pane in the ACTIVE PANE's cwd (got
      <scratch>/keys/pane)`, all in the one run whose precondition line reads
      `…session path, pane cwd and $HOME are three different directories`
- [x] pressed through a nested tmux, `F5 z`, `F5 h`, `F5 0`, `F5 q` and
      `F4 z` each return the client to `root`, move nothing, and put **not one
      byte** on the pane's pty — four `PASS keys: F5 <k> returns the client to
      the root table (got root)` lines, `…four mistypes moved nothing (pane 3
      → 3)`, and `…five mistypes put NOT ONE BYTE on the pane's pty (od reads
      '\n')` — the `\n` is the flushing Enter and nothing else
- [x] `F6` runs the toggle all the way into nushell and pushes no key table —
      `PASS keys: F6 runs the theme toggle all the way into nu (marker reads
      'TOGGLED')` and `…F6 pushes no table — it is an action, not a mode (got
      root)`

## Verify and Proof

Both stages read and press the conf named on the command line, so the command
says which file it proves. Run from the repo root.

```sh
TKT_CONF=home/dot_config/tmux/tmux.conf bash tests/tmux-key-tables.sh --tables
TKT_CONF=home/dot_config/tmux/tmux.conf bash tests/tmux-key-tables.sh --keys
```
