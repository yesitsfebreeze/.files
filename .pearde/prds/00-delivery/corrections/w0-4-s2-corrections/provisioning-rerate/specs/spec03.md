verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/specs/check03.sh`

est: 40m

# spec03 — the stale-clone corrections, and the two entries `8fe3a71` invalidated

Goal: finish the file. spec01 stops it rating deleted machinery; this stops it
rating the **wrong tree**. Four corrections, none of which changes a single
C/U number.

Files: `.mi/docs/capabilities-provisioning.md` — same one file as spec01.

**Runs after spec01.** `check03.sh` re-asserts spec01's post-fold order as its
first check, so running it early reports that order failure and nothing is
gained. Order: spec01 → spec03 → spec02's record.

**Proven RED on 2026-08-21**: `bash .../specs/check03.sh` exits 1 with **32
failures** — the order guard (spec01 not yet landed), seven head assertions
plus the unlabelled-clone walker, nine on the L-12/L-13 record, eight on the
push workflow and five on `Small tool configs`.

**Everything below was measured today, in the live source, read-only.**
`chezmoi source-path` printed `/Users/feb/dev/.files/home` before and after.

## Boxes

- [x] **B1 — the head stops calling the stale clone "the chezmoi source".**
      It currently reads "the chezmoi source at `~/.local/share/chezmoi`
      (`home/` + `justfile` + `docs/`) is not a port target". Wrong tree:
      `chezmoi source-path` prints `/Users/feb/dev/.files/home` and
      `~/.config/chezmoi/chezmoi.toml` sets `sourceDir =
      "/Users/feb/dev/.files"`. `~/.local/share/chezmoi` is a stale checkout
      of the same GitHub repo, last commit 2026-06-20, whose HEAD `a2544e4`
      is a git **ancestor** of the live source's `8e99f58` — two months
      behind, not divergent. Name the live source, and name the clone as a
      clone. The check walks **every** occurrence of `~/.local/share/chezmoi`
      in the file and fails any that has no "stale" within 400 characters:
      the only permitted mention is as the stale clone that produced wrong
      findings, labelled as such (Decision 4(a), as replaced).

- [x] **B2 — but "not a port target" stays, and so do "Decision 4" and
      "canonical".** `docs-inventories`' spec03 asserts all three literal
      phrases in the head, and none of them is what Decision 4(a) supersedes.
      What (a) withdraws is "**abandoned**": the live source is not abandoned,
      it is where the deployed config comes from. "Not a port target" is a
      different claim and remains true of both trees — the sentence it lives
      in already says the capabilities below are "what `05-platform` rebuilds
      **from scratch**", which is the repo's whole premise. Keep the phrase,
      attached to the rebuild-from-scratch clause, and let the sentence say
      the live source is where the deployed tree comes from rather than that
      it is abandoned. **This is why B1 costs zero extra red assertions.**

- [x] **B3 — L-12 and L-13 are corrected in place, with their tokens kept.**
      Both records inside `## Managed config surface` are readings of the
      stale clone. Use the wording already agreed in W0.4f's
      [`decision4-replacement.md`](../../platform/decision4-replacement.md) —
      read it; it is the approved text and this box is a port of it into the
      inventory, not a fresh draft:

      - **L-13's divergence is zero.** Against the live source
        `wezterm/wezterm.lua`, `nushell/config.nu`, `nushell/finder.nu` and
        `nushell/theme.nu` are **byte-identical** to their deployed `~/.config`
        counterparts. Write the corrected figures as `1149 vs 1149`,
        `715 vs 715` and `221 vs 221` — that keeps the literal `1149` the
        neighbouring closed gate asserts while making the line true.
      - **The claims that follow from it go.** The entry must stop saying
        `chezmoi apply` "would destroy the config", and stop concluding that
        "chezmoi-managed" "is not true of the files they rate". Both were
        true only of the clone. The check fails on either string, and on the
        three old pairs `339 vs 1149`, `380 vs 715`, `345 vs 221`.
      - **L-12 is corrected, not confirmed.** Five of its six files are
        artefacts of the clone: the four `solo-window.*` files are absent
        from the live source, which has zero `solo_window()` references (the
        three references exist only in the clone), and `wsl-clip-prime.sh` is
        in neither tree. One is real — `home/dot_config/wezterm/background.png`
        — and it is dropped by decision 5(a) with the wallpaper pipeline.
      - **Keep `L-12`, `L-13`, `solo-window` and `1149` present.** Deleting
        the records would turn four more of `docs-inventories`' assertions
        red for no gain; correcting them in place keeps all four green. The
        check asserts each token still exists *and* that the corrected
        figures are there.

