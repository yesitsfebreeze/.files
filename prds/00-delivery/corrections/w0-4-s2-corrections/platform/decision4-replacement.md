Replacement text for open decision 4 in `.mi/prds/00-delivery/corrections/prd.md`,
drafted by W0.4f's analyst on 2026-08-21. **W0.4h (`backlog-closeout`) is the
writer** — W0.4f owns no file in the backlog and must not write there. Approved
by the user as Q1: keep decision 4's conclusion, rewrite its reasoning.

Replace the measurement paragraph's opening, clause (a), clause (b), and the
L-12 line. Clause (c) and the closing "Every inventory in `.mi/docs/` rates the
deployed artifact" sentence stand unchanged.

---

Raised by `w0-6-live-bugs`: checking L-12 surfaced what looked like two
different programs. It was a reading error. The tree measured on 2026-08-20,
`~/.local/share/chezmoi`, is **not the chezmoi source** — `chezmoi
source-path` prints `/Users/feb/dev/.files/home`, and
`~/.config/chezmoi/chezmoi.toml` sets `sourceDir = "/Users/feb/dev/.files"`.
`~/.local/share/chezmoi` is a stale checkout of the same GitHub repo
(`yesitsfebreeze/.files`), last commit 2026-06-20, whose HEAD `a2544e4` is a
git **ancestor** of the live source's `8e99f58` — two months behind, not
divergent. Measured against the live source, the divergence is zero:
`wezterm/wezterm.lua`, `nushell/config.nu`, `nushell/finder.nu` and
`nushell/theme.nu` are byte-identical to their deployed `~/.config`
counterparts. CLAUDE.md's "verify against the live config, always" still
failed, but one directory further out than the audit thought — "the live
config" resolved to whichever *clone* the reading agent opened, which is the
same failure class that invalidated `02-terminal`.

What the decision settles:
- (a) The deployed tree is canonical — and, source and deployed being the
  same content, that costs nothing. The live chezmoi source at
  `/Users/feb/dev/.files` is **not** abandoned: it is where the deployed
  config comes from, last committed 2026-08-19. No document may cite
  `~/.local/share/chezmoi` as the chezmoi source again; the only permitted
  mention is as the stale clone that produced wrong findings, labelled as
  such. (Supersedes the previous (a), "the chezmoi source is **abandoned**,
  not a port target", which was decided about the wrong tree.)
- (b) There is no 345-line source `finder.nu`. The live source's
  `finder.nu` is 221 lines and byte-identical to the deployed file, so
  `04-shell/04` is correctly specced and there is nothing to choose between.
  The 345-line stack-and-resume design exists only in the stale clone. L-5
  still stands on its own evidence: `leadermode.nu` is dead code calling
  `finder --resume`/`--fresh`, flags the deployed finder never had.
  (Supersedes the previous (b).)
- L-12 is **corrected, not confirmed**. Of its six files, five are artefacts
  of reading the stale clone: the four `solo-window.*` files are absent from
  the live source (which has zero `solo_window()` references, as does the
  deployed config — the 3 references exist only in the clone), and
  `wsl-clip-prime.sh` is in neither tree. One is real:
  `home/dot_config/wezterm/background.png` is in the live source, and is
  dropped by decision 5(a) along with the wallpaper pipeline. Recorded in
  `05-platform/01-deploy-mechanism/managed-config`.

---

## Second consequence, worth its own backlog line

Commit **`8fe3a71`** (2026-08-19, *"Simplify dotfiles: drop theme/pi/data-driven
machinery, minimal chezmoi, one plain install.sh"*, an ancestor of the live
HEAD, 2490 deletions) removed `home/.chezmoidata/packages.yaml` (214 lines),
`home/run_onchange_install-packages.sh.tmpl` (486 lines),
`home/run_once_before_install-homebrew.sh.tmpl` and `home/.chezmoiignore`,
replacing them with a flat 233-line `install.sh` at the repo root. Any node
specced from that machinery is specced from a deleted capability. Within
`05-platform` this is handled by W0.4f specs 03/04/06/07; the backlog should
carry the fact so nothing else is written against it.
