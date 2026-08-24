# spec04 — R4 + R7: one exclusion list, and it covers everything
# excluded

est: 0.75h

## Goal

`.mi/prds/README.md` is the canonical exclusion list — `SYSTEM.md` requires a
`DO NOT PORT` decision to land "in the epic's Non-goals **and** the README's
exclusion list". Two defects, both checked against the file as it stands after
three lanes edited `## Excluded` today:

- **R4 — it says it twice.** Outside `## Excluded` the file carries *two*
  statements about exclusions: the pointer at line 19 ("Items marked
  `DO NOT PORT` / `DEFER` are excluded by design (listed at the bottom so the
  decision stays visible)") and, after the tree, "Windows/PowerShell support
  was dropped from scope entirely; see the exclusion list at the end for the
  full set." The second both points at the list *and* states one of its
  entries, so Windows is excluded in two places and the tree's own rule —
  "each fact lives in exactly one file", and by extension one place in a file
  — is broken in the document that publishes the rule.
- **R7 — provisioning is missing from it.**
  [`capabilities-provisioning.md`](../../../../../../docs/capabilities-provisioning.md)
  carries three verdicts that appear nowhere in `## Excluded`: Windows config
  mirroring (`run_after_mirror-config-to-windows.sh`, `DO NOT PORT`), the
  `wp-stat-overlay` installer (`DEFER`) and the published docs site (`docs/`,
  `DEFER`). The Non-goals half is already done —
  [`05-platform/prd.md`](../../../../../05-platform/prd.md)'s `## Out of scope`
  names all three — so only the README half is open. Re-homed here from
  `w0-3-platform-rewrite` R2 by the conductor on 2026-08-21: W0.3 found it
  but does not own this file.

- **One more exclusion is owed to this list.**
  [`w0-4-s2-corrections/docs-inventories`](../../docs-inventories/prd.md)
  (W0.4a) is marking **`Cross-platform dependency bootstrap`** (
  `capabilities.md` line 79, C 5 / U 7) as `DO NOT PORT` — `conf/bootstrap.lua`
  detects the OS, installs `zoxide`/`docker` via winget/brew/curl and stamps
  `.cache/.bootstrap`. Its own spec routes the README half here by name. The
  Non-goals half is already met:
  [`05-platform/prd.md`](../../../../../05-platform/prd.md)'s `## Out of
  scope` reads "The legacy `conf/bootstrap.lua` checker and its
  `.cache/.bootstrap` stamp. Superseded; not ported." Exactly the R7 shape —
  only the README half is open. Note that the entry lives in
  `capabilities.md`, the legacy inventory, **not** in
  `capabilities-provisioning.md`, so it belongs on the legacy
  `DO NOT PORT` line beside its sibling "cross-platform Lua/shell/PowerShell
  parity", not in the new provisioning group.

One more thing to fix while inside `## Excluded`, because it is a factual
error rather than a style point: the `Retained — the tinty theme switcher`
paragraph closes with "It still owes a node: `theme.nu` has no child in
`04-shell`". It has one. `04-shell/09-theme-switcher` was created on
2026-08-21, the same day, once the tinty answer landed.

## Files touched

- `.mi/prds/README.md` — the paragraph after the tree diagram (deleted), and
  the `## Excluded` section.

### Ownership hazards, read before writing

- **Three done nodes guard this section.** Their verifies re-run, so an edit
  that trips one turns a finished ticket red. All three assertions are
  re-checked by this spec's own verify; keep them green:
  - `decisions/tinty` spec03 — `## Excluded` must still contain `Retained`,
    `tinty`, `2026-08-21`, `SIMPLIFY`, `decisions/tinty`; its `DEFER` line
    must still list `opacity picker`, `smear cursor` and `tv cable channels`;
    it must **not** contain `theme switcher (tinty`; and
    `Retained — the tinty theme switcher` may appear at most once.
  - `decisions/odin-toolchain` spec02 — `## Excluded` must contain `Odin`,
    `2026-08-21`, `per-project`, and `Odin` must appear at most twice in the
    whole file.
  - `decisions/wallpaper-opacity` spec02 — `## Excluded` must contain
    `2026-08-21`, `Ctrl+Shift+B`, `wallpaper`, `capsule --rebuild`, and
    `Ctrl+Shift+B` must appear **nowhere outside** `## Excluded`.
- Do not touch the tree diagram or the build order — spec05 owns those.
- Do not add a box to the README, and do not flip one: the tinty guard fails
  on any `- [x]` or `- [~]` line in this file.
- `.mi/SYSTEM.md` is **not** this node's file. Its `## Known gaps` and its
  `04-shell` child count are stale too; that is reported to the conductor, not
  fixed here.

## What to write

Relative links shown under **What to write** are written *into the target
file*, so they resolve from that file's directory, not from this spec's.

<!-- tree-links: target-file-vantage — the relative links in this section are
     markup written into prds/README.md, and resolve from that file's
     directory, not from this spec's. Repairing them here would falsify the
     instruction. -->

1. **Delete** the post-tree paragraph "Windows/PowerShell support was dropped
   from scope entirely; see the exclusion list at the end for the full set."
   The pointer near the top already does that job, and Windows is in the list.
   Leave the top pointer exactly as it is.
2. **Add a provisioning group to `## Excluded`**, in the same shape as the
   groups around it and cross-linking
   `../docs/capabilities-provisioning.md` and `05-platform/prd.md` rather
   than restating their reasoning:
   - `DO NOT PORT` — provisioning: Windows config mirroring
     (`run_after_mirror-config-to-windows.sh`) — the host is macOS-only, so
     the mirror has no destination.
   - `DEFER` — provisioning: the `wp-stat-overlay` installer and the
     published docs site (`docs/`).
   Put the `DEFER` pair wherever it reads best, but do **not** fold it into
   the existing `DEFER — real, but not in the minimal base` line if that
   would disturb the three keywords the tinty guard checks there.
3. **Add `cross-platform dependency bootstrap` to the legacy `DO NOT PORT`
   line**, next to `cross-platform Lua/shell/PowerShell parity`, naming
   `conf/bootstrap.lua` and giving the one-clause reason (superseded by
   `05-platform`). That line is a bare `·`-separated list with no per-item
   links, so match its shape — do not introduce a link there.
4. **Correct the tinty paragraph's closing sentence.** Replace "It still owes
   a node…" with the fact: the shell half now has a node,
   [`04-shell/09-theme-switcher`](04-shell/09-theme-switcher/prd.md) (S.9),
   created 2026-08-21; the F6 binding is still
   [`w0-2-terminal-respec`](00-delivery/corrections/w0-2-terminal-respec/prd.md)
   R5's to place. Keep the sentence in the same paragraph so the guard's
   single-occurrence count is unaffected.

## Acceptance

- [ ] Outside `## Excluded`, exactly one line in the README mentions
      exclusion at all — the pointer near the top.
- [ ] `Windows/PowerShell support was dropped from scope entirely` no longer
      appears.
- [ ] `## Excluded` names `run_after_mirror-config-to-windows.sh`,
      `wp-stat-overlay` and the published docs site.
- [ ] `## Excluded` names `bootstrap.lua`, on the legacy `DO NOT PORT` line.
- [ ] `## Excluded` links `capabilities-provisioning.md`.
- [ ] `## Excluded` no longer says the theme switcher owes a node, and names
      `04-shell/09-theme-switcher`.
- [ ] The tinty guard still passes: `Retained`, `tinty`, `2026-08-21`,
      `SIMPLIFY`, `decisions/tinty`, `opacity picker`, `smear cursor`,
      `tv cable channels` all present; `theme switcher (tinty` absent;
      `Retained — the tinty theme switcher` appears at most once.
- [ ] The odin guard still passes: `Odin`, `2026-08-21`, `per-project`
      present in `## Excluded`; `Odin` appears at most twice in the file.
- [ ] The wallpaper guard still passes: `Ctrl+Shift+B`, `wallpaper`,
      `capsule --rebuild` present in `## Excluded`, and `Ctrl+Shift+B`
      appears nowhere else in the file.
- [ ] No `- [x]` or `- [~]` box exists anywhere in the README.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; r=prds/README.md; rc=0; X() { awk "/^## Excluded/{x=1;next} /^## /{x=0} x" "$r"; }; B() { awk "/^## Excluded/{x=1} !x" "$r"; }; n=$(B | grep -ci "exclu"); [ "$n" -eq 1 ] || { echo "FAIL: $n exclusion statements outside ## Excluded, expected exactly 1"; rc=1; }; grep -qF "Windows/PowerShell support was dropped from scope entirely" "$r" && { echo "FAIL: the duplicate Windows exclusion survives"; rc=1; }; for s in "run_after_mirror-config-to-windows.sh" "wp-stat-overlay" "docs site" "capabilities-provisioning.md" "04-shell/09-theme-switcher" "bootstrap.lua"; do X | grep -qF "$s" || { echo "FAIL: ## Excluded lacks: $s"; rc=1; }; done; X | awk "/DO NOT PORT.*legacy/,/^$/" | grep -qF "bootstrap.lua" || { echo "FAIL: the bootstrap exclusion is not on the legacy DO NOT PORT line"; rc=1; }; N=$(tr "\n" " " < "$r" | tr -s " "); for s in "still owes a node" "has no child in"; do printf "%s" "$N" | grep -qF "$s" && { echo "FAIL: the theme switcher is still said to owe a node: $s"; rc=1; }; done; for s in "Retained" "tinty" "2026-08-21" "SIMPLIFY" "decisions/tinty" "opacity picker" "smear cursor" "tv cable channels" "Odin" "per-project" "Ctrl+Shift+B" "wallpaper" "capsule --rebuild"; do X | grep -qF "$s" || { echo "FAIL: a done node guard broke — ## Excluded lacks: $s"; rc=1; }; done; X | grep -qF "theme switcher (tinty" && { echo "FAIL: tinty guard — the theme switcher is deferred again"; rc=1; }; [ "$(grep -c "Retained — the tinty theme switcher" "$r")" -le 1 ] || { echo "FAIL: tinty guard — retention paragraph stated more than once"; rc=1; }; [ "$(grep -cF "Odin" "$r")" -le 2 ] || { echo "FAIL: odin guard — Odin exclusion stated more than once"; rc=1; }; [ "$(grep -cF "Ctrl+Shift+B" "$r")" -eq "$(X | grep -cF "Ctrl+Shift+B")" ] || { echo "FAIL: wallpaper guard — Ctrl+Shift+B named outside ## Excluded"; rc=1; }; grep -qE "^- \[[x~]\]" "$r" && { echo "FAIL: a README box was closed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

Proven RED before being written here — see `checks/red-spec04.txt`.
