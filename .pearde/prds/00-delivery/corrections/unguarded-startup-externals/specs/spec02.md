---
est: 0.5h
footprint:
  - home/dot_config/nushell/zoxide.nu
verify: "bash tests/shell-zoxide.sh --tree"
covers: R2, R3
---

# spec02 — three `zoxide.nu` guards: silence in the fallback, a message in `z`/`zi`

`home/dot_config/nushell/zoxide.nu` gets one small helper and three guards.
The split is the whole point of R3 and it is not symmetric:

- **`_z_fallback` (line 165) bails SILENTLY.** It runs on `pre_execution` for
  every unresolvable bare word — every typo — and nothing asked for zoxide
  there. The shell's own unknown-command error must be the only thing the user
  sees.
- **`_z_jump` (line 53) and `_zi_nav` (line 89) print a deliberate message.**
  These are reached because the user typed `z`, `zi`, `zl`, `zc` or `cdi`.
  Silence there would be a command that does nothing and says nothing.

Measured on the pinned 0.114.1 on 2026-08-23, with the machine shape
`tests/shell-zoxide.sh`'s `mk_machine` builds and `$env.PATH` narrowed so
`zoxide` does not resolve. The numbers are copied, not re-derived.

## The edits

**1 — the helper, inserted directly after the `_recents_add` shim and
BEFORE `_z_jump`:**

```nu
# _z_no_zoxide — the one message the USER-INVOKED entry points share (R3).
# Defined ABOVE its call sites, and that is load-bearing for the same reason
# the header gives for `cc` and `__zoxide_z`: nushell binds a def body's
# calls at PARSE time, so a helper defined below them would bind as an
# EXTERNAL and fail at runtime on the one path that is supposed to be the
# clean answer.
def _z_no_zoxide [] {
    print -e "zoxide not installed — z/zi cannot jump. Install it, then run: chezmoi apply"
}
```

The `chezmoi apply` half of the message is not filler. Installing the binary
is not enough: `home/run_after_generate-shell-init.sh:91-101` writes an
**empty** `~/.cache/nushell/init/zoxide.nu` when `zoxide` is absent
(`: > "$out"`, the truncate-on-failure branch), so until an apply regenerates
it `__zoxide_z` is undefined and binds as an external.

**2 — `_z_jump`, as the FIRST statement of the body, above the three literal
arms:**

```nu
def --env _z_jump [rest: list<string>] {
    # ABOVE THE LITERAL ARMS, not at the query below: an ABSENT zoxide means
    # an EMPTY generated init (the generator truncates on a missing tool), so
    # `__zoxide_z` is not defined either and binds as an EXTERNAL — measured
    # 2026-08-23, `z <existing dir>` answered `Command __zoxide_z not found`.
    if (which zoxide | is-empty) { _z_no_zoxide; return false }
```

**Above the literal arms, not at the query on line 53.** With zoxide absent
the generated init is empty (above), so `__zoxide_z` is not defined either:
measured, unguarded, empty init, `z ~/proj` answered
`nu::shell::external_command` / ``Command `__zoxide_z` not found`` pointing at
`zoxide.nu:50`. A guard on the query alone would leave that hole open.
`return false` is the same answer the no-match branch below already gives, so
`zl` and `zc` skip their `la` / `cc` exactly as they do on a miss, and the
whole invocation still exits 0 (measured) — a missing tool is not a failed
pipeline.

**3 — `_zi_nav`, as the FIRST statement of the body:**

```nu
def --env --wrapped _zi_nav [...rest: string] {
    if (which zoxide | is-empty) { _z_no_zoxide; return }
```

**4 — `_z_fallback`, directly above the `let q = (^zoxide query …` on line
165, replacing nothing:**

```nu
    # SILENTLY, unlike the three user-invoked sites above (R2): nothing asked
    # for zoxide here — this closure fires on EVERY unresolvable bare word —
    # so a missing binary must leave the shell's OWN unknown-command error as
    # the only thing printed. Measured 2026-08-23 with zoxide absent: two
    # typos in one session produced FOUR error boxes unguarded, the first of
    # each pair quoting this file and even offering the generated init's jump
    # function as a did-you-mean, and the string `zoxide` appeared 8 times in
    # the transcript; with the guard it is two boxes, both the shell's own,
    # and the string `zoxide` appears NOT ONCE. (The name of that function is
    # kept out of this body on purpose: absences_ok in tests/shell-zoxide.sh
    # asserts it appears nowhere here, because its empty no-match hand-off is
    # the M-8 route to HOME.)
    if (which zoxide | is-empty) { return }
```

## Why `print -e` and not `error make`

`finder.nu:44` and `capsule.nu:363` raise for a missing hard dependency;
`theme.nu:276-287` prints `<tool> not installed — <what to do>` and returns,
on the picker paths. This node follows `theme.nu`, and on `stderr` because
that is what the adjacent no-match branch in `_z_jump` already does
(`print -e ($q.stderr | str trim)`). An `error make` here would replace one
nushell error box with another, which is the thing this node exists to
remove, and it would break the bool contract `zl`/`zc` read.

