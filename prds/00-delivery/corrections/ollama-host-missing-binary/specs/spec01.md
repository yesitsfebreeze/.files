---
est: 0.5h
footprint:
  - home/dot_config/nushell/env.nu
verify: "bash tests/nushell-core.sh --hermetic"
covers: R1, R2, R3
---

# spec01 — guard the Ollama probe on `which`, and record why

One condition changes and one comment paragraph is added, both in
`home/dot_config/nushell/env.nu`. The probe keeps its body: same `complete`,
same exit-code test, same trimmed stdout. What changes is that the block is
entered only when `ollama-host` resolves.

The mechanism is not a matter of taste. Everything below was measured on the
pinned nushell 0.114.1 on 2026-08-23, against a scratch `HOME` with
`PATH=<scratch>/bin:/usr/bin:/bin` and no `ollama-host` anywhere on it,
driven through the gate's own pty runner. The implementer copies the
numbers; it does not re-derive them.

## The edit

Replace the condition on the last block of the file:

```nu
if $nu.is-interactive and (which ollama-host | is-not-empty) {
```

`and` short-circuits, so a `nu -c` caller still never runs the lookup.

Insert this paragraph directly above that line, after the existing
`Guarded on the same $nu.is-interactive as the start dir` paragraph. Wrap at
~78 columns to match the file. The wording may be tightened; every fact and
every number in it must survive, because spec02 gates the phrases marked
below.

```
# AND ON `which`, BECAUSE `complete` DOES NOT CATCH A MISSING EXTERNAL.
# This repo deploys no `ollama-host` — `git ls-files home` carries nothing
# under `.local/bin` and no package list names it — so on a fresh provision
# the binary is absent. Measured 2026-08-23 on 0.114.1 under a real pty with
# it absent, the unguarded `do { ^ollama-host } | complete` printed
# `nu::shell::external_command` / "Command `ollama-host` not found" at EVERY
# interactive start AND ABORTED THE REST OF THIS FILE: a `$env.X = ...`
# appended below this block never ran. The block being LAST is the only
# reason the visible damage is the message alone — anything appended below
# it would silently not run.
#
# `complete` is not a presence check, and no redirect makes it one:
# `^missing e> /dev/null` raises the identical error, because there is no
# child whose stderr could be redirected. `do --ignore-errors { ^missing } |
# complete` is worse still — it fails with "Complete only works with
# external commands". `try { ... }` DOES catch it, which is what makes
# config.nu's `^bash <artifact>` safe at the PALETTE anchor, but wrapping
# this probe in `try` would throw away the exit code the next line reads.
# So the guard is `which`, the same idiom that gates `tinty init` one branch
# below that artifact.
#
# COST of the guard, measured the same day in the same shell: 100 lookups of
# an ABSENT name take 0.49 ms (~5 µs each), 100 of a present one 0.94 ms
# (~9 µs each). Three orders of magnitude under the ~11 ms spawn it now
# gates, so it does not dent R9's zero-work startup.
```

## Acceptance

- [x] `home/dot_config/nushell/env.nu` enters the probe block only on
      `$nu.is-interactive and (which ollama-host | is-not-empty)`.
- [x] The block's body is byte-identical to before: the `do { ^ollama-host }
      | complete`, the `exit_code == 0` test, and
      `$env.OLLAMA_HOST = ($_ollama.stdout | str trim)`.
- [x] The existing COST paragraph (~11 ms / ~10 ms / 400 ms, dated
      2026-08-21) is still there, unedited.
- [x] The new paragraph carries all four facts: `complete` does not catch a
      missing external; the redirect does not either; `try` does but would
      discard the exit code; the guard's own measured cost.
- [x] With no `ollama-host` on PATH, an interactive start prints nothing
      about it — transcript quoted.
- [x] With an `ollama-host` on PATH that prints a marker and exits 0,
      `OLLAMA_HOST` is that marker, trimmed — quoted.

## Verify and Proof

The gate's hermetic stage is the machine-checked half (spec02 adds the
absent-binary checks; S4.26 already covers the present-binary half):

```sh
bash tests/nushell-core.sh --hermetic
```

Both halves by hand, if the transcript is wanted before spec02 lands. The
pty runner is the one this gate writes out; extract it once:

```sh
S=$(mktemp -d); cd "$(git rev-parse --show-toplevel)"
awk '/^  cat > "\$PTY" <<.PYEOF.$/{f=1;next} /^PYEOF$/{f=0} f' \
    tests/nushell-core.sh > "$S/nupty.py"
mkdir -p "$S/home/.config/nushell" "$S/home/.cache/nushell/init" "$S/bin"
for f in dirstack pass theme claude zoxide history capsule finder copymode \
         help; do cp home/dot_config/nushell/$f.nu "$S/home/.config/nushell/"
done
for p in starship zoxide television; do
  printf '# stub\n' > "$S/home/.cache/nushell/init/$p.nu"; done

# absent: nothing about ollama-host may appear
python3 "$S/nupty.py" 40 HOME="$S/home" PATH="$S/bin:/usr/bin:/bin" \
  TERM=xterm-256color -- "$(command -v nu)" --no-history \
  --config "$PWD/home/dot_config/nushell/config.nu" \
  --env-config "$PWD/home/dot_config/nushell/env.nu" \
  -e 'print $"OLLAMA:($env.OLLAMA_HOST? | default "<unset>")"; exit' \
  | tr -d '\r'

# present: the value is unchanged
printf '#!/bin/sh\necho "   http://probe-marker:11434   "\n' \
  > "$S/bin/ollama-host"; chmod +x "$S/bin/ollama-host"
# …same command again
```
