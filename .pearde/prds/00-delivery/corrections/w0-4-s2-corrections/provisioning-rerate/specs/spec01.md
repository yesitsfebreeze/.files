verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/specs/check01.sh`

est: 35m

# spec01 — fold three dead entries into `## Tool installation (install.sh)`

Goal: R1, R2, R3 and R5. `.mi/docs/capabilities-provisioning.md` stops rating
machinery commit `8fe3a71` deleted, and starts rating the script that replaced
it, at the rating the user set.

Files: `.mi/docs/capabilities-provisioning.md` — and nothing else. That is
W0.4i's entire `files` list in `plan.json`.

**Proven RED on 2026-08-21** against the current tree: `bash
.../specs/check01.sh` exits 1 with **12 failures** — entry count 12, the
post-fold order, the three folded entries still standing, `Tool installation`
missing, the exact heading line missing, the Neovim entry not naming
`install.sh` or `nvim --version`, the burrito bullet's two stale claims, and
`05-platform/02-package-provisioning`'s source citation resolving to no
heading. Everything the check guards rather than drives is already green:
the ratio-descending rule, the six surviving C/U pairs, the L-12 / L-13 /
solo-window / 1149 records, the Decision 4 head note, and every relative
link. It must still be green after.

**Measured against the live file, not the summary.** `install.sh` was read in
full at `/Users/feb/dev/.files/install.sh` (233 lines, `wc -l`), `8fe3a71`'s
diffstat was read with `git show --stat`, `home/.chezmoidata/` was confirmed
absent, and `chezmoi source-path` was confirmed to print
`/Users/feb/dev/.files/home` before and after. Read-only throughout.

## Boxes

- [x] **B1 — the three entries are deleted, whole.** `## Declarative package
      set (`.chezmoidata/packages.yaml`)` (C 2 / U 9, currently first),
      `## Homebrew bootstrap (`run_once_before_install-homebrew.sh.tmpl`)`
      (C 2 / U 8, currently fourth) and `## Package installer
      (`run_onchange_install-packages.sh.tmpl`)` (C 8 / U 9, currently ninth)
      go, together with their `----` separators. Every one of them rates a
      file that no longer exists — verified: `home/.chezmoidata/` is not a
      directory in the live source, and `home/` holds exactly one `run_`
      script, `run_after_generate-shell-init.sh`.

- [x] **B2 — one entry replaces them, at C 4 · U 9.** The heading is exactly
      `## Tool installation (install.sh)` — no backticks, no verdict marker.
      The literal string matters: `05-platform/02-package-provisioning`'s
      `Parent:` line cites `"Tool installation (install.sh)"` as its dominant
      source, and a citation that does not grep back to a heading is the
      `maximiz:ed` defect that dangled `02-terminal/02-startup-layout` for a
      month. The check re-reads that PRD and greps the cited string back.

      The body must describe what the script actually does, in three
      mechanisms. Suggested text — reword freely, but every fact below was
      measured and the check asserts the load-bearing ones:

      > - One script installs every tool the other epics assume:
      >   `install.sh`, 233 lines at the root of the chezmoi repo
      >   (`/Users/feb/dev/.files`, whose `home/` is what `chezmoi
      >   source-path` prints). Idempotent and non-fatal by construction:
      >   every step is `command -v`-guarded, so a re-run on a provisioned
      >   machine is a no-op, and every failure path calls `warn` and
      >   continues, so a partial machine beats an aborted one.
      > - **1 — package-manager batch install.** macOS bootstraps Homebrew
      >   itself when `brew` is missing (the official installer under
      >   `NONINTERACTIVE=1`, then `eval "$(brew shellenv)"` because the new
      >   brew is not yet on PATH), then runs one `brew install` list plus a
      >   nerd-font cask. Linux takes apt, pacman or dnf, whichever exists,
      >   and warns rather than failing when none does. Debian names two
      >   tools differently, so `batcat` and `fdfind` are symlinked into
      >   `~/.local/bin` as `bat` and `fd`; `build-essential` / `base-devel`
      >   is pulled in when `make` is missing, because lazy.nvim `build`
      >   steps and cargo need it.
      > - **2 — a GitHub-release ladder for what the distros do not carry.**
      >   `latest_tag()` reads `tag_name` from the releases API and
      >   `fetch_release()` downloads, extracts and installs one named
      >   binary into `~/.local/bin`, skipping when it is already on PATH.
      >   It covers `kern` on both platforms and, on Linux only, `wt`, `tv`,
      >   `gh`, `nu`, `lazygit`, `starship` and `delta` — macOS gets all of
      >   those from brew.
      > - **3 — a few source builds.** `cargo install --git` for `keydr`, a
      >   shallow clone plus `just install` for burrito, and nvm +
      >   `npm install -g` for the pi coding agent and its extensions.
      > - **4** *(the rating bullets)* `- 4` then `- 9`.