## Why `which` and not `complete`, `try`, or a redirect

Settled in the PRD and in `ollama-host-missing-binary` spec01: `complete`
does not catch a missing external, `e> /dev/null` raises identically because
there is no child to redirect, `do --ignore-errors { … } | complete` fails
with "Complete only works with external commands", and `try` catches but
discards the exit code `_z_jump` reads on the very next line. `which` returns
`[]` and costs ~4 µs for an absent name (measured 2026-08-23: 420 µs per 100
lookups) against the spawn it gates. `finder.nu:44` is the in-tree precedent
for the `is-empty` bail spelling.

## What must not change

Three sibling contracts in `tests/shell-zoxide.sh` (which this node's spec04
edits, but only additively):

- `queries_ok` (lines 155-175): exactly two `^zoxide query --exclude $env.PWD --`
  lines, both piping to `| complete`, and exactly one
  `^zoxide query --interactive` with `| complete` and no `--exclude`. The
  guards go on their own lines and leave all three untouched.
- `defs_ok` (lines 129-145): the eleven listed defs/aliases/appends, each
  once, in strictly increasing line order. `_z_no_zoxide` is not in that list
  and must sit between `def _recents_add [` and `def --env _z_jump [`.
- `absences_ok` (lines 175-182): no `$env.config.hooks.env_change.PWD` in
  this file, and no `__zoxide_z` inside the `_z_fallback` body — **comments
  included**. A first draft of the fallback comment quoted nushell's
  `help: Did you mean __zoxide_z?` verbatim and turned that check red; the
  wording above names the function indirectly for that reason, and says so.

Checked against exactly these edits: `bash tests/shell-zoxide.sh --tree`
reports no new FAIL (see the pre-existing red in spec04).

## Acceptance

- [x] `_z_fallback` bails on `if (which zoxide | is-empty) { return }` and
      prints nothing — `_z_no_zoxide` does **not** appear in its body.
- [x] `_z_jump` and `_zi_nav` each bail on the same condition through
      `_z_no_zoxide`, as the first statement of the body — before `_z_jump`'s
      literal arms.
- [x] `_z_no_zoxide` is defined once, above `_z_jump`, and its message
      carries both halves: the tool is missing, and `chezmoi apply` is what
      makes it work after installing.
- [x] The comment at the fallback records the asymmetry with its reason and
      the measured before/after counts.
- [x] `bash tests/shell-zoxide.sh --tree` shows no FAIL other than the
      pre-existing `exactly six entries name this PRD as their source`
      (spec04 documents it).
- [x] By hand, quoted in the report, with `zoxide` absent: `z <query>`, `zi`,
      `zl <query>` and `z <existing dir>` each print the message once, leave
      PWD unchanged and exit 0; two typos print two error boxes that name the
      typed word and never the string `zoxide`.

```sh
S=$(mktemp -d); cd "$(git rev-parse --show-toplevel)"
mkdir -p "$S/home/.config/nushell" "$S/home/.cache/nushell/init" "$S/bin" \
         "$S/home/proj" "$S/elsewhere"
for f in dirstack pass theme claude zoxide history capsule finder copymode \
         help; do cp home/dot_config/nushell/$f.nu "$S/home/.config/nushell/"
done
for p in starship television; do
  printf '# stub\n' > "$S/home/.cache/nushell/init/$p.nu"; done
: > "$S/home/.cache/nushell/init/zoxide.nu"   # what the generator writes
                                             # when zoxide is absent
for c in 'z projquery' 'zi' 'zl someq' 'z ~/proj'; do
  ( cd "$S/elsewhere" && /usr/bin/env -i HOME="$S/home" \
      PATH="$S/bin:/usr/bin:/bin" "$(command -v nu)" --no-history \
      --config "$PWD/home/dot_config/nushell/config.nu" \
      --env-config "$PWD/home/dot_config/nushell/env.nu" \
      -c "\$env.PATH = [\"/usr/bin\"]; $c; print \$\"PWD:(\$env.PWD)\"" ) 2>&1
  echo "rc=$?"
done
```

      Measured output per command, guarded: the message, then
      `PWD:<…>/elsewhere`, then `rc=0`. Unguarded: `Error:
      nu::shell::external_command` / ``Command `zoxide` not found`` and
      `rc=1` for the first three, and ``Command `__zoxide_z` not found`` for
      `z ~/proj`. The typo half needs the pty — spec04's ZX.4 is the
      machine-checked form.

## Verify and Proof

```sh
bash tests/shell-zoxide.sh --tree
```

R2 and R3's executed proof lands in spec04; run the full
`bash tests/shell-zoxide.sh` **alone** once that is in.
