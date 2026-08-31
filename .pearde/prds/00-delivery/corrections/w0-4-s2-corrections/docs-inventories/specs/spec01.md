verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=docs/capabilities-nushell.md; rc=0; RAT() { awk "/^## /{h=\$0; sub(/^## /,\"\",h); n=0} /^- [0-9]+\$/{v[n++]=\$2} /^----/{if(n>=2) printf \"%d\t%s\n\", v[n-1]-v[n-2], h}" "$f"; }; SEC() { awk -v H="$1" "index(\$0,\"## \"H)==1{s=1;next} s&&/^## /{exit} s" "$f" | tr "\n" " " | tr -s " "; }; NUM() { awk -v H="$1" "index(\$0,\"## \"H)==1{s=1;next} s&&/^## /{exit} s&&/^- [0-9]+\$/{print \$2}" "$f" | tr "\n" " "; }; RAT | awk -F"\t" "NR>1 && \$1>p {printf \"FAIL: ratio rise — %s (%d) sits below (%d)\n\", \$2, \$1, p; r=1} {p=\$1} END{exit r+0}" || rc=1; [ "$(RAT | wc -l | tr -d " ")" = "14" ] || { echo "FAIL: entry count is not 14 (got $(RAT | wc -l | tr -d " "))"; rc=1; }; HEAD=$(awk "/^## /{exit} {print}" "$f" | tr "\n" " " | tr -s " "); echo "$HEAD" | grep -qF "(chezmoi-managed)" && { echo "FAIL: head still calls the deployed nushell tree chezmoi-managed"; rc=1; }; for s in "deployed" "canonical" "Decision 4" "dirstack.nu" "quicklist.nu" "leadermode.nu" "overlay.nu" "opacity.nu"; do echo "$HEAD" | grep -qF "$s" || { echo "FAIL: head lacks: $s"; rc=1; }; done; A=$(SEC "Aliases and small utilities"); echo "$A" | grep -qF "(burrito sessions)" && { echo "FAIL: bb/ba still listed as a ported alias"; rc=1; }; for s in "brr" "DO NOT PORT" "2026-08-20" "M-7"; do echo "$A" | grep -qF "$s" || { echo "FAIL: aliases entry lacks the bb/ba exclusion note part: $s"; rc=1; }; done; [ "$(NUM "Aliases and small utilities")" = "2 8 " ] || { echo "FAIL: aliases entry re-rated (04-shell/02 cites C 2 / U 8); got $(NUM "Aliases and small utilities")"; rc=1; }; L=$(SEC "Leader mode"); echo "$L" | grep -qF "needs to name one of them" && { echo "FAIL: leader-mode entry still leaves the deployed-vs-source question open"; rc=1; }; echo "$L" | grep -qF "Decision 4" || { echo "FAIL: leader-mode entry does not cite Decision 4"; rc=1; }; T=$(SEC "Theme switcher (tinty + television)"); echo "$T" | grep -qF "stays as palette owner" || { echo "FAIL: the tinty decision record was disturbed"; rc=1; }; grep -qF "## Theme switcher (tinty + television)  SIMPLIFY" "$f" || { echo "FAIL: theme switcher lost its SIMPLIFY marker"; rc=1; }; [ "$(NUM "Theme switcher (tinty + television)")" = "8 5 " ] || { echo "FAIL: theme switcher re-rated; the tinty decision moved the marker, not the numbers"; rc=1; }; for e in "Dirstack" "Television finder stack" "Quicklist"; do SEC "$e" | grep -qF "do not reproduce" || { echo "FAIL: the live-bug note in \"$e\" was lost"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 20m

# spec01 — `capabilities-nushell.md`: sort, burrito strip, canonicality

Goal: land R3's nushell half, R5's nushell half, and R7's only in-footprint
target in one pass over one file.

Files: `.mi/docs/capabilities-nushell.md` — and nothing else. `capabilities.md`
is blocked by R1 and is not touched here.

**The verify was proven RED on 2026-08-21** against the current file: it
reports the opacity rise, the four missing head assertions, the four missing
bb/ba assertions and the two leader-mode assertions — twelve failures — while
the guard assertions (14 entries, theme switcher still `SIMPLIFY` at 8 / 5,
aliases still 2 / 8, the three live-bug notes) already pass, so a green run
means the corrections landed and nothing else moved.

## What is wrong now

Ratios in file order are `6 6 5 4 3 3 1 1 0 -1 -3 0 -4 -6`. The single
violation is **Opacity picker** (C 3 / U 3, ratio 0) sitting below Claude
launchers (−1) and Theme switcher (−3). Everything else is already descending.

## Boxes

- [ ] **B1 — the sort violation is gone.** Move the whole `## Opacity picker
      DEFER` entry (heading, its bullets, its `- 3` / `- 3`, its `----`) so it
      sits immediately **after** `## Quicklist — cross-channel recents` and
      immediately **before** `## Claude launchers  SIMPLIFY`. Tie-break is
      existing file order, so Quicklist (also ratio 0) stays above it. Move
      the text verbatim; do not re-word or re-rate it.
- [ ] **B2 — no entry is lost or re-rated by the move.** The file still holds
      14 entries and every C/U pair is byte-identical to before.
- [ ] **B3 — `bb`/`ba` stop reading as ported.** Remove `` `bb`/`ba` (burrito
      sessions), `` from the alias list in `## Aliases and small utilities`,
      and add a second bullet to that entry recording the exclusion instead of
      silently deleting it. The bullet must carry all four facts a reader
      needs: that the live `config.nu` defines `alias bb = brr` and
      `alias ba = brr --attach`; that they invoke **`brr`**, not `burrito`
      (M-7 — both binaries exist, so a search for "burrito" misses them);
      that burrito is `DO NOT PORT`, decided **2026-08-20**, because it is no
      longer used and WezTerm's nine-tab floor owns panes and tabs; and that
      the `burrito-sessions` television channel comes out with them.
- [ ] **B4 — the aliases entry keeps C 2 / U 8.** Two aliases out of eleven do
      not move a 1–10 rating, and `04-shell/02-aliases-utilities`'s header
      cites these numbers — changing them here breaks the contract's first
      rating rule from the far side.
- [ ] **B5 — the head stops claiming the rated files are chezmoi-managed.**
      `Source of truth: the live config in ~/.config/nushell/
      (chezmoi-managed)` is false for half of what follows. Replace it with
      the deployed tree named as canonical per **Decision 4** (2026-08-21,
      linked to `../prds/00-delivery/corrections/prd.md`), plus the measured
      reason: the chezmoi source at
      `~/.local/share/chezmoi/home/dot_config/nushell/` holds only `cl.py`,
      `config.nu`, `env.nu`, `finder.nu`, `pass.nu`, `theme.nu` — so
      `dirstack.nu`, `quicklist.nu`, `leadermode.nu`, `overlay.nu` and
      `opacity.nu` are **not in it at all** — and its `config.nu` (380 lines)
      and `finder.nu` (345 lines) are different programs from the deployed
      ones (715 and 221). Verified live on 2026-08-21.
- [ ] **B6 — the leader-mode entry stops asking a settled question.** Its last
      sentence still reads "…so 'the live config' needs to name one of them."
      Decision 4 named one. Replace that clause with the answer: the deployed
      tree is canonical, the chezmoi source is abandoned, the 345-line source
      `finder.nu` and its `--resume`/`--fresh` design are not ported, and
      `leadermode.nu` is an unmanaged leftover of that abandoned design. Keep
      the rest of the entry, including its `DO NOT PORT` verdict and 7 / 3.
- [ ] **B7 — nothing a closed lane owns is disturbed.** The theme-switcher
      entry still carries `SIMPLIFY`, still rates 8 / 5, and still contains
      "stays as palette owner" (`decisions/tinty` moved the marker, not the
      measurements). The L-2, L-3 and L-4 "do not reproduce" notes survive the
      reorder intact.

## Out of scope

- `capabilities.md` — R1 blocks it; see the `## Questions` on the node.
- `capabilities-terminal.md` — not in W0.4a's `files` list in `plan.json`.
- `04-shell/*` PRDs — W0.4b owns them, including `04-shell/02` R4, the
  PRD-side half of the `bb`/`ba` strip.
- Re-rating anything. The markers record membership; the numbers measure.
