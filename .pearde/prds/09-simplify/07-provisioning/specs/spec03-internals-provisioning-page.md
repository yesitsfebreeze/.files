---
complexity: 6
footprint:
  - home/dot_config/nushell/help/manual/internals/provisioning.md
  - home/dot_config/nushell/help/manual/internals/index.md
  - home/dot_config/nushell/help/manual/internals/neovim.md
---

# spec03 — the manual gains a provisioning page and loses a stale citation

R6 asked for "the `internals/` page that describes provisioning". There was
none — `internals/` held eight pages and provisioning was not among them, so
the page is net-new rather than edited. It opens on `brew bundle` then
`chezmoi apply` and names no wave and no gate.

**Already stands** (built, deployed and verified 2026-09-02): the page is
written, linked from `internals/index.md`, and `chezmoi apply` has put it at
`~/.config/nushell/help/manual/internals/provisioning.md`, where `?` greps it.

What it carries, all of it measured during this build rather than copied:

- The Homebrew tap-trust refusal, with the error text, and why the line in
  `install.sh` is load-bearing.
- Why a release-rung binary in `~/.local/bin` outlives the reason for it, with
  Homebrew's own `shadowed by` warning as the evidence.
- Why `brew bundle check` reports the machine and not the Brewfile, and what
  to run instead for each.
- The three shell-init constraints that used to be a 40-line header in
  `run_after_generate-shell-init.sh`: the literal cache path and why nushell's
  parse-time `source` forbids `XDG_CACHE_HOME`; PATH order following the shell
  rather than the installer; and the explicit `exit 0` that keeps a missing
  tool from killing the whole apply.
- The `~/.claude.json` destination, `env -u CLAUDE_CONFIG_DIR`, and the
  absolute path, from `run_after_register-mcp.sh`.

**The stale citation this change created.** `internals/neovim.md` cited
`install.sh`'s `PKGS` array three times as the reason git, the four formatters
and the Nerd Font are present. `PKGS` no longer exists, so those three lines
now point at nothing and were repointed at the `Brewfile`. Found by grepping
the tree for the identifiers before cutting them, not afterwards.

## Acceptance

- [x] `internals/provisioning.md` exists, says `brew bundle` then
      `chezmoi apply`, and matches neither "wave" nor "gate" — 104 lines,
      `ok the internals page says brew bundle` /
      `ok the internals page names no wave or gate`
- [x] `internals/index.md` links it — `:21`
      `- [Provisioning](./provisioning.md) — \`brew bundle\` then \`chezmoi apply\`…`
- [x] no page under `internals/` still cites `install.sh`'s `PKGS` —
      `grep -rn 'PKGS' --glob '!.git' .` over the whole tree returns nothing
- [x] the page is deployed at
      `~/.config/nushell/help/manual/internals/provisioning.md` —
      `ok the page is deployed`; `ls -l` 5148 bytes, and `chezmoi status`
      leaves no file target pending

## Verify and Proof

```sh
bash .pearde/prds/09-simplify/07-provisioning/probe/verify.sh
```

Deploy it with a **scoped** apply and never a bare one:

```sh
chezmoi apply ~/.config/nushell/help/manual/internals
```

Three `run_after` scripts render as pending run-targets in this tree — the
mason seeder among them, which this PRD does not own. A bare `chezmoi apply`
runs all three.

`help --check` is deliberately not in this spec's verify: the command does not
exist. `home/dot_config/nushell/help-check.nu` was deleted in this same
working tree by the concurrent `09-simplify/03-help-system` pass, so the drift
check that would normally guard a new manual page cannot be run today. Noted
in the report, not worked around here.