- [x] **B3 — the entry names its three sources with their own numbers.** The
      contract's merged-entry rule: an entry that merges several carries the
      dominant rating and lists every source. Name `Package installer`
      (C 8 / U 9), `Declarative package set` (C 2 / U 9) and `Homebrew
      bootstrap` (C 2 / U 8), in that `C n / U n` notation — the check
      matches the notation, whitespace-normalised, so wrapping is free.

- [x] **B4 — the entry records the deletion, so nobody restores it (R3).**
      In the same paragraph: commit `8fe3a71`, committer date **2026-08-19**,
      *"Simplify dotfiles: drop theme/pi/data-driven machinery, minimal
      chezmoi, one plain install.sh"*, **2490** deletions; it removed the
      214-line `.chezmoidata/packages.yaml`, the 486-line `run_onchange`
      installer template (559 lines rendered) and the `run_once_before`
      Homebrew template, and the **sha256** re-run gate with them. Say in
      words that they are not to be **restored** from this inventory. Then
      the rating itself: **re-rated 2026-08-21, C 8 → C 4**; U stays 9
      because every epic still depends on its tools existing, C falls to 4
      because what is rated is a guarded shell script with three mechanisms,
      not a 559-line template rendering a YAML model behind a sha256 gate.

- [x] **B5 — burrito is flagged where the script builds it.** Mechanism 3
      names a burrito build (`git clone` + `just install`, `install.sh`
      lines 155–165 as measured). Say in the same bullet that burrito is
      `DO NOT PORT`, decided 2026-08-20 — the live script still builds it and
      the rebuild does not. Without that clause this entry is the one place
      in the tree that reads as an instruction to install burrito, which is
      exactly the restore-from-the-inventory failure R3 is about.

- [x] **B6 — the new entry sits sixth, and nothing else moves.** Post-fold
      ratios are `6 6 6 6 5 5 4 0 -1 -2`, giving:

      6  Shell-init generation (`run_after_generate-shell-init.sh`)
      6  Idempotent apply + push workflow
      6  Managed config surface (`home/dot_config/`)
      6  Starship prompt
      5  Small tool configs
      5  Tool installation (install.sh)
      4  Neovim version gating
      0  Published docs site (`docs/`)  DEFER
      -1 wp-stat-overlay installer  DEFER
      -2 Windows config mirroring (…)  DO NOT PORT

      The one tie that needs deciding is `Small tool configs` (5) against the
      new entry (5). It breaks the way R6 broke every other tie in this file
      — by existing file order — with the folded entry inheriting the
      position of its **dominant** source, `Package installer` at position 9,
      which sat below `Small tool configs` at position 7. So the new entry
      goes after `Small tool configs` and before `Neovim version gating`.
      The payoff is that **every surviving entry keeps its relative order**:
      nothing outside the fold moves, which is this ticket's third
      acceptance box. Do not "promote" the new entry above `Small tool
      configs` because it feels more important — the sort key is the ratio,
      and importance is already spent on U 9.

