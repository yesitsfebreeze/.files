---
est: 1h
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
covers: R1, R4
needs: spec01
---

# spec03 — the gate drives the PWD closure with `stty` unresolvable

`tests/nushell-core.sh` gets one machine in `stage_hermetic`, two derived
`config.nu` copies, and six prose/text checks in `stage_tree`. **The code
below is not a sketch.** It was inserted into a copy of this gate, run against
a copy of `config.nu` carrying spec01's edit and comment, and it is green with
the guard and red without — both runs quoted at the foot of this file. Paste
it; do not redesign it.

## How the binary is made absent, and why not the obvious way

`ollama-host-missing-binary` spec02 deleted a poison stub. **That does not
work here, twice over:**

1. **No fixture is hiding `stty`.** `mk_machine` (line 269) poisons
   `bash tinty ollama-host starship zoxide tv brew`; a grep across all of
   `tests/` finds no `stty` stub anywhere. So unlike the `ollama-host` case
   there is nothing to delete — the six sibling gates that carried an
   `ollama-host` stub carry none for this.
2. **`stty` cannot be hidden from outside the shell at all.** `env.nu`'s PATH
   repair (the `$env.PATH = (…)` block, lines 65-79) `append`s `"/bin"` —
   along with `/opt/homebrew/bin`, `/usr/bin` and the rest —
   *unconditionally*, `uniq`ed. So `nu_pty`'s
   `PATH="$M/bin:/usr/bin:/bin"` is not the effective PATH, and neither
   `env -i` nor a trimmed machine `bin` keeps `/bin/stty` out of it. Measured:
   with `PATH="$M/bin:/usr/bin"` (no `/bin`), `which stty | length` inside the
   shell is still `1`.

So the absence is made **inside the session**, by narrowing `$env.PATH` in the
REPL before the `cd`. Nushell resolves every external against the live
`$env.PATH` (measured: `which stty | length` is `0` immediately after, and the
spawn then fails), and that is R1's real-world case anyway — a mangled PATH,
which is exactly when the shell has to keep working. The alternative
considered and rejected: a derived `env.nu` with `"/bin"` cut from the append
list, which is a second fixture to keep in sync with a file this node does not
otherwise touch.

## Why a marker file rather than the listing

`^stty sane` runs first in the closure, so what the error kills is the `la`
below it — but **the listing is not observable in this gate.** Its pty runner
(`write_pty_runner`, line 125) sets no winsize, `term size` reports 0 columns,
and the closure's own width guard skips `la` there. `tests/shell-listing.sh`
is the gate with the winsize-setting runner and it already owns the listing
(its H8). So the abort is proved with a marker statement inserted right after
the spawn in a derived copy: with the guard the marker is written, with the
bare spawn it never is. spec01 carries the hand-run transcript of the listing
itself.

## The hermetic block

Insert directly **before** `  # ── S4.27 — the palette ladder (R10), four
machines.`, i.e. after the last `OH.4` line and the `MACHINE_ENV="$SAVED_ENV"`
that closes the ollama block.

