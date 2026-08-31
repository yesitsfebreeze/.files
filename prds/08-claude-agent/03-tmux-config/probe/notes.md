# probe notes — 08-claude-agent/03-tmux-config

Host: macOS 25.2 (Darwin 25.2.0, arm64), tmux 3.7c (/opt/homebrew/bin/tmux),
claude 2.1.251 (/Users/feb/.local/bin/claude). Everything below was
MEASURED on this host. Scripts are beside this file; fixtures are built at
run time under mktemp, never under the board.

## E1 — what tmux SENDS a pane, by request and by option

`probe/01-what-the-pane-gets.sh`, the nested pty fixture (F14/F15 shape:
outer pane runs the inner client, `send-keys -H` puts raw bytes on the
inner client's stdin — what a terminal emulator does). The inner collector
optionally enables an extended-key protocol on its tty first, then logs
every byte it receives, raw (`stty raw -echo; dd bs=1` — see E5).
Inputs: Shift+Enter in both spellings (`CSI 27;2;13~`, `CSI 13;2u`),
plain Enter, Ctrl+X, arrow-up.

| extended-keys | extkeys feature | pane request | pane received |
|---|---|---|---|
| off | 0/1 | none / mok / kitty | `\r \r \r 030 ESC[A` |
| on | 0/1 | none / kitty | `\r \r \r 030 ESC[A` |
| on | 0/1 | mok (`CSI >4;1m`) | `\r ESC[27;2;13~ ESC[27;2;13~ 030 ESC[A` |

Three findings in one matrix:

- **The pairing is undisturbed.** A pane that requested nothing — reedline,
  with `use_kitty_protocol: false` — receives byte-identical input with
  extended-keys off and on. All eight no-request/kitty rows are identical.
- **With the option OFF, both Shift+Enter spellings fold to bare `\r`.**
  Extended keys are the one thing the docs' first line buys.
- **The pane path is modifyOtherKeys-only.** A pane that enables
  modifyOtherKeys gets Shift+Enter WHOLE (translated to the xterm format,
  `CSI 27;2;13~`, both input spellings alike) and the unbound keys STAY
  legacy in the same stream — arrow-up `CSI A`, Ctrl+X bare 018. Extended
  keys for the keys that have no well-known encoding, untouched bytes
  beside them. The tmux man page says the same in prose (`on` = the pane
  program can request mode 1 or 2; `always` would force it).

## E2 — the extkeys feature line is belt and braces on 3.7c

`probe/02-what-the-client-gets.sh`, wire capture by `pipe-pane -O` on the
outer pane carrying the inner client (the C8 technique): with extended-keys
on, tmux emits `CSI >4;2m` on the CLIENT wire at attach — with the feature
line present and absent alike, on an xterm-shaped client TERM and on
screen-256color alike. With extended-keys off, no enable goes out. So on
3.7c `xterm*:extkeys` is not what gates the request — `extended-keys on`
is — and the line is carried because the docs require it and because an
older tmux gates the request on a matching extkeys feature. No kitty
protocol query (`CSI ?u`) went out in any arm.

This also bounds what the client-side enable can disturb: the enable
sequence goes to the OUTER terminal (WezTerm), never into a pane. Nushell
sits behind tmux and reads whatever tmux's pane encoding produces, which
E1 measured unchanged.

## E3 — the shipped conf with the section appended

`probe/03-real-conf.sh`: the real `home/dot_config/tmux/tmux.conf` with the
analyst's section appended loads stderr-clean into an isolated server;
`extended-keys on` reads back; `xterm*:extkeys` joins the feature list as
entry [4]; the pre-existing assertions (default-terminal, escape-time,
focus-events, allow-passthrough, base-index, renumber-windows) all still
read as 01-session-and-windows shipped them; the CSI-u decode of `C-S-x`
(05-copy-and-clipboard C2) still works against an extended-keys-on server,
unconditionally, as measured there.

## E4 — does Claude Code ask?

`strings` of the claude 2.1.251 binary: it carries the modifyOtherKeys
mode-2 enable bytes (`CSI >4;2m`) and a kitty reply parser (`CSI ?u` ->
`kittyKeyboard`, flags int) — it DECODES both reply forms, and E1 measured
the mode-1 request (`CSI >4;1m`) is what turns tmux's sending on. Its
default keybinding map binds `chat:submit` to `enter` and — confirmed in
the binary's keybinding table — `chat:newline` to `ctrl+j`, with the
input layer treating `return`+shift (or meta) as a newline: exactly the
distinction a tmux that folds Shift+Enter to `\r` destroys, and the reason
Ctrl+J keeps working without any of this (it arrives as the bare byte 0x0A,
never extended). `CLAUDE_CODE_ALTGR_AS_TEXT` exists as an env override on
the same decode path (quirk `off|force|auto`, WezTerm-session aware), noted
for 04-help-entries; not exercised here.

## E5 — two traps the fixture hit, both of which made a first pass lie

- **A plain `cat > file` collector lies.** The pane pty's line discipline
  folds CR to NL (ICRNL) and canonical mode holds every byte after the last
  newline — a server kill then discards the buffer. First pass read three
  bogus `\n` for five keys. The collector must `stty raw -echo` and `dd
  bs=1` (cat's stdio buffer dies with the SIGKILL; dd writes per read).
- **`printf '%b'` in an UNQUOTED heredoc becomes `printf '%%b'`** — the
  heredoc consumed what was meant for the collector's own format string,
  printing the literal `%b` and never emitting the enable bytes. The mok
  arm then looked like the no-request arm and the "mode 1 buys Shift+Enter"
  check read as a false-red. Quoted `<<'EOF'` heredoc, no shell expansion
  to second-guess. This is the same class as the gate's own rule 2: a
  substitution evaluated in the wrong context, silently.

## Out of scope, honestly not measured

- What WezTerm's GUI actually puts on the pty for Shift+Enter — needs a
  real window plus synthetic keystrokes, intrusive; carried from
  05-copy-and-clipboard C1. What IS measured here is the tmux half: with
  the docs' lines in, a pane that asks gets the distinction, one that does
  not gets exactly what it got before.
- Whether Claude Code's running session picks the lines up without a
  re-attach — the docs say `source-file` applies them to a running server;
  the gate proves the loaded server reads them, not a live agent's keys.