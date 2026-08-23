# spec04 — R3: the goalpost block, proving each repointed assertion still fails against the old record

Covers **R3** for spec02 and spec03. (R1 carries its own proof in-line — see
spec01's NEGATIVE half.) Est 30m.

## Goal

R3 is the whole point of this ticket: a repaired gate must be a **moved**
goalpost, not a deleted one. spec02 changes two grep patterns and spec03
changes fifteen live predicates; on their own, nothing distinguishes that from
someone loosening a check until it passed.

So `tests/live-bugs.sh` gains one short, clearly labelled section carrying a
**verbatim excerpt of the pre-correction record**, and asserts that every
repointed check is red against it.

## Files touched

- `tests/live-bugs.sh` — one new section, placed immediately after the L-13
  block and before the final summary. Nothing above it is touched.

## Why a heredoc, and not `git show` or a fixture file

- **Not `git show HEAD:`** — `HEAD` is the pre-correction text only until
  W0.4i's rewrite is committed, at which point the proof would silently invert.
  Pinning a blob SHA fixes that but puts a git dependency inside a test whose
  header promises it only reads the live config.
- **Not a fixture file** — a new `tests/fixtures/` tree for eleven lines,
  owned by nobody, that the next reader has to go find.
- **A heredoc** is self-contained, survives a squashed history, and the
  excerpt *is* the audit trail: the reason the assertion moved sits three
  lines from the assertion that moved.

No `--selftest` mode. `gates/selftest.sh` explicitly holds scripts under
`tests/` out of that contract ("they belong to other nodes and must not be
edited"), and a `--selftest` would need a scratch tree, which this file's
header forbids ("Never writes anything, anywhere").

## The excerpt

Sixteen lines, lifted verbatim from
`git show HEAD:.mi/docs/capabilities-provisioning.md` lines 82-86, 93-94 and
96-102, with two elisions marked `  […]`. Every non-elision line was checked
with `grep -qxF` against that blob on 2026-08-21 — all sixteen matched exactly.

    PRE_CORRECTION="$(cat <<'PRE'
    - **Live bug L-12, corrected and do not reproduce:** the source tree ships
      `solo-window.{applescript,sh,ps1,vbs}`. The audit called them unreferenced;
      measured, that is only half right — the *deployed*
      `~/.config/wezterm/wezterm.lua` never mentions solo-window, but the
      *source* `home/dot_config/wezterm/wezterm.lua` defines `solo_window()` and
      […]
    - **New finding (L-13), the ground the corrections epic stands on:** the
      chezmoi source and `~/.config` have diverged, in both directions, and
      […]
      inventory in this repo was written from. Measured 2026-08-20, source vs
      deployed line counts: `wezterm/wezterm.lua` 339 vs 1149 · `nushell/config.nu`
      380 vs 715 · `nushell/finder.nu` 345 vs 221 (the source one is a different,
      stack-and-resume design) · `television/config.toml` 16 vs 15 ·
      `nvim/lua/config/keymaps.lua` identical. `leadermode.nu`, `dirstack.nu`,
      `quicklist.nu`, `overlay.nu` and `opacity.nu` exist only under `~/.config`
      and are not in the source at all. So "chezmoi-managed", written at the head
    PRE
    )"

Reproduce it with that `git show` if any line needs re-checking. Do not
reflow it — the wrap points are the file's, and rewrapping breaks the verbatim
property the first two assertions rest on.

## The seven assertions

Two prove the excerpt is real, two prove the new patterns moved, three prove
the re-expressed live checks moved:

    echo "── goalposts: what moved, and proof it moved rather than vanished ───"
    # Fixture-is-real. Without these, an empty string would "prove" everything
    # below — gates/selftest.sh's "a claimed mutation is not a made one".
    grep -qF 'Live bug L-12, corrected' <<<"$PRE_CORRECTION"
    chk "goalpost: the excerpt is genuinely the pre-correction text (old L-12 wording present)" $?
    grep -qF 'New finding (L-13)' <<<"$PRE_CORRECTION"
    chk "goalpost: the excerpt is genuinely the pre-correction text (old L-13 wording present)" $?
    # spec02: the repointed doc greps are red against the old record.
    ! grep -qF 'Live bug L-12 is corrected, not confirmed' <<<"$PRE_CORRECTION"
    chk "goalpost: the new L-12 pattern does NOT match the pre-correction text" $?
    ! grep -qF 'L-13 is corrected too' <<<"$PRE_CORRECTION"
    chk "goalpost: the new L-13 pattern does NOT match the pre-correction text" $?
    # spec03: the re-expressed live checks are red against the old reading,
    # read out of the old record itself rather than hand-typed.
    grep -qF 'the source tree ships' <<<"$PRE_CORRECTION"
    chk "goalpost: the old record says the source SHIPS solo-window.* — the re-expressed L-12 absence check is red there" $?
    grep -qF '339 vs 1149' <<<"$PRE_CORRECTION"
    chk "goalpost: the old record says 339 vs 1149 — the byte-identity check is red there" $?
    grep -qF 'and are not in the source at all' <<<"$PRE_CORRECTION"
    chk "goalpost: the old record says those five files are not in the source — the re-expressed L-13 presence check is red there" $?

All seven were run against the excerpt on 2026-08-21 and all seven are green;
the four discriminating patterns were also run against the corrected working
tree and give the opposite answer there, which is what makes them a
discrimination rather than a coincidence:

| pattern | corrected doc | excerpt |
|---|---|---|
| `Live bug L-12 is corrected, not confirmed` | HIT | miss |
| `L-13 is corrected too` | HIT | miss |
| `1149 vs 1149` | HIT | miss |
| `339 vs 1149` | miss | HIT |

**Honest limit, state it in the comment rather than overselling.** The last
three assertions prove the re-expressed live checks contradict the *old
record*. They do not re-run those checks against the clone tree, deliberately:
the acceptance line forbids any assertion in this file measuring
`~/.local/share/chezmoi`, and reading it would also make the gate depend on a
stale tree that ought to be deleted. What carries the rest of the weight for
R2b is spec03's `source: $SRC is the tree chezmoi source-path reports` guard —
the goalpost cannot move back.

## Boxes

- [x] The excerpt is verbatim: every non-`[…]` line matches
      `git show HEAD:.mi/docs/capabilities-provisioning.md` under `grep -qxF`.
- [x] Seven `goalpost:` assertions PASS.
- [x] The two fixture-is-real assertions come **first**, so an empty or
      mangled excerpt fails loudly instead of vouching for everything after it.
- [x] The section sits after the L-13 block and before the summary; no
      assertion above it is reordered.
- [x] The comment states the honest limit about the clone.
- [x] `bash tests/live-bugs.sh` exits 0.

## Verify

    bash tests/live-bugs.sh > /tmp/w08-s4.log 2>&1 && \
      [ "$(grep -cE '^PASS  goalpost: ' /tmp/w08-s4.log)" -eq 7 ] && \
      ! grep -q '^FAIL' /tmp/w08-s4.log

**Proved RED 2026-08-21** before speccing: `goalpost:` PASS count 0 of 7, and
the run exits 1 with two FAILs.