```sh
  # ── ST.1 – ST.4 — the auto-list closure's `^stty sane` with stty ABSENT.
  # 00-delivery/corrections/unguarded-startup-externals R1/R4. The S4.x series
  # is 04-shell/01 spec04's; these checks carry this node's own ids.
  #
  # THE BINARY CANNOT BE HIDDEN FROM OUTSIDE THIS SHELL, and no fixture is
  # hiding it either: mk_machine poisons bash/tinty/ollama-host/starship/
  # zoxide/tv/brew and NOTHING anywhere under tests/ poisons stty, so unlike
  # the ollama-host case there is no stub to delete. env.nu's PATH repair
  # APPENDS "/bin" — and /opt/homebrew/bin, /usr/bin, … — unconditionally, so
  # nu_pty's PATH="$M/bin:/usr/bin:/bin" is not the effective PATH and
  # /bin/stty always comes back. The absence is therefore made INSIDE the
  # session by narrowing $env.PATH in the REPL before the cd: nushell resolves
  # every external against the live $env.PATH (measured: `which stty | length`
  # is 0 immediately after). That is also R1's real case — a mangled PATH,
  # which is exactly when the shell has to keep working.
  local MST="$SCRATCH/m-nostty"
  mk_machine "$MST"
  mkdir -p "$MST/home/s1" "$MST/home/s2"
  local PROMPT_ST='@WAIT=\x1b[?2004h'
  nu_pty "$MST" "$PROMPT_ST" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT_ST" "@SEND=cd $MST/home/s1\r" \
                "$PROMPT_ST" "@SEND=cd $MST/home/s2\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MST/pty.out"
  echo "      stty error boxes: $($GREP -acF 'Command `stty` not found' "$MST/pty.out"), external_command: $($GREP -acF 'nu::shell::external_command' "$MST/pty.out"), dirs.txt: $(tr '\n' '|' < "$MST/home/.local/state/nushell/dirs.txt" 2>/dev/null)"
  chk_fail "hermetic: ST.1 with stty unresolvable a cd raises no nu::shell::external_command" \
           $GREP -qF 'nu::shell::external_command' "$MST/pty.out"
  chk_fail "hermetic: ST.1 …and the transcript never reports a missing stty" \
           $GREP -qF 'Command `stty` not found' "$MST/pty.out"
  chk_ok "hermetic: ST.2 …and the dirstack still recorded BOTH moves" \
         test "$(cat "$MST/home/.local/state/nushell/dirs.txt" 2>/dev/null)" = "$(printf '%s\n%s' "$MST/home/s2" "$MST/home/s1")"

  # ST.3 / ST.4 — two derived copies of config.nu, each with a MARKER as the
  # statement right after the stty spawn, so "did the rest of the closure run"
  # is answerable. The reverted copy restores the bare spawn and changes
  # nothing else. The marker is needed because the listing itself is NOT
  # observable here: this gate's pty runner sets no winsize, `term size`
  # reports 0 columns and the closure's own width guard skips `la`. The
  # listing half is tests/shell-listing.sh's H8, whose runner is the
  # winsize-setting variant.
  local GUARDED_ST='            if (which stty | is-not-empty) { ^stty sane e> /dev/null }'
  local BARE_ST='            ^stty sane e> /dev/null'
  local MARKER_ST='            "reached" | save -f ($nu.home-dir | path join "stty-tail.txt")'
  local CK="$SCRATCH/cfg-keep-marker.nu" CR="$SCRATCH/cfg-revert-marker.nu"
  awk -v g="$GUARDED_ST" -v m="$MARKER_ST" '{ print } $0 == g { print m }' \
      "$CONFIG_NU" > "$CK"
  awk -v g="$GUARDED_ST" -v b="$BARE_ST" -v m="$MARKER_ST" \
      '{ if ($0 == g) { print b; print m } else print }' "$CONFIG_NU" > "$CR"
  chk_ok "hermetic: ST.3 the kept copy carries the which guard and the marker" \
         test "$($GREP -cF 'which stty | is-not-empty' "$CK")" -eq 1 \
              -a "$($GREP -cF 'stty-tail.txt' "$CK")" -eq 1
  chk_fail "hermetic: ST.4 …and the reverted copy really did lose the guard" \
           $GREP -qF 'which stty | is-not-empty' "$CR"
  chk_ok "hermetic: ST.4 …and differs from the kept copy in nothing else (same line count)" \
         test "$(wc -l < "$CK")" -eq "$(wc -l < "$CR")"

  local SAVED_CFG="$MACHINE_CFG"
  MACHINE_CFG="$CK"
  local MSK="$SCRATCH/m-nostty-keep"; mk_machine "$MSK"; mkdir -p "$MSK/home/s1"
  nu_pty "$MSK" "$PROMPT_ST" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT_ST" "@SEND=cd $MSK/home/s1\r" \
                "$PROMPT_ST" '@SEND=exit\r' > /dev/null 2>&1
  chk_ok "hermetic: ST.3 with the guard the statements AFTER the spawn still run (got $(cat "$MSK/home/stty-tail.txt" 2>/dev/null || echo '<absent>'))" \
         test "$(cat "$MSK/home/stty-tail.txt" 2>/dev/null)" = "reached"

  MACHINE_CFG="$CR"
  local MSR="$SCRATCH/m-nostty-rev"; mk_machine "$MSR"; mkdir -p "$MSR/home/s1"
  nu_pty "$MSR" "$PROMPT_ST" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT_ST" "@SEND=cd $MSR/home/s1\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MSR/pty.out"
  chk_ok "hermetic: ST.4 counterfactual: the bare spawn raises nu::shell::external_command" \
         $GREP -qF 'nu::shell::external_command' "$MSR/pty.out"
  chk_ok "hermetic: ST.4 …naming the missing stty, the e> /dev/null notwithstanding" \
         $GREP -qF 'Command `stty` not found' "$MSR/pty.out"
  chk_fail "hermetic: ST.4 …and the statements after it never ran" \
           test -f "$MSR/home/stty-tail.txt"
  MACHINE_CFG="$SAVED_CFG"
```

