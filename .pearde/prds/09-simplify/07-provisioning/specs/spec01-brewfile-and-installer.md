---
complexity: 14
footprint:
  - Brewfile
  - install.sh
---

# spec01 — a Brewfile, and install.sh at 78 lines

The package set moves out of `install.sh` into a `Brewfile` at the repo root,
and `install.sh` shrinks from 493 lines to 78: bootstrap Homebrew, trust the
tinted tap, `brew bundle install`, fetch `tmux-mcp`, clone the two tmux
plugins, `chezmoi apply` last.

**Already stands** (built and verified 2026-09-02): both files are written and
the verify below passes on three consecutive runs. What is left is landing
them — and reading the two decisions inside them, because each was forced by
something the build hit rather than chosen.

**Decision 1 — `brew trust --tap tinted-theming/tinted` is a line, not a
nicety.** Homebrew 6.0.21 refuses to load a formula from an untrusted
third-party tap, `brew bundle` will not trust one for you, and it does not
fail the run — it prints `Refusing to load formula … from untrusted tap` and
carries on. Without that line a fresh machine finishes green with no tinty,
and tinty owns the palette every other tool inherits. Trust lives in
`~/.homebrew/trust.json`, which is machine state, so every machine needs it.

**Decision 2 — `rust` stays in the Brewfile.** R1 offered to drop it if
`rustfmt` was its only reason. It is its only reason and the reason holds:
`lua/plugins/conform.lua` still names `rustfmt` for rust files, and
`internals/neovim.md` records that a configured-but-absent formatter is
*silent* behind `lsp_format = "fallback"` — the language server formats the
buffer and nothing says rustfmt did not run. `rustfmt` has no formula of its
own; it ships with `rust`.

**What moved off the release rung.** `tinty` now comes from the tap, so
`install.sh` no longer fetches it — and the release-rung copy at
`~/.local/bin/tinty` had to be deleted, because `~/.local/bin` is ahead of the
Homebrew prefix on PATH and the stale binary would have won forever. Homebrew
said so itself at install time (`tinty (shadowed by …)`). Done on this machine
2026-09-02; nothing needs to do it on a fresh one, which never had the copy.
`tmux-mcp` is now the only tool left on the release rung.

## Acceptance

- [x] `Brewfile` lists 28 entries — one tap, 26 formulae, one cask — and every
      name resolves against Homebrew. `verify.sh` 2026-09-02:
      `ok Brewfile lists 28 entries` / `ok every formula resolves` /
      `ok every cask resolves`
- [x] `tinted-theming/tinted/tinty` is one of them, and `rust` is another.
      `Brewfile:11` `brew "tinted-theming/tinted/tinty"`, `:18` `brew "rust"`
- [x] `install.sh` is at most 80 lines and `bash -n` parses it —
      `ok install.sh is 78 lines` / `ok install.sh parses`
- [x] `install.sh` runs `brew trust --tap tinted-theming/tinted` before
      `brew bundle install --file Brewfile` — `install.sh:31` then `:32`;
      `ok install.sh trusts the tinted tap`
- [x] the last thing `install.sh` does is `chezmoi apply`, after the bundle —
      `ok chezmoi apply comes after brew bundle` (`:73`, last block before
      `exit 0`)
- [x] `install.sh` names no deleted test, gate, `INSTALL_DRY` seam or
      `MASON_SEED` — `ok no deleted-test or seam citations` (the `rg`, negated
      with `!`, matches nothing)
- [x] `/opt/homebrew/bin/tinty` exists and `~/.local/bin/tinty` does not —
      `ok brew owns tinty` / `ok no ~/.local/bin/tinty shadow`;
      `command -v tinty` → `/opt/homebrew/bin/tinty`

## Verify and Proof

```sh
bash .pearde/prds/09-simplify/07-provisioning/probe/verify.sh
```

Asserts post-state only, and passes on a re-run: no `git add`, no
`git commit`, and no `grep -c` (which exits 1 on a count of zero — and zero is
what success looks like for a deletion). The one grep for an absence is
negated with `!` for the same reason.

**Do not put `brew bundle check --file Brewfile` in a verify block.** The PRD's
first acceptance line asked for it and it is the wrong check: it reports the
machine, not the Brewfile. Measured 2026-09-02, it is red here for four
reasons this change does not own — `gh` and `gnupg` merely outdated, `docker`
unable to link because Docker Desktop owns
`/opt/homebrew/etc/bash_completion.d/docker`, and the CaskaydiaCove fonts in
`~/Library/Fonts` differing byte-wise from the cask's own 3.5.1 so that even
`--adopt` refuses them. Outdated recurs upstream on its own, so the check
would go red again for nothing. `brew bundle list --file Brewfile --all` plus
`brew info` over the names is the check on the *file*, and it is what the
verify runs.
