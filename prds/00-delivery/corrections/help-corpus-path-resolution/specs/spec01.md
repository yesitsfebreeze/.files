---
est: 1h
footprint:
  - home/dot_config/nushell/help.nu
---

# spec01 — address the corpus by the literal that sources help.nu, and raise when it is not there

`_help_dir` reads `$nu.default-config-dir`, a launch-time constant. Replace it
with `$nu.home-dir | path join ".config" "nushell" "help"` — the same
`~/.config/nushell` literal `config.nu` uses to `source` help.nu itself — and
make a corpus that is absent or degenerate raise a named error instead of
rendering an empty manual.

## What was measured

All measurements on the pinned nushell 0.114.1, 2026-08-23, against a staged
machine holding the managed nushell tree under `$HOME/.config/nushell` plus
the corpus, every run under `/usr/bin/env -i` with `HOME` and `PATH` only.

Four launch shapes, four candidate resolutions:

| launch shape | `$nu.default-config-dir` | `$nu.config-path \| path dirname` | `$env.XDG_CONFIG_HOME` | `$nu.home-dir/.config/nushell` |
|---|---|---|---|---|
| plain `nu`, no `XDG_CONFIG_HOME` | `~/Library/Application Support/nushell` | same | unset | `~/.config/nushell` |
| plain `nu`, `XDG_CONFIG_HOME` exported | `~/.config/nushell` | `~/.config/nushell` | `~/.config` | `~/.config/nushell` |
| `nu --config ~/.config/nushell/config.nu`, no export | `~/Library/Application Support/nushell` | `~/.config/nushell` | `~/.config` (env.nu sets it) | `~/.config/nushell` |
| `nu --config <other tree>/config.nu`, export elsewhere | the export's dir | `<other tree>` | the export's dir | `~/.config/nushell` |

Three facts settle the choice.

1. **The third row is the defect, and it is the deployed shape.** With
   `--config` naming our tree and no export, `help` fails with nushell's raw
   `nu::shell::io::file_not_found` at `help.nu:93`, rc 1. Not an empty
   manual — a stack trace.

2. **`$nu.config-path | path dirname` is not correct by construction.**
   `config.nu` sources every module by a `~`-literal
   (`source ~/.config/nushell/help.nu`), so `--config` pointed at another
   tree still loads `$HOME/.config/nushell/help.nu`. Measured with a marker
   `def` in each of two trees: `--config <alt>/config.nu` printed
   `HOME-HELP-NU`. So `$nu.config-path | path dirname` can name a directory
   that did not supply the running `help.nu` — row four — and the renderer
   and its corpus come from different trees.

3. **`$nu.home-dir`-relative agrees with that literal in every shape.**
   Same value in all four rows, and it is exactly the directory `help.nu`
   itself was read from. This is `config.nu`'s own GENERATED rule one level
   down: *"One hardcoded path on both sides cannot diverge."* The
   `env.nu`/`dirstack.nu` `startdir.txt` mirror is the same pattern, and it
   is gated the same way (spec02).

`$env.XDG_CONFIG_HOME` is rejected for a second reason: `env.nu` assigns it
unconditionally, so it is a copy of `$nu.home-dir/.config` whenever env.nu
ran and nothing at all when it did not.

**No fallback chain.** One resolution, no `if not exists then try elsewhere`.
A fallback is what turns "not found" into "found somewhere wrong", and row
four already shows what that costs: a manual that renders, exits 0, and
describes a different machine.

**Out of this spec's reach, on purpose.** Row one — plain `nu` with no
export, which is a GUI-launched WezTerm today, since `wezterm.lua`
deliberately carries no `default_prog` — loads
`~/Library/Application Support/nushell/config.nu`. That file does not exist,
so *none* of the repo's nushell configuration loads and `help` is nushell's
builtin welcome text. Measured. No line in `help.nu` can change that,
because `help.nu` is never sourced. That half belongs to
[`02-terminal/06-launchd-path`](../../../../02-terminal/06-launchd-path/prd.md);
see the PRD's R5 finding.

## What to change

**One line of resolution.** `_help_dir` returns
`$nu.home-dir | path join ".config" "nushell" "help"`. `$nu.default-config-dir`
and `$nu.config-path` must not appear anywhere in the file, so a grep for
either is proof of a regression — that is what spec02's tree check asserts.

**Three raises, following `finder.nu`'s empty-decode rule and
`capsule.nu`'s missing-Dockerfile message.** Every message starts `help: `,
names the resolved path, names the fix, and names the escape hatch:

- `_help_dir` — the directory does not exist. Name the resolved path and
  `chezmoi apply`.
- `_help_topics` — `topics.nuon` is absent, or opens to something that is
  not a non-empty list. Measured: a zero-byte `topics.nuon` opens as
  `nothing`, and `help` then prints `Topics:` with nothing under it,
  `First keys:` with nothing under it, and exits **0**. That render is the
  defect R2 names, and only an explicit length check catches it.
- `_help_corpus` — a surface file is absent, or the flattened entry list is
  empty. Same reason.

`help --delegate <name>` must keep working with the corpus gone, because
clause 1 returns before any corpus read (measured: rc 0 with the corpus
renamed away). Name it in the missing-corpus message: it is the reader's way
out.

**The consequence, recorded rather than softened.** Clauses 6 and 7 read the
corpus, so a missing corpus makes `ls --help` raise instead of delegating
(measured: rc 1). That is the intended trade — a corpus that is missing is a
broken deploy, and a `--help` that quietly fell through to `std/help` would
hide it. Write the trade and its escape hatch into the header.

