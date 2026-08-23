---
est: 1h
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
covers: R5
needs: spec01
---

# spec02 — the gate runs the probe with the binary absent

`tests/nushell-core.sh` gets one new scratch machine — the base machine with
`bin/ollama-host` deleted — plus five prose checks. The code below is not a
sketch: it was written into a copy of this gate, run against a copy of
`env.nu` carrying spec01's edit, and it goes green with the guard and red
without. Paste it, do not redesign it.

## Why the gate was blind, precisely

The PRD's R5 says the shell gates "run with the developer's real `HOME` on
PATH in at least some stages". **That is not true of this gate, and the real
reason matters more.** All three stages isolate PATH completely:
`nu_c`, `nu_pty` and `nu_pty_e` all run `/usr/bin/env -i … PATH="$M/bin:
/usr/bin:/bin"` (lines 278, 288, 298), and `cz()` in the apply stage does
the same (line 876). The developer's `~/.local/bin/ollama-host` was never
reachable from any of them.

What made the binary resolve was the **fixture**: `mk_machine` installs a
poison stub for it (line 269), `stage_apply` installs another (line 917),
and `tests/shell-listing.sh:301` states the reason outright — "an
interactive shell probes ollama-host, and a MISSING external inside its
`do|complete` is a shell error that takes the config down, so the stub must
exist". The gate stubbed the defect out and wrote down why. The second half:
the apply stage reaches the deployed `env.nu` only through `nu_c`, which
never enters an `$nu.is-interactive` branch, so the interactive path exists
in the hermetic stage alone.

So the check has exactly one home: **`stage_hermetic`, on its own machine
with the stub removed.** Leave `mk_machine` and the existing S4.26 block
alone — S4.26 is the binary-present half of the same requirement, and the
poison stub is still what proves `nu -c` never spawns it.

## Where the code goes

Insert the block below in `stage_hermetic`, directly after the last S4.26
check (`hermetic: S4.26 a probe exiting 0 sets OLLAMA_HOST to its TRIMMED
stdout`) and directly before `# ── S4.27 — the palette ladder (R10), four
machines.`

```sh
  # ── OH.1 – OH.4 — the same probe with the binary ABSENT.
  # 00-delivery/corrections/ollama-host-missing-binary. The S4.x series is
  # 04-shell/01 spec04's; these checks carry this node's own ids rather than
  # claim numbers in it.
  #
  # mk_machine installs a poison `ollama-host` DELIBERATELY, and said why:
  # before the guard, a missing external inside `do { } | complete` took
  # env.nu down. That fixture is the whole reason this gate was blind — the
  # hermetic stage isolates PATH completely (`env -i PATH=$M/bin:/usr/bin:
  # /bin`), so the only thing that ever made the binary resolve here was the
  # stub. This machine removes it.
  local MOA="$SCRATCH/m-noollama"
  mk_machine "$MOA"
  rm -f "$MOA/bin/ollama-host"

  nu_pty_e "$MOA" 'print $"OLLAMA:($env.OLLAMA_HOST? | default "<unset>")"; exit' \
    | tr -d '\r' > "$MOA/pty.out"
  sed 's/^/      /' "$MOA/pty.out"
  chk_fail "hermetic: OH.1 with NO ollama-host on PATH an interactive start never mentions it" \
           $GREP -qF 'ollama-host' "$MOA/pty.out"
  chk_fail "hermetic: OH.1 …and raises no nu::shell::external_command" \
           $GREP -qF 'nu::shell::external_command' "$MOA/pty.out"
  out="$($GREP -o 'OLLAMA:.*' "$MOA/pty.out" | head -1)"
  chk_ok "hermetic: OH.1 …and OLLAMA_HOST stays unset (got $out)" \
         test "$out" = "OLLAMA:<unset>"

  nu_c "$MOA" 'print NOOLLAMA-OK' > "$MOA/c.out" 2>"$MOA/c.err"
  if [ -s "$MOA/c.err" ]; then sed 's/^/      /' "$MOA/c.err"; fi
  chk_ok "hermetic: OH.2 nu -c against the same machine is silent (the poison stub is not load-bearing there either)" \
         test ! -s "$MOA/c.err"

  # OH.3 / OH.4 — two derived copies of env.nu, each with a marker appended as
  # its last statement, so "did the rest of the file run" is answerable. The
  # reverted copy restores the bare `$nu.is-interactive` and nothing else.
  local EK="$SCRATCH/env-keep-marker.nu" ER="$SCRATCH/env-revert-marker.nu"
  cp "$ENV_NU" "$EK"
  sed -e "s@^if \$nu.is-interactive and (which ollama-host | is-not-empty) {\$@if \$nu.is-interactive {@" \
      "$ENV_NU" > "$ER"
  printf '\n$env.OLLAMA_TAIL_MARKER = "reached"\n' >> "$EK"
  printf '\n$env.OLLAMA_TAIL_MARKER = "reached"\n' >> "$ER"
  chk_ok "hermetic: OH.4 the kept copy carries the which guard" \
         $GREP -qF 'which ollama-host' "$EK"
  chk_fail "hermetic: OH.4 …and the reverted copy really did lose it" \
           $GREP -qF 'which ollama-host' "$ER"
  chk_ok "hermetic: OH.4 …and differs from the kept copy in nothing else (same line count)" \
         test "$(wc -l < "$EK")" -eq "$(wc -l < "$ER")"

  local SAVED_ENV="$MACHINE_ENV"
  MACHINE_ENV="$EK"
  nu_pty_e "$MOA" 'print $"MARK:($env.OLLAMA_TAIL_MARKER? | default "<unset>")"; exit' \
    | tr -d '\r' > "$MOA/keep.out"
  out="$($GREP -o 'MARK:.*' "$MOA/keep.out" | head -1)"
  chk_ok "hermetic: OH.3 with the guard, the statements after the probe still run (got $out)" \
         test "$out" = "MARK:reached"

  MACHINE_ENV="$ER"
  nu_pty_e "$MOA" 'print $"MARK:($env.OLLAMA_TAIL_MARKER? | default "<unset>")"; exit' \
    | tr -d '\r' > "$MOA/rev.out"
  sed 's/^/      /' "$MOA/rev.out"
  chk_ok "hermetic: OH.4 counterfactual: the bare is-interactive guard names ollama-host on stderr" \
         $GREP -qF 'ollama-host' "$MOA/rev.out"
  chk_ok "hermetic: OH.4 …as a nu::shell::external_command" \
         $GREP -qF 'nu::shell::external_command' "$MOA/rev.out"
  out="$($GREP -o 'MARK:.*' "$MOA/rev.out" | head -1)"
  chk_ok "hermetic: OH.4 …and the error ABORTS the rest of env.nu (got $out)" \
         test "$out" = "MARK:<unset>"
  MACHINE_ENV="$SAVED_ENV"