Four details are load-bearing:

- `MACHINE_CFG` is the global `nu_pty` reads. Save it, swap it, **restore
  it** — S4.27 and every later check run against it. (The ollama block does
  the same with `MACHINE_ENV`.)
- The `$env.PATH` narrowing is typed as its own REPL line *before* the `cd`,
  because the PWD hook fires between REPL entries, not between statements on
  one line (S4.29 records the same constraint).
- The two derived copies differ by exactly one line's content, and the
  same-line-count check is what proves it.
- ST.2 stays green with **and** without the guard, deliberately: the dirstack
  push is the FIRST PWD append and survives either way. It is in the block as
  the measured record of what the ordering protects, not as a counterfactual.

## The tree block

Insert directly **above** `  chk_ok "why: the guard deviation is recorded in
BOTH files, with its measurement" \` in `stage_tree`, after the ollama `OH.5`
/ `OH.6` lines. `has`, `$CFG_TXT` and `norm` are already in scope there.

```sh
  # ST.5 / ST.6 — 00-delivery/corrections/unguarded-startup-externals R1: the
  # reason the guard is `which` and the measured blast radius are the
  # expensive part of this fix.
  chk_ok "why: ST.5 config.nu records that the redirect cannot suppress a not-found error" \
         has . "$CFG_TXT" 'there is no child process whose stderr could be redirected'
  chk_ok "why: ST.5 …that the unguarded spawn costs one error box per cd" \
         has . "$CFG_TXT" 'ONE FULL ERROR BOX PER CD'
  chk_ok "why: ST.5 …that the abort reaches every PWD closure appended after it" \
         has . "$CFG_TXT" 'every PWD closure appended AFTER it never runs either'
  chk_ok "why: ST.5 …and that it is not a session-wide latch" \
         has . "$CFG_TXT" 'not a session-wide latch'
  chk_ok "why: ST.5 …with the measured cost of the lookup that replaced it" \
         has . "$CFG_TXT" '~4 µs each'
  chk_ok "tree: ST.6 the stty spawn is guarded on the binary resolving" \
         $GREP -qF 'if (which stty | is-not-empty) { ^stty sane e> /dev/null }' "$CONFIG_NU"
```

## Acceptance

- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, with all
      ten `ST.*` hermetic lines and all six tree lines PASS. Quote them.
- [x] The counterfactual: with spec01's guard reverted in `config.nu` and
      nothing else changed, the same gate exits 1 and `ST.1` (both lines),
      `ST.3` (both lines) and `ST.6` are FAIL. Quote them, restore the guard,
      show green again.
- [x] `mk_machine`, the `S4.*` series and the `OH.*` block are byte-unchanged:
      `git diff --stat tests/nushell-core.sh` shows insertions only.
- [x] The gate still leaves the live files alone — the closing `S4.36`,
      `S4.5` and `S4.8` lines are PASS.

## Verify and Proof

Run it **alone.** Gates run in parallel make the pty runs return empty output
and go red for a reason no change caused; the class is recorded in
[`sibling-gates-copymode-staging`](../../sibling-gates-copymode-staging/specs/spec01.md).
Two other implementers' gates were running while this spec was written, which
is why the `--apply` stage is left to the implementer.

```sh
bash tests/nushell-core.sh
```

Measured on 2026-08-23 in a scratch copy of the tree carrying spec01's edit
and comment, this exact block inserted:

```
bash tests/nushell-core.sh --tree      → EXIT=0   (ST.5 ×5, ST.6 PASS)
bash tests/nushell-core.sh --hermetic  → EXIT=0   (all ten ST lines PASS,
                                          "stty error boxes: 0,
                                           external_command: 0,
                                           dirs.txt: …/s2|…/s1|")
```

and with the guard reverted to the bare spawn, nothing else changed:

```
--hermetic → EXIT=1
  FAIL hermetic: ST.1 with stty unresolvable a cd raises no nu::shell::external_command
  FAIL hermetic: ST.1 …and the transcript never reports a missing stty
  PASS hermetic: ST.2 …and the dirstack still recorded BOTH moves
  FAIL hermetic: ST.3 the kept copy carries the which guard and the marker
  FAIL hermetic: ST.3 with the guard the statements AFTER the spawn still run (got <absent>)
--tree     → EXIT=1
  FAIL tree: ST.6 the stty spawn is guarded on the binary resolving
```
