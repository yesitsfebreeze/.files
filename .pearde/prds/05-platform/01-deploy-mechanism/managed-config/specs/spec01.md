---
est: 1.25h
verify: "bash tests/managed-config.sh --gitconfig"
---

# spec01 — `home/dot_gitconfig.tmpl`, the one templated file

Goal: put the rebuild's git configuration into the managed tree as the single
templated file R2 allows, and prove it by *rendering* it through an isolated
chezmoi apply and interrogating the result with `git config --file` — not by
grepping the template. Today `home/dot_gitconfig.tmpl` does not exist, so the
skeleton P.1 landed deploys a nushell help tree and nothing else, and
`~/.gitconfig` on a machine deployed from this repo would be whatever was
there before.

This is real configuration: after `just cutover` this file *is* the user's
`~/.gitconfig`. Two things in it are load-bearing beyond taste and are called
out under `## Design` — the gh credential reset and `delta.syntax-theme =
ansi`.

## Files

| File | State | Note |
|---|---|---|
| `home/dot_gitconfig.tmpl` | new | the P.5 footprint in `plan.json`, exactly |
| `tests/managed-config.sh` | new | **footprint addition** — see below |

`tests/managed-config.sh` is outside the footprint `plan.json` records for
P.5. No other task claims it (checked against every `files` list in
`.mi/gantt/plan.json`; the only other `tests/` entry anywhere is E.14's
`home/dot_config/nvim/tests/`). It follows the precedent P.1 set and G.1
codified: a node-specific gate script lives in `tests/`
(`tests/deploy-skeleton.sh` is P.1's, `tests/help-content-model.nu` is
H.1's), while `gates/` holds the shared runner and library. Without it R2 is
prose and closes unproven, which is the failure mode the board was converted
to avoid.

**Read-only, never written:** `gates/lib.sh` (G.1's — sourced for the house
`chk`, `guard_begin`/`guard_end`, `lint_no_bare_chezmoi`, `gates_tmpdir`),
`tests/deploy-skeleton.sh` (P.1's, landed and gated),
`/Users/feb/dev/.files/**` (the live source), `home/.chezmoi.toml.tmpl`
(P.1's — it supplies `.name` / `.email`).

## Design

The starting point is the live source's `dot_gitconfig.tmpl`
(`/Users/feb/dev/.files/home/dot_gitconfig.tmpl`, 2977 bytes), which is
byte-identical to the deployed `~/.gitconfig` apart from the two rendered
identity lines — verified 2026-08-21 with `diff <(cat ~/.gitconfig) <(cat
…/dot_gitconfig.tmpl)`: two lines differ, `name` and `email`, and nothing
else. So there is no source-versus-deployed fork to resolve here, unlike
`wezterm.lua` and `config.nu`.

**Producing the file.** Copy
`/Users/feb/dev/.files/home/dot_gitconfig.tmpl` to
`home/dot_gitconfig.tmpl` and apply the three edits below — nothing else.
Re-typing it from memory is how a value drifts; the live file is the
reference, and the gate then proves the copy against 33 parsed keys.

Carried across **verbatim**: `[init] defaultBranch`, `[core]`,
`[interactive]`, `[delta]`, `[merge]`, `[diff]`, `[pull]`, `[push]`,
`[fetch]`, `[rebase]`, `[column]`, `[branch]`, and all 13 `[alias]` entries.

Three things change, each with its reason.

**1. The `[includeIf "gitdir:~/dev/_pi_extensions/"]` block is not carried
across.** Three independent reasons, all measured 2026-08-21:

- The directory it scopes does not exist: `ls ~/dev/_pi_extensions` →
  *No such file or directory*.
- It exists to fix auth for repos cloned by
  `run_onchange_after_install-pi.sh`, and that script is not in the live
  source any more — commit `8fe3a71` (2026-08-19) removed the pi machinery.
  The include survives as a reference to a deleted mechanism.
- Its `path` points at `~/.config/git/pi-extensions.gitconfig`, and `git` is
  not one of the nine names in R2's managed surface. Carrying the include
  means either adding a tenth directory to the surface for a dead workspace,
  or shipping a `~/.gitconfig` whose `includeIf` points at an unmanaged file
  that only exists on this one machine.

The pi surface is already `DO NOT PORT` twice over in
[`.mi/prds/README.md`](../../../../README.md) (legacy "kern local store / pi
surface index"; the capsule Odin/pi toolchain, decided 2026-08-21). Under
Decision 4 nothing is deleted from the live source and nothing is removed
from this machine — `~/.config/git/pi-extensions.gitconfig` is unmanaged and
chezmoi never removes unmanaged files, so it simply stops being included once
this `~/.gitconfig` is deployed. **If the workspace ever comes back the fix is
to re-add the two-line block and put the included file under the surface as a
declared tenth name** — recorded here so the knowledge is not lost.

**2. The credential comment is retargeted, the mechanism is not.** The live
comment says the empty `helper =` stops "Git Credential Manager's" `manager`
helper from also firing, and names Azure DevOps as the host that still wants
it. Neither applies: `git config --system credential.helper` on this machine
prints `osxkeychain`, and `git-credential-manager` is not installed. GCM was
the Windows half of a dual-platform setup that is `DO NOT PORT`. The
*mechanism* is unchanged and stays exactly as-is, because it is the expensive
part: an empty first `helper` value resets the inherited helper list **for
these two URLs only**, so the system helper cannot answer for github.com with
a token cached for a different account, and gh's *active* account wins. Every
other host still gets `osxkeychain`. This is what `gh auth setup-git` writes,
made declarative. It hard-requires `gh` on `PATH` (P.2's `install.sh`).

**3. The `autocrlf` comment loses its cross-platform hedge.** The setting
stays `input` — correct and unconditional on a macOS-only host — but the live
comment's "Linux/macOS only" framing came from the same dual-platform setup.

**Not changed, and do not "fix" it: `delta.syntax-theme = ansi`.** This is the
epic-wide palette rule in one line. `ansi` is a builtin bat/delta theme that
maps tokens onto the terminal's 16 ANSI slots, so delta's syntax highlighting
follows whatever palette tinty applied instead of a pinned gruvbox. Replacing
it with a named theme hardcodes a palette downstream of the terminal, which
the contract forbids and
[`decisions/tinty`](../../../../00-delivery/decisions/tinty/prd.md) makes
load-bearing. The gate asserts it.

`[core] pager = delta` and `[interactive] diffFilter` make **delta** a hard
runtime dependency of this file, as `gh` is. Both are in the live
`install.sh` (`git-delta`, `gh`, line 33 of the brew batch). P.2 owns that
file; this spec asserts nothing about it, but a P.2 that drops either package
breaks this one.

## The gate

`tests/managed-config.sh`, stage `--gitconfig` (stage `--surface` is
[`spec02`](spec02.md); no argument runs both). It sources `gates/lib.sh` for
the house dialect — `chk`, `guard_begin`/`guard_end`,
`lint_no_bare_chezmoi`, `gates_tmpdir` — rather than inventing a fourth
assertion dialect, and adds one local helper, `cz`, carrying the five flags.

**SAFETY, and it is not hypothetical: `HOME` does not isolate chezmoi.** A
scratch-`HOME` `chezmoi init --force` once rewrote the real
`~/.config/chezmoi/chezmoi.toml` and repointed this machine at a throwaway
repo. Every invocation goes through `cz`, which passes `--source`,
`--destination`, `--config`, `--persistent-state`, `--cache` (and
`--config-path` on `init`, which is init-only); `lint_no_bare_chezmoi` on
this file rejects a bare `chezmoi` in command position; and
`guard_begin`/`guard_end` assert the live config's hash and `chezmoi
source-path` are unchanged on exit, so a dropped flag turns the gate red on
the damage rather than on a lint. The stage renders into a scratch
destination and never into `$HOME`.

Shape: copy the repo working tree into scratch (the gate tests the files as
they are now, not as they were committed), pre-seed `[data] name/email` in the
scratch config so `promptStringOnce` never prompts (P.1's spec01 records why
`--promptDefaults` and `--promptString` are both wrong), `init`, `apply`, then
interrogate `<dest>/.gitconfig`.

**Assertions are content-based, through `git config --file`, never greps over
the template.** A grep over an ~78-column-wrapped file has produced false
negatives repeatedly on this board; `git config --file <f> --get <key>` reads
the parsed value, which is also a free proof that the rendered file is valid
git config syntax. 33 key/value pairs are asserted by table, plus the two
multi-valued credential helpers via `--get-all`.

## Acceptance

Closed 2026-08-21 by `bash tests/managed-config.sh --gitconfig` — **57 PASS /
0 FAIL, exit 0**. Every box below was ticked against that run, and every check
was additionally shown to fire: planting the user's real address turned three
red, deleting the two empty `helper =` lines turned both credential checks
red, and `syntax-theme = gruvbox-dark` turned the palette check red. All
counterfactuals ran in scratch copies of the repo.

One correction to this document's own arithmetic: the key table as built
asserts **35** parsed keys, not 33 — 23 non-alias keys (`init.defaultBranch`,
`core.pager`, `core.autocrlf`, `interactive.diffFilter`, eight `[delta]`
keys, `merge.conflictStyle`, two `[diff]` keys, `pull.rebase`, two `[push]`
keys, `fetch.prune`, two `[rebase]` keys, `column.ui`, `branch.sort`) plus the
12 single-line aliases, with `alias.lg` asserted separately as the spec says.
The box below is met as a superset; the live file has 36 non-identity keys and
every one of them is now asserted.

- [x] `home/dot_gitconfig.tmpl` exists and carries `{{ .name }}` / `{{ .email }}`,
      and no literal email address appears anywhere in it — the repo is
      published, so a baked-in identity is a leak, and a hardcoded value would
      also silently pass a render check.
- [x] An isolated `init` + `apply` with seeded template data renders
      `<dest>/.gitconfig`, it contains no unrendered `{{`, and
      `git config --file <dest>/.gitconfig --list` exits 0 (the file parses).
- [x] `user.name` and `user.email` in the rendered file equal the **seeded**
      gate values (`P5 Gate User` / `p5-gate@example.invalid`) — proving the
      identity is templated rather than constant.
- [x] All 33 asserted keys carry their live values, including
      `delta.syntax-theme = ansi`, `core.pager = delta`,
      `interactive.diffFilter = delta --color-only`,
      `merge.conflictStyle = zdiff3`, `diff.algorithm = histogram`,
      `push.autoSetupRemote = true`, `branch.sort = -committerdate` and the
      12 single-line aliases (`lg` is asserted separately, below).
- [x] `credential.https://github.com.helper` and
      `credential.https://gist.github.com.helper` each read back as exactly
      two values — an empty one, then `!gh auth git-credential` — proving the
      inherited-helper reset survived rendering, not just that the words are
      in the file.
- [x] `alias.lg`'s `--format=format:'…'` string survives rendering with its
      quoting intact (chezmoi's renderer and git's own quote handling both
      pass over it).
- [x] The rendered file contains no `includeIf` and no `_pi_extensions`, and
      `home/dot_config/git/` does not exist in the managed tree.
- [x] `bash tests/managed-config.sh --gitconfig` exits 0, and the live-config
      guard passes: `~/.config/chezmoi/chezmoi.toml` sha256 unchanged and
      `chezmoi source-path` still `/Users/feb/dev/.files/home`.

## Proven RED

A prototype of exactly these checks was run against the tree as it stands
(2026-08-21). Exit 1:

```
FAIL: gitconfig: home/dot_gitconfig.tmpl exists
PASS  gitconfig: LIVE chezmoi.toml unchanged
PASS  gitconfig: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
```

The literal `verify:` command exits 127 today
(`tests/managed-config.sh: No such file or directory`).

The same prototype against a scratch copy of the repo carrying the drafted
`home/dot_gitconfig.tmpl` printed **53 PASS / 0 FAIL for this stage**, exit 0
— so the spec is known-achievable, not hoped-for.

Two counterfactuals were **run**, not asserted. Replacing `{{ .email }}` with
the user's real address in the copy turns three checks red at once:

```
FAIL: gitconfig: user.email comes from template data
FAIL: gitconfig: no literal email address in the source template
FAIL: gitconfig: user.email = p5-gate@example.invalid (got: shadowhvlmnns@gmail.com)
```

and the whole run was bracketed by `chezmoi source-path`, which printed
`/Users/feb/dev/.files/home` before and after every execution.

## Out of scope

- The census of the managed surface itself — [`spec02`](spec02.md), same
  script, `--surface` stage.
- `install.sh` and its package list (P.2), even though `delta` and `gh` are
  hard dependencies of this file. Cross-linked, not asserted.
- `~/.config/git/ignore` (`core.excludesFile`'s default, one line,
  `**/.claude/settings.local.json`). It is deployed-only and in neither the
  live source nor R2's surface; adopting it would mean adding `git` to the
  surface, which is exactly the decision this spec declines above. Recorded
  so it is a decision rather than an oversight.
- Any per-repo or per-directory git identity. One identity, one file.
