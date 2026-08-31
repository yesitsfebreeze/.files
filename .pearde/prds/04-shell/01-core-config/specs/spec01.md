# spec01 — `home/dot_config/nushell/env.nu`

Covers **R1**, **R2** and the shell-start half of **R7** of
[`../prd.md`](../prd.md).

## Goal

The environment file nushell evaluates *before* `config.nu`: repair PATH for a
login shell macOS never ran `path_helper` for, set the handful of variables the
rest of the epic reads, and open an interactive shell where the user last
navigated — while leaving `nu -c` in its caller's directory.

## Exact files touched

- **create** `home/dot_config/nushell/env.nu` → deploys to
  `~/.config/nushell/env.nu`

Nothing else. Measured: `home/.chezmoiignore` holds only `README.md` /
`**/README.md` / `.DS_Store` / `**/.DS_Store`, and `env.nu` matches none of
them, so no ignore edit is needed. `~/.config/nushell` is the right target on
this host — measured, `$nu.default-config-dir` is
`/Users/feb/.config/nushell`, not the macOS
`~/Library/Application Support/nushell` that `$nu.user-autoload-dirs`
resolves to.

## Decisions this spec makes, with the evidence

**D1 — `ENV_CONVERSIONS` is kept, and R2's stated reason for it is wrong on
the pinned version.** R2 says "without it `$env.PATH` is a plain string — so
every `prepend`, `append` and `uniq` in R1 silently does the wrong thing".
Measured on nushell **0.114.1** (the pinned version), with an empty
env-config and no `ENV_CONVERSIONS` anywhere:

```
$ env -i HOME=<scratch> PATH=/opt/homebrew/bin:/usr/bin:/bin \
    nu --config /dev/null --env-config /dev/null \
       -c 'print ($env.PATH | describe); print ($env.PATH | length)'
list<string>
3
$ ... -c '$env.PATH = ($env.PATH | prepend "/zzz" | uniq); printenv PATH'
/zzz:/opt/homebrew/bin:/usr/bin:/bin
```

`$env.PATH` is *already* a `list<string>` and *already* round-trips to a
colon string for children. R1 does not depend on this block on 0.114.1. The
block is still written, because R2 makes it a box and because it is cheap
insurance if a future nushell drops the built-in special case — but the
comment in the file must record the measurement, not repeat the false
premise. **This is a PRD defect to file on the corrections backlog** (see
Hand-offs).

**D2 — the conversion closures do *not* call `path expand`.** The live block
runs `path expand --no-symlink` in both directions. Measured, both directions,
0.114.1:

| inherited `PATH` entry | live block | no block at all |
|---|---|---|
| `~/mybin` | exported as `<HOME>/mybin` | exported as `<HOME>/mybin` |
| `rel/dir` | exported as `<cwd>/rel/dir` | exported as `rel/dir` |

`from_string` had **no** observable effect in either case (the incoming list
showed `rel/dir` and `~/mybin` verbatim with the block installed). The only
behaviour the live block buys is the second row: a relative PATH entry becomes
absolute **against the current working directory**, which makes the exported
`PATH` change as you `cd`. That is a surprise, not a feature. The closures are
therefore a plain round trip — `split row (char esep)` / `str join
(char esep)`.

**D3 — the `"Path"` key is kept anyway.** R2's box names `PATH` *and* `Path`,
and `Path` is the Windows spelling on a host the scope decisions already
declare macOS-only. It costs one record entry and keeping it keeps the box
honest against its own wording; the file comment records that it is inert here
and why it is not evidence of Windows support.

**D4 — the interactivity guard is `is-terminal --stdout`, and it is stronger
than its name suggests.** R7 requires `nu -c` to keep its caller's cwd. That
only works if the guard is false for `nu -c` *even when the caller has a real
terminal*. Measured under a real pty allocated by `script(1)`, where
`/bin/sh`'s own `[ -t 1 ]` is **true**:

```
SH_TTY_YES
false      # nu -n -c 'print (is-terminal --stdout)'
false      # nu -n -c 'print ($nu.is-interactive)'
```

So `is-terminal --stdout` is false for every `-c` invocation, terminal or not,
and R7's acceptance line (`nu -c 'pwd'` from another dir prints that dir) holds
with it. `$nu.is-interactive` would work equally well for R7; `is-terminal
--stdout` is kept because R2's probe guard and R10's palette guard want the
`nu | cat` case suppressed too, and one guard expression for all three is one
thing to reason about.