**The header comment.** Replace the corpus block's current text with what
was measured: the four-shape table, the `~`-literal mirror and its reason,
the no-fallback rule, the `ls --help` trade, a cross-reference to
`history.nu`'s header for `$nu.history-path` — the constant that genuinely
cannot be moved and is therefore not this file's problem — and a pointer to
`02-terminal/06-launchd-path` for the launch half. Keep it a comment: this
file stays LAYOUT ONLY, and none of this is manual content.

## Acceptance

- [x] `_help_dir` resolves through `$nu.home-dir`; `/usr/bin/grep -c` for
      `$nu.default-config-dir` and for `$nu.config-path` in `help.nu` both
      report 0. Both printed `0`, and
      `grep -n 'path join ".config" "nushell" "help"'` printed
      `140:    let dir = ($nu.home-dir | path join ".config" "nushell" "help")`.
- [x] `help` renders the full overview under `env -i` with **no**
      `XDG_CONFIG_HOME`, launched as
      `nu --config <machine>/config.nu --env-config <machine>/env.nu`: rc 0,
      empty stderr. Got `help rc=0 stderrbytes=0`.
- [x] That render is byte-identical to the same command with
      `XDG_CONFIG_HOME` exported (`cmp` reports no difference). `cmp` was
      silent and printed `IDENTICAL`; 1259 bytes each side.
- [x] `help --all | length` under the no-export launch equals the corpus's
      own entry count: `--all length: 92`, `corpus entries: 92`.
- [x] With the corpus directory renamed away, `help` exits non-zero, prints
      nothing on stdout, and the error names the resolved path, `chezmoi
      apply` and `help --delegate`. Got `missing rc=1 stdoutbytes=0` and
      `x help: the manual's corpus directory <…>/home/.config/nushell/help
      is missing — run \`chezmoi apply\`; \`help --delegate <name>\` still
      reaches nushell's own help` (nushell wraps the path across lines).
- [x] With the corpus directory renamed away, `help --delegate ls` still
      exits 0: `delegate rc=0`. `ls --help` in that state gave `rc=1` — the
      named trade, recorded in the header rather than softened.
- [x] With `topics.nuon` replaced by `[]`, `help` exits non-zero:
      `empty-topics rc=1 stdoutbytes=0`, message
      `help: the manual's spine <…>/topics.nuon holds no topics — run
      \`chezmoi apply\`; …`. A **zero-byte** `topics.nuon` gives the same
      raise (`zerobyte-topics rc=1`), not nushell's
      `incompatible_path_access`. The pre-change render is kept as the
      gate's counterfactual, where it still exits 0.
- [x] With the four surface files replaced by `[]`, `help` exits non-zero:
      `empty-surfaces rc=1 stdoutbytes=0`.
- [x] `timeit { help }` inside the configured shell stays under 100 ms:
      `5ms 417µs 542ns`. The gate's own probe agrees (`got: fast`).
- [x] `help.nu` is still defs only: no config-record write, no keybinding
      upsert, no caret-prefixed spawn, no `/Users/`, no `dot_config`. The
      caret grep printed `0`, and the gate's purity, no-spawn and
      corpus-path checks all PASS with their counterfactuals FAILing.
- [x] `bash tests/shell-help.sh` reports 0 failed:
      `CHECKS: 88 run, 88 passed, 0 failed` / `EXIT=0`.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# the resolution is the ~-literal, and neither launch-time constant survives
/usr/bin/grep -c '\$nu\.default-config-dir' home/dot_config/nushell/help.nu
/usr/bin/grep -c '\$nu\.config-path' home/dot_config/nushell/help.nu
/usr/bin/grep -n 'path join ".config" "nushell" "help"' home/dot_config/nushell/help.nu

# a machine, then the export-absent render against the export-present one
M=$(mktemp -d); mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init"
for f in env.nu config.nu dirstack.nu theme.nu pass.nu claude.nu zoxide.nu \
         history.nu capsule.nu finder.nu copymode.nu help.nu; do
  cp "home/dot_config/nushell/$f" "$M/home/.config/nushell/"
done
cp -R home/dot_config/nushell/help "$M/home/.config/nushell/help"
for p in starship zoxide television; do
  printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
done
NU=$(command -v nu)
noxdg() { /usr/bin/env -i HOME="$M/home" PATH=/usr/bin:/bin "$NU" --no-history \
  --config "$M/home/.config/nushell/config.nu" \
  --env-config "$M/home/.config/nushell/env.nu" -c "$1"; }
xdg()  { /usr/bin/env -i HOME="$M/home" XDG_CONFIG_HOME="$M/home/.config" \
  PATH=/usr/bin:/bin "$NU" --no-history \
  --config "$M/home/.config/nushell/config.nu" \
  --env-config "$M/home/.config/nushell/env.nu" -c "$1"; }
noxdg 'help' > "$M/a.txt" 2> "$M/a.err"; echo "rc=$? stderr=$(wc -c < "$M/a.err")"
xdg   'help' > "$M/b.txt"; cmp "$M/a.txt" "$M/b.txt" && echo IDENTICAL
noxdg 'help --all | length'
noxdg 'timeit { help }'

# loud failures
mv "$M/home/.config/nushell/help" "$M/home/.config/nushell/help.away"
noxdg 'help' > "$M/c.out" 2> "$M/c.err"; echo "missing rc=$? stdout=$(wc -c < "$M/c.out")"
cat "$M/c.err"
noxdg 'help --delegate ls' > /dev/null 2>&1; echo "delegate rc=$?"
mv "$M/home/.config/nushell/help.away" "$M/home/.config/nushell/help"
printf '[]\n' > "$M/home/.config/nushell/help/topics.nuon"
noxdg 'help' > /dev/null 2>&1; echo "empty-topics rc=$?"

# purity and the gate
/usr/bin/grep -cE '\^(nvim|wezterm|git|tv)' home/dot_config/nushell/help.nu
bash tests/shell-help.sh | tail -3
```