- [x] **B7 — `Neovim version gating` stays its own entry at 4 / 8, pointed at
      `install.sh` (R2).** Do not re-rate it and do not move it. Its body
      currently says "The installer overrides the package version…", naming
      a template that no longer exists. Repoint it at what does, keeping the
      whole hard-won why — apt/dnf ship 0.9.x, nvim-lspconfig needs 0.11.3+,
      `vim.lsp.enable` and blink.cmp expect 0.11+. Measured mechanism, from
      `install.sh` lines 127–145: it parses `nvim --version` for the minor
      number, and when nvim is missing or the minor is `< 11` it installs the
      official release tarball into `~/.local/opt/neovim` and symlinks it
      into `~/.local/bin`. Linux only; macOS gets a current one from brew.
      Worth one clause: this capability **survived** `8fe3a71` — only its
      host moved. The check fails if the entry still names `run_onchange`,
      `run_once_before` or a `.tmpl`.

- [x] **B8 — the burrito bullet in `Managed config surface` stops asserting
      deleted machinery is live.** It currently reads that the source
      "carries it in two places — `home/dot_config/burrito/burrito.toml` and
      a `burrito` `cargo_git` entry in `home/.chezmoidata/packages.yaml`,
      both verified live 2026-08-21". Measured today: the config dir is
      there, `home/.chezmoidata/` is **not** — `8fe3a71` took it. That makes
      this the file's second entry naming deleted machinery as present,
      which the first acceptance box forbids. Correct it in place: the config
      dir is still live, the `cargo_git` entry went with the rest of
      `packages.yaml` in `8fe3a71`, and `install.sh` §3 builds burrito from a
      git clone instead — so neither carries into the rebuilt surface.

      **Keep the word `packages.yaml` in the bullet.** `docs-inventories`'
      spec03 asserts that literal string inside this section, along with
      `burrito`, `DO NOT PORT` and `2026-08-20`; a correction that names what
      the entry *was* keeps all four green while making the sentence true.
      This is a repair, not a re-rate: the entry stays C 3 / U 9 and stays
      third. Do not touch the L-12, L-13, `solo-window` or `1149` records in
      the same entry — the check guards every one of them, and their own
      correction (they were measured against a stale June clone) belongs to
      whoever the orchestrator routes it to, not here.

- [x] **B9 — R5 needs no PRD edit, and the check proves it rather than
      assuming it.** Every `Parent:` block under `.mi/prds/05-platform` that
      cites `capabilities-provisioning.md` was read: `01-deploy-mechanism`
      cites "Idempotent apply + push workflow" and "Managed config surface",
      `03-shell-init-generation` cites "Shell-init generation", and
      `02-package-provisioning` already cites "Tool installation
      (install.sh)" (C4 U9) and "Neovim version gating" (C4 U8) — the
      platform lane landed that minutes before this node was created. The
      three grandchildren cite requirement numbers, not inventory entries.
      So no header names a folded entry, and the only broken citation is the
      one B2 repairs. The check walks all of them: it fails on any
      `05-platform` citation of a folded name, and on any cited string that
      matches no `##` heading. Leave `.mi/prds/05-platform/**` untouched —
      it is W0.4f's footprint, and W0.4f is `done`.

## Out of scope

- `.mi/prds/05-platform/**` — W0.4f's, and already correct (B9).
- The PRD-side re-spec of `02-package-provisioning` — W0.4f's, landed.
- Any other entry's wording, and every rating in the file. `Idempotent apply
  + push workflow`, `Small tool configs`, the head's `~/.local/share/chezmoi`
  source path and the L-12 / L-13 measurements are all
  [`spec03`](spec03.md)'s, in the same file and the same ticket — run spec01
  first, then spec03, then spec02's record. Nothing outside those two specs
  changes, and no C or U in this file moves except the folded entry's own.