**D5 — the `ollama-host` probe stays, with a measured cost, not an adjective.**
R2 asks for the cost to be recorded "to be weighed against R9's zero-work
startup". Measured on this machine 2026-08-21, `~/.local/bin/ollama-host`
(a `sh` script running one `curl -fs --max-time 0.4`):

- Ollama listening on 127.0.0.1:11434 (it is, PID 1174): **~11 ms** per call
  (10 calls, 0.11 s; repeated, 0.105 s).
- Nothing listening (`OLLAMA_PORT=11999`): **~10 ms** per call — a refused
  connection returns immediately.
- Worst case is bounded by curl's own `--max-time 0.4`, i.e. **400 ms**, and
  only for a host that *drops* rather than refuses.

For scale, R10's palette re-assert costs ~5 ms and the `tinty init` it avoids
costs ~128 ms (both measured, see spec03 D3). ~11 ms is real but is not the
thing that would blow R9.

**D6 — `PASSWORD_STORE_DIR` is deliberately not set here.** The live `env.nu`
sets it. R2 does not name it and this PRD's Out of scope is "anything this
node's Requirements do not name". It belongs with the `pass` completion that
reads it — [`04-shell/02`](../../02-aliases-utilities/prd.md) R6. Recorded so
its absence reads as a decision. Hand-off below.

## Requirements — boxes a real check can fail

- [x] **S1.1** — The file exists at `home/dot_config/nushell/env.nu` and
      begins with a comment naming what evaluates it and when (nushell's
      env-config, before `config.nu`).
- [x] **S1.2** — **`$env.ENV_CONVERSIONS`** is set with `PATH` and `Path`
      records, each with `from_string` and `to_string`, and **neither closure
      calls `path expand`** (D2). A grep for `path expand` in this file
      returns nothing.
- [x] **S1.3** — **PATH repair (R1).** `$env.PATH` is rebuilt as: `prepend`
      `$nu.home-dir/.local/bin`, `prepend` `$nu.home-dir/.cargo/bin`, `append`
      the seven system/brew dirs `/opt/homebrew/bin`, `/opt/homebrew/sbin`,
      `/usr/local/bin`, `/usr/bin`, `/bin`, `/usr/sbin`, `/sbin`, then `uniq`.
      Checkable end state, from a scratch `PATH=/usr/bin:/bin`: the resulting
      list starts with `<HOME>/.cargo/bin`, `<HOME>/.local/bin`, contains
      `/opt/homebrew/bin`, and contains no duplicate entries.
- [x] **S1.4** — **PATH repair is a no-op when the parent already provided
      the dirs.** Run twice with the second run inheriting the first run's
      exported `PATH`: the two exported strings are byte-identical.
- [x] **S1.5** — **The `path_helper` reason is in the file.** The comment
      states that macOS seeds these dirs via `path_helper` from
      `/etc/zprofile` and `/etc/profile` only, that nushell never runs it, and
      that a GUI-launched WezTerm with nu as the login shell therefore starts
      without Homebrew on PATH. Without the reason the block looks like
      cargo-culting and the next reader deletes it.
- [x] **S1.6** — **Environment (R2).** Exactly these are set, and a check can
      read each back out of a `nu -c` run: `EDITOR` = `nvim`, `VISUAL` =
      `nvim`, `SHELL` = `$nu.current-exe`, `XDG_CONFIG_HOME` =
      `<HOME>/.config`, `RIPGREP_CONFIG_PATH` = `<HOME>/.config/ripgrep/config`,
      `STARSHIP_SHELL` = `nu`.
- [x] **S1.7** — **`RIPGREP_CONFIG_PATH` carries its reason:** it is what
      makes `rg` share the ignore rules `fd` reads natively from
      `~/.config/fd/ignore`. Without the pointer the two finders disagree
      about `node_modules`.
