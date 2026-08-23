# spec02 — the `copymode` nushell command

R5's shell half: a nushell command that prints the OSC 1337 `SetUserVar`
named `copymode`, which spec01's handler turns into copy mode. One new
module file plus its `source` line — the module pattern `pass.nu` and
`claude.nu` already follow. There is no live source to port: the deployed
shell has no such command (measured 2026-08-22 — `copymode` appears
nowhere under `~/.config/nushell/`), only the handler side exists, so this
file is written fresh against R5's contract.

**Est:** 0.25h

**Footprint:** `home/dot_config/nushell/copymode.nu` (create),
`home/dot_config/nushell/config.nu` (one `source` line — shared file, held
by the live nushell lane this round; land only when no other lane holds
it)

## `home/dot_config/nushell/copymode.nu`

```nu
# copymode.nu — enter WezTerm copy mode from the shell.
# Sourced by config.nu at the MODULES anchor.
#
# Prints an OSC 1337 SetUserVar named `copymode` to stdout; WezTerm parses
# it off the pty and drops THIS pane into copy mode (wezterm.lua's
# user-var-changed handler). The handler ignores the value, but SetUserVar
# syntax requires one, base64-encoded. This is the only route from a shell
# command into a GUI-only mode — WezTerm's CLI has no action for it.
def copymode [] {
    print -n $"(char -u '1b')]1337;SetUserVar=copymode=('1' | encode base64)(char -u '7')"
}
```

The emitted bytes are exactly
`\x1b]1337;SetUserVar=copymode=MQ==\x07` (measured through `nu -n` and
`od -c` on 2026-08-22). `print -n` — a trailing newline would print a
blank line into the prompt.

## `config.nu`

Append one line at the end of the `-- ── MODULES ──` block, after the last
existing `source ~/.config/nushell/*.nu` line:

```nu
source ~/.config/nushell/copymode.nu
```

The block's own comment states the pairing rule this follows: the module
and its `source` line land in one change, because a `source` of a missing
file is a parse error that discards the whole of `config.nu` — the
definitions above the failing line as well as those below. Interactively
the shell still reaches a prompt, so the result is a working but naked
REPL; `nu -c` prints the error, never runs the command, and exits 1. The
GENERATED anchor in `config.nu` carries the measurement. Touch nothing
else in `config.nu`.

## Acceptance

- [x] `nu -n -c "source home/dot_config/nushell/copymode.nu; copymode"`
      emits exactly the 32 bytes
      `\x1b]1337;SetUserVar=copymode=MQ==\x07` — byte-compared, not
      eyeballed.
- [x] `/usr/bin/grep -c 'source ~/.config/nushell/copymode.nu'
      home/dot_config/nushell/config.nu` returns 1, inside the MODULES
      block.
- [x] `copymode.nu` names no user-var but `copymode` — `opacity` appears
      nowhere in the file (R5: one name, not two).
- [x] `bash tests/nushell-core.sh` stays ALL PASS.
      Green only after one line outside this spec's footprint. The gate's
      `mk_machine` stages each module `config.nu` sources at the MODULES
      anchor, one `cp` per module with a comment naming the owning node
      (`tests/nushell-core.sh:256-264`); a `source` of an unstaged file is a
      parse error, so the `source` line alone took the hermetic stage to 27
      FAILs. Added
      `cp "$NUSHELL_SRC/copymode.nu" ... # 02-terminal/04: config.nu sources
      copymode.nu at MODULES`, the sixth instance of that pattern, and the
      gate returns EXIT=0 with 0 FAILs. Every module-adding lane owes this
      line and the spec should name it in the footprint.

## Verify

```sh
H="$(mktemp -d)"
nu -n -c "source home/dot_config/nushell/copymode.nu; copymode" > "$H/got"
printf '\033]1337;SetUserVar=copymode=MQ==\007' > "$H/want"
cmp "$H/got" "$H/want" && echo bytes-ok
/usr/bin/grep -c 'source ~/.config/nushell/copymode.nu' home/dot_config/nushell/config.nu  # want 1
/usr/bin/grep -c 'opacity' home/dot_config/nushell/copymode.nu || true                     # want 0
bash tests/nushell-core.sh
```
