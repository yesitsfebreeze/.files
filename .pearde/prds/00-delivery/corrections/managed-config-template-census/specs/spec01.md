---
est: 0.75h
footprint:
  - tests/managed-config.sh
verify: "bash tests/managed-config.sh && bash tests/managed-config.sh --selftest"
---

# spec01 — the census names its templates instead of counting to one

Turn the two template clauses of the `--surface` census into a **named set**.
A declared list at the top of `tests/managed-config.sh` names every deployed
template with the reason it is one; the census fails on any `*.tmpl` that is
not in the list, at any depth. A counterfactual stage proves the census still
goes red on an unnamed template, so admitting `theme.toml.tmpl` does not buy
the pass by loosening the check.

Measured before the change, `bash tests/managed-config.sh` on the tree as it
stands: **2 red checks**, both in `--surface`, exit 1.

```
FAIL  surface: exactly one deployed template, dot_gitconfig.tmpl (got: dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl)
FAIL  surface: no template under home/dot_config/
```

Everything else in the file is green — the whole `--gitconfig` stage, census
checks 1–4, and the real-user-path guard.

## Design

**One list, and editing it IS the decision.** It sits beside `SURFACE` /
`SURFACE_PENDING` / `HOME_TOP` at the top of the script, in the same dialect,
carrying one comment line per entry. Paths are relative to `home/`, `LC_ALL=C`
sorted, so the list compares directly against `find | LC_ALL=C sort` output.

```
TEMPLATES="dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl"
```

The comment above it carries both reasons, because a template is the
exception this census exists to police:

- `dot_gitconfig.tmpl` — per-machine identity, `{{ .name }}` / `{{ .email }}`.
- `dot_config/television/cable/theme.toml.tmpl` — S.9: television hands the
  channel's `command` to `$SHELL`, and an absolute `{{ .chezmoi.homeDir }}`
  path is the one form that runs identically under nu, bash and sh. Recorded
  in [`04-shell/09-theme-switcher`](../../../../04-shell/09-theme-switcher/specs/spec03-tv-channel.md).

**Check 5 becomes set equality against `TEMPLATES`.** It stays
bidirectional: both named templates exist on disk today, so a named template
that disappears is a real regression and must be red. The `.chezmoi*` and
`run_*` exclusions stay exactly as they are — chezmoi metadata and chezmoi
scripts are not deploy targets.

**Check 6 becomes the named-exception form.** It walks `*.tmpl` under
`home/dot_config/`, skips the entries `TEMPLATES` names, and fails naming
whatever is left. Its label says so, so the next agent finds the list from the
FAIL line alone. Do not replace it with a per-directory allowance
(`television/**.tmpl` and friends) — the premise being kept is that each
template is named, not that some directories may template freely.

**Both checks go through one function, `templates_ok <home-dir>`**, so the
counterfactual runs the same code as the census. The house reason for that
shape is in `gates/lib.sh` beside `chk_ok`/`chk_fail`, and
`tests/shell-television.sh` and `tests/nvim-completion.sh` are the precedents.

**New stage `--selftest`**, in the contract shape `gates/selftest.sh`
defines, both halves:

- RED — `scratch_tree` a copy, plant `home/dot_config/foo/bar.tmpl`, print the
  `MUTATION:` and `MUTATION HOST:` lines, and `chk_fail templates_ok` on the
  copy.
- GREEN — the same unmutated copy, `chk_ok templates_ok`. A gate that only
  proves it can fail has not proved it can pass.

The scratch root comes from `gates_tmpdir`, which cleans itself up on exit.
The real tree is never mutated. `--selftest` is additive: `--gitconfig`,
`--surface` and the no-argument `--all` behave as they do today, so
`gates/waves.tsv`, which runs this file with no argument, is untouched.

Two constraints carried from the file's own comments, both already paid for:
no `case` inside a command substitution (macOS bash 3.2 mis-parses it and
swallows the rest of the block), and no `chezmoi` in command position outside
`cz` (`lint_no_bare_chezmoi` rejects it).