```

Three details are load-bearing:

- The transcript assertion is the **absence of the string `ollama-host`**,
  not of the error sentence. The pty transcript carries ANSI escapes and
  nushell's error box wraps to the terminal width, so a sentence match is
  width-dependent; the bare word is not. With the guard in place the word
  cannot appear at all.
- `MACHINE_ENV` is a global that `nu_pty_e` reads. Save it, swap it, restore
  it — S4.27 and every later check run against it.
- The marker copies exist because "the error only prints a message" is
  false. Under the reverted guard the statements after the probe do not run;
  the block being the last one in `env.nu` is the only thing limiting
  today's damage.

## The prose half

Add these beside the existing `why:` checks in `stage_tree`, directly above
`chk_ok "why: the guard deviation is recorded in BOTH files, …"`:

```sh
  # OH.5 — 00-delivery/corrections/ollama-host-missing-binary R3: the reason
  # the guard is `which` and not `complete` is the expensive part.
  chk_ok "why: OH.5 env.nu records that complete does not catch a missing external" \
         has . "$ENV_TXT" '`complete` DOES NOT CATCH A MISSING EXTERNAL'
  chk_ok "why: OH.5 …that the unguarded probe aborted the rest of the file" \
         has . "$ENV_TXT" 'ABORTED THE REST OF THIS FILE'
  chk_ok "why: OH.5 …that try would discard the exit code the probe reads" \
         has . "$ENV_TXT" 'would throw away the exit code'
  chk_ok "why: OH.5 …and the measured cost of the lookup it replaced it with" \
         has . "$ENV_TXT" '~5 µs each'
  chk_ok "tree: OH.6 the probe block is guarded on the binary resolving" \
         $GREP -qF 'if $nu.is-interactive and (which ollama-host | is-not-empty) {' "$ENV_NU"
```

## Acceptance

- [x] `bash tests/nushell-core.sh` reaches `EXIT=0` with every OH check
      PASS — the ten hermetic lines and the five tree lines quoted.
- [x] The counterfactual: with spec01's guard reverted in
      `home/dot_config/nushell/env.nu` and nothing else changed, the same
      command exits 1, and `OH.1` (both lines), `OH.3` and `OH.6` are FAIL.
      Quote them, then restore the guard and show green again.
- [x] `mk_machine`, the S4.26 block and every other existing check are
      byte-unchanged. `git diff --stat tests/nushell-core.sh` shows
      insertions only.
- [x] The gate still leaves the live files alone: the three `S4.36` /
      `S4.5` / `S4.8` lines at the end of the run are PASS.

## Verify and Proof

Run it **alone**. Gates run in parallel make the pty runs return empty
output and go red for a reason no change caused — the class is recorded in
[`sibling-gates-copymode-staging`](../../sibling-gates-copymode-staging/specs/spec01.md),
which measured exactly that against S4.26. One red S4.27 line was seen in
one of two lone full runs of this gate on 2026-08-23, the same class.

```sh
bash tests/nushell-core.sh
```
