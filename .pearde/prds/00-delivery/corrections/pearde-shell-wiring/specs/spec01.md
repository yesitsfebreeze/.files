---
complexity: 8
footprint:
  - home/dot_config/nushell/env.nu
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/manual/guide/agents.md
  - home/dot_config/nushell/help/manual/reference/agents.md
---

# spec01 — the board tool answers to `pearde` in the shell, as the person it is

`pearde install --apply` builds the skill symlinks and then prints two lines
for you to add to your shell yourself; it writes no shell file. Neither line
was in this configuration, so the board could only be driven by typing
`PEARDE_AS=engineer python3 <repo>/resources/pearde.py` in full. This unit
puts both lines into the nushell configuration in nushell's own form, and
gives the new alias the manual entry the shell's drift check requires of any
alias.

**What already stands.** Pass one built and deployed all of it, uncommitted in
the tree, and `probe/verify.sh` passes eight of eight against the live shell.
`home/dot_config/nushell/env.nu` carries `$env.PEARDE_AS = "engineer"`;
`home/dot_config/nushell/config.nu` carries the alias in the ALIASES anchor;
`help/shell.nuon` carries a `pearde [cmd]` entry at `agents` step 22, and the
two generated `manual/*/agents.md` pages were rebuilt from it with `just
manual`. `help --check` answers `clean`, `undocumented: 0`.

**What is left.** Re-run the acceptance below against the tree as you find it
and tick only what you ran — the value of these boxes is that a second run
proves it, not that pass one said so. Three things pass one deliberately did
not do, listed so they are not mistaken for oversights: the manual was not
regenerated for the whole corpus beyond the two `agents` pages the entry
touches, `chezmoi apply` was scoped to the nushell files rather than run bare
(the working tree holds unrelated pending changes, including three `*.sh`
files that would land in `$HOME` itself), and no row was added to
`why-review.nuon` — see the report's findings.

**Two traps, both measured on 2026-09-02, both load-bearing here.**

`nu -c '<code>'` loads NEITHER `env.nu` nor `config.nu`, so it reports the
alias as unknown and `PEARDE_AS` as absent even when both are correct and
deployed. Worse, it looks like it loaded: `EDITOR` and `STARSHIP_SHELL` both
answer under it, inherited from the parent process. Test with the two config
paths named explicitly, or with a detached `tmux` session running bare `nu` —
both forms are in `probe/verify.sh`.

The alias path is the SOURCE repo `~/dev/infra/pearde`, never the
`.claude/skills/pearde` symlink inside this project. Every install on this
machine is symlinks into that one repo, so a project-local path would give a
`pearde` that answers only while you stand in this directory.

## Acceptance

- [x] `home/dot_config/nushell/env.nu` sets `$env.PEARDE_AS` to `engineer`,
      and the comment above it says what reads the variable and what happens
      when it is unset
- [x] `home/dot_config/nushell/config.nu` aliases `pearde` to
      `python3 ~/dev/infra/pearde/resources/pearde.py`, in the ALIASES anchor,
      pointing at the source repo and not at any project's skills directory
- [x] `chezmoi diff` prints nothing for either file — the shell in use is
      running what the source says, not a hand-edit
- [x] a shell that loaded the config runs `pearde sweep --dry` to completion:
      the alias resolves, and the transition is not refused for a missing
      persona
- [x] a bare interactive `nu` — one nobody handed a config path to — shows the
      same two things
- [x] `help --check` exits 0 and reports `undocumented: 0`, so the new alias
      is documented rather than allowlisted; `HC_ALLOW.alias` is unchanged
- [x] `help "pearde [cmd]"` prints the entry, and its `verify` target is
      `{kind: "alias", name: "pearde"}`
- [x] the two generated pages under `help/manual/` carry the entry and were
      produced by `just manual`, not hand-edited — re-running the generator
      leaves them unchanged

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# every acceptance box above, in order, against the live shell
bash .pearde/prds/00-delivery/corrections/pearde-shell-wiring/probe/verify.sh

# the generated pages are generated: regenerating leaves them byte-identical.
# NOT `git diff --exit-code` — these pages are legitimately dirty against HEAD
# while this PRD is in flight, so that would fail on the very change it is
# meant to bless. Compare each page to itself across a regeneration instead.
snap=$(mktemp -d)
cp home/dot_config/nushell/help/manual/guide/agents.md "$snap/guide.md"
cp home/dot_config/nushell/help/manual/reference/agents.md "$snap/reference.md"
node scripts/generate-manual.mjs >/dev/null
diff "$snap/guide.md"     home/dot_config/nushell/help/manual/guide/agents.md &&
diff "$snap/reference.md" home/dot_config/nushell/help/manual/reference/agents.md &&
  echo "ok   manual pages are reproducible from shell.nuon"
rm -rf "$snap"

# the entry is reachable by name, and the allowlist was not used to hide it
nu --env-config ~/.config/nushell/env.nu --config ~/.config/nushell/config.nu \
   -c 'help "pearde [cmd]"'
grep -n 'alias: \["core-help" "core-ls"\]' home/dot_config/nushell/help-check.nu \
  && echo "ok   HC_ALLOW.alias unchanged"
```