## Acceptance

- [x] `tests/managed-config.sh` declares `TEMPLATES` with both paths, and the
      comment above it gives the television entry S.9's absolute-path reason.
      Line 93: `TEMPLATES="dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl"`,
      commented "S.9: television hands the channel's `command` to $SHELL, and
      an absolute {{ .chezmoi.homeDir }} path is the one form that runs
      identically under nu, bash and sh."
- [x] Check 5 compares the `*.tmpl` census against `TEMPLATES`; check 6 fails
      only on a template `TEMPLATES` does not name, and its FAIL message names
      the offender. Both go through `tmpl_census` / `templates_ok`. The
      offender is named:
      `FAIL  surface: every template under home/dot_config/ is named in TEMPLATES (unnamed: dot_config/foo/bar.tmpl)`
- [x] `bash tests/managed-config.sh --surface` exits 0 with 0 FAIL.
      `SURFACE EXIT=0`, `grep -c '^FAIL'` = `0`:

      ```
      PASS  surface: home/ holds only declared entries (undeclared: <none>)
      PASS  surface: home/dot_config/ holds only declared tools (undeclared: <none>)
      PASS  surface: no DO NOT PORT / dropped artefact under home/ (found: <none>)
      PASS  surface: each declared tool has exactly one path under home/ (dupes: <none>)
      PASS  surface: deployed templates are exactly the TEMPLATES set (want: dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl / got: dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl)
      PASS  surface: every template under home/dot_config/ is named in TEMPLATES (unnamed: <none>)
      ```
- [x] `bash tests/managed-config.sh` exits 0 with 0 FAIL. `ALL EXIT=0`,
      65 PASS, 0 FAIL, summary line:
      `PASS — the managed surface is the declared surface, and the live chezmoi config was never touched`
- [x] `bash tests/managed-config.sh --selftest` exits 0, both halves:

      ```
      ── stage --selftest: the template census still has teeth ────────────
            MUTATION HOST: /var/folders/_p/.../T//gates.E2egM6/managed-config (a scratch_tree copy; the real tree is never written)
            MUTATION: planted home/dot_config/foo/bar.tmpl in the copy
      PASS  selftest red: an unnamed home/dot_config/foo/bar.tmpl turns the census red
            mutated copy: unnamed under dot_config/ = dot_config/foo/bar.tmpl
            MUTATION: removed the planted template again (the green counterfactual)
      PASS  selftest green: the unmutated copy passes the census
            unmutated copy: found = dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl
      PASS  selftest: the real home/dot_config/foo was never created
      SELFTEST EXIT=0
      ```
- [x] Deleting `dot_config/television/cable/theme.toml.tmpl` from `TEMPLATES`
      in a scratch copy turns check 5 and check 6 red again — the admission is
      one list entry, not a loosened check:

      ```
      FAIL  surface: deployed templates are exactly the TEMPLATES set (want: dot_gitconfig.tmpl / got: dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl)
      FAIL  surface: every template under home/dot_config/ is named in TEMPLATES (unnamed: dot_config/television/cable/theme.toml.tmpl)
      EXIT=1
      ```

      And the mirror direction, proving check 5 is bidirectional: with
      `TEMPLATES` restored and the template file itself removed from the
      scratch copy,
      `FAIL  surface: deployed templates are exactly the TEMPLATES set (want: dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl / got: dot_gitconfig.tmpl)`
- [x] The run mutated no real path.
      `PASS  the gate touched no REAL user path (~/.cache/{nushell,starship,television}, ~/.zoxide.nu, ~/.config/{nushell/help,television}, ~/.gitconfig)`,
      `test ! -e home/dot_config/foo` → `no real home/dot_config/foo`, and
      `PASS  lint: no bare chezmoi in command position in managed-config.sh`.

## Verify and Proof

```sh
bash tests/managed-config.sh
bash tests/managed-config.sh --selftest
bash tests/managed-config.sh --surface
test ! -e home/dot_config/foo
```