- [x] **S1.8** — **`STARSHIP_SHELL` carries its reason:** starship is the
      prompt (sourced from R9's generated init) and R5's OSC-133 disable is
      specific to starship's *two-line* prompt, so the file that names the
      prompt and the file that works around it must be readable together.
- [x] **S1.9** — **`SHELL` carries its reason:** it is the fallback for
      anything that spawns "the user's shell" by `$SHELL`, not the primary
      path. (The live comment's burrito rationale is dropped — burrito is
      `DO NOT PORT`, per the README exclusion list.)
- [x] **S1.10** — **Start dir (R7).** Guarded on `is-terminal --stdout`: read
      `<state>/nushell/startdir.txt`, use it only when non-empty **and**
      `path exists`, otherwise `cd` the fallback `$nu.home-dir/dev`, which is
      `mkdir`-ed first so the `cd` cannot fail on a fresh machine. `<state>`
      is `$env.XDG_STATE_HOME?` defaulted to `<HOME>/.local/state`.
- [x] **S1.11** — **The mirrored path is declared as a mirror.** This file
      recomputes the `startdir.txt` path that
      [`spec02`](spec02.md)'s `_startdir_file` also computes, because `env.nu`
      runs before `config.nu` sources `dirstack.nu` and so cannot call it. The
      comment says so and names the other file. A check greps both files for
      the literal segments `nushell` / `startdir.txt` and for the same
      `XDG_STATE_HOME` default, and fails if they diverge.
- [x] **S1.12** — **`nu -c` keeps its caller's cwd (R7, D4).** From a
      directory that is not the start dir, `nu --config <config.nu>
      --env-config <env.nu> -c 'pwd'` prints the caller's directory. Must also
      hold when the caller has a real terminal (run it under `script(1)`).
- [x] **S1.13** — **The `ollama-host` probe (R2, D5).** Guarded on
      `$nu.is-interactive` **and** on `which ollama-host` resolving —
      *amended 2026-08-23 by the orchestrator: this box named
      `is-terminal --stdout`, retired by the guard-deviation correction
      recorded at line 213 below, and the existence half was added by
      `00-delivery/corrections/ollama-host-missing-binary` after it measured
      that an absent binary aborts the rest of `env.nu`*; runs
      `^ollama-host` through `complete`; sets
      `$env.OLLAMA_HOST` from trimmed stdout **only** on exit code 0. The
      comment records the measured cost from D5 (~11 ms up, ~10 ms refused,
      400 ms bounded worst case) with the date. A check with a poison
      `ollama-host` on PATH proves it is never spawned under `nu -c`, and a
      check with a stub exiting 1 proves `OLLAMA_HOST` stays unset.
- [x] **S1.14** — **No generated-integration work here.** `env.nu` sources
      nothing and spawns nothing but the R2 probe; the comment points at R9 /
      `config.nu` for where the generated init files are sourced.
- [x] **S1.15** — **Writes nothing outside `$HOME/dev` and the state dir.**
      Under an isolated `HOME`, the only paths created by an interactive-guarded
      run are `<HOME>/dev` (S1.10) and nothing else; under `nu -c` neither is
      created.

## Out of scope

- `PASSWORD_STORE_DIR` (D6), `OLLAMA_PORT` tuning, and anything else the live
  `env.nu` sets that R1/R2/R7 do not name.

## Hand-offs

- **Corrections backlog (a new row, not this node's to write):** R2's
  ENV_CONVERSIONS sub-box states a premise that is false on the pinned
  nushell 0.114.1 (D1). The requirement survives; its reason must be replaced
  with the measurement.
- **[`04-shell/02`](../../02-aliases-utilities/prd.md) R6** — the `pass`
  completion needs `PASSWORD_STORE_DIR`; D6 leaves it to that node.
- **[`02-terminal`](../../../02-terminal/prd.md)** — WezTerm launches nu with
  explicit `--config`/`--env-config` pointing at these two files
  (`wezterm.lua:16-19` live). That coupling is the terminal epic's to keep, not
  this one's; it is named here so the dependency is not invisible.

## Implementation record

Built 2026-08-21. All fifteen boxes ticked against `bash tests/nushell-core.sh`
(147 PASS / 0 FAIL).

**D4 was superseded by measurement: the guard shipped is `$nu.is-interactive`,
not `is-terminal --stdout`.** D4's measurement covered the `nu -c` half only.
Measured under a real pty (where a `/bin/sh -c '[ -t 1 ]'` spawned from inside
nu answers yes), with the guard in the `if (…)` position this file actually
uses, `is-terminal --stdout` is false **interactively as well** — a
parenthesised sub-expression captures stdout, and the command reports the
current pipeline's redirection state. With D4's guard, S1.10 and S1.13 would be
dead code. D4 itself names `$nu.is-interactive` as working equally well for R7,
and it is what S1.12's `nu -c` requirement needs. The full argument, and the
corrections-backlog hand-off, are in [`../prd.md`](../prd.md)'s Implementation
record. S1.10 and S1.13 are ticked on the *behaviour* they specify, proved with
the working guard.