- [x] **B4 — `Idempotent apply + push workflow` describes the settled shape.**
      It changed twice and the entry reflects neither. Rewrite the body,
      keeping C 3 / U 9 and the entry's position:

      - `chezmoi apply` is still the single deploy step, still idempotent,
        still `command -v`-guarded so a re-apply is a no-op. That part stands.
      - `install.sh` §7 now ends in `chezmoi apply`, so the installer is
        itself a deploy path — added by `8fe3a71`.
      - `just push` is **git only** — stage, commit, push — and must not
        deploy, init or repoint anything. The cutover moved to its own named
        recipe, `just cutover`, because a recipe typed daily for its git half
        was silently repointing the machine's chezmoi source. Decided by the
        user 2026-08-21; the settled contract is
        [`repo-skeleton`](../../../../../05-platform/01-deploy-mechanism/repo-skeleton/prd.md)
        R5, and R7 is the reason it is enforced by mechanism (**`HOME` does
        not isolate chezmoi** — a scratch-`HOME` `chezmoi init --force` once
        rewrote the real `~/.config/chezmoi/chezmoi.toml`). Carry that
        constraint with its reason; it is the expensive half of the
        knowledge.
      - The old description — "one `push` recipe: init from this source,
        apply, commit, push, then `chezmoi update --force`" — is exactly the
        shape the user rejected. The check fails if it survives.
      - **`rr` stays.** It is a live daily-driver capability and neither
        `8fe3a71` nor the cutover decision touched it. The check asserts the
        bare word survives (word-boundary regex — `rr` is a substring of
        "correction", so a naive check would pass on nothing).

- [x] **B5 — `Small tool configs` reconciles with `decisions/tinty` instead
      of contradicting it.** The entry lists "`tinted-theming` (tinty state +
      artifacts)" as part of the managed surface. Measured today, that is
      the one place the two trees really do differ, and it is worth stating
      precisely rather than deleting:

      - `8fe3a71` deleted **all of** `home/dot_config/tinted-theming/` from
        the source — `tinty/config.toml`, the base16/base24 schemes, and the
        generator scripts including `executable_wezterm-colors.sh` (102
        lines). It is absent from the live source at HEAD, in git and on
        disk.
      - The deployed tree still has it: `~/.config/tinted-theming/tinty/`
        holds the schemes and generators, `tinty` is installed at
        `~/.local/bin/tinty`, and `~/.config/wezterm/colors.lua` — the
        artifact WezTerm `dofile`s — exists and is **gitignored** in the
        source.
      - So the capability is live and canonical (Decision 4: the deployed
        tree is what these inventories rate), only its chezmoi management
        lapsed. Say that. Do **not** mark it dropped: `decisions/tinty`
        settled 2026-08-21 that tinty **stays as palette owner**, and
        `05-platform/01-deploy-mechanism/managed-config` R2 deliberately
        still lists `tinted-theming` in the surface — as forward-looking
        scope, i.e. the thing the rebuild re-manages. An inventory saying
        otherwise would contradict a landed decision.
      - Cross-link both, don't restate them: the entry must name
        `decisions/tinty` and `managed-config`. The check fails if the entry
        contains `DO NOT PORT`, `DEFER` or "dropped", and fails if it does
        not name both. Rating stays **C 2 / U 7** and the entry does not
        move.

- [x] **B6 — nothing moves and nothing is re-rated.** The order was
      re-derived rather than patched, as instructed: none of B1–B5 changes a
      C or a U, so the ratio sequence is still `6 6 6 6 5 5 4 0 -1 -2` and
      the post-fold order is still spec01 B6's, tie-break included
      (`Small tool configs` before `Tool installation`, the folded entry
      inheriting its dominant source's file position). The check asserts the
      full order and re-asserts the three ratings this spec touches.

## Out of scope

- `.mi/prds/00-delivery/corrections/prd.md` — the backlog's own Decision 4
  rewrite is **W0.4h**'s, and its text is already staged at
  [`decision4-replacement.md`](../../platform/decision4-replacement.md).
  This spec ports the agreed wording into the inventory; it does not write
  the backlog.
- `.mi/prds/05-platform/**` — W0.4f's, closed. B4 and B5 cite
  `repo-skeleton` and `managed-config`; they do not edit them.
- The other inventories. `capabilities-nushell.md`, `capabilities-nvim.md`
  and `capabilities-terminal.md` may carry the same stale-clone readings —
  W0.4a's R7 swept them for the *source-vs-deployed* wording but before the
  clone was identified. Report it; it is not this file.
- The `.gitignore` comment in the live source claiming
  `home/dot_config/tinted-theming/tinty/config.toml` is "the tracked source
  config", a file `8fe3a71` deleted. Upstream's, and live sources are never
  edited as part of PRD work.
