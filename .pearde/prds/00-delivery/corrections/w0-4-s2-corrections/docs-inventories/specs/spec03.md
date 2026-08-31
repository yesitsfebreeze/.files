verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=docs/capabilities-provisioning.md; rc=0; RAT() { awk "/^## /{h=\$0; sub(/^## /,\"\",h); n=0} /^- [0-9]+\$/{v[n++]=\$2} /^----/{if(n>=2) printf \"%d\t%s\n\", v[n-1]-v[n-2], h}" "$f"; }; SEC() { awk -v H="$1" "index(\$0,\"## \"H)==1{s=1;next} s&&/^## /{exit} s" "$f" | tr "\n" " " | tr -s " "; }; NUM() { awk -v H="$1" "index(\$0,\"## \"H)==1{s=1;next} s&&/^## /{exit} s&&/^- [0-9]+\$/{print \$2}" "$f" | tr "\n" " "; }; RAT | awk -F"\t" "NR>1 && \$1>p {printf \"FAIL: ratio rise — %s (%d) sits below (%d)\n\", \$2, \$1, p; r=1} {p=\$1} END{exit r+0}" || rc=1; [ "$(RAT | wc -l | tr -d " ")" = "10" ] || { echo "FAIL: entry count is not 10 (got $(RAT | wc -l | tr -d " "))"; rc=1; }; GOT=$(RAT | cut -f2 | sed -e "s/  *DO NOT PORT\$//" -e "s/  *DEFER\$//" -e "s/  *SIMPLIFY\$//" -e "s/ *(.*//" | tr "\n" "|"); WANT="Shell-init generation|Idempotent apply + push workflow|Managed config surface|Starship prompt|Small tool configs|Tool installation|Neovim version gating|Published docs site|wp-stat-overlay installer|Windows config mirroring|"; [ "$GOT" = "$WANT" ] || { echo "FAIL: order is not the one R6 fixes."; echo "  got:  $GOT"; echo "  want: $WANT"; rc=1; }; S=$(SEC "Managed config surface"); echo "$S" | grep -qE "television, burrito|burrito, starship" && { echo "FAIL: burrito is still inside the list of configs the surface takes over"; rc=1; }; for s in "burrito" "DO NOT PORT" "2026-08-20" "packages.yaml"; do echo "$S" | grep -qF "$s" || { echo "FAIL: the burrito exclusion note is missing: $s"; rc=1; }; done; for s in "L-12" "L-13" "solo-window" "1149"; do echo "$S" | grep -qF "$s" || { echo "FAIL: the managed-config entry lost: $s"; rc=1; }; done; grep -q "(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/specs/\.\./prd/" "$f" && { echo "FAIL: stale ../prd/ links remain (the board lives at prds)"; rc=1; }; for l in $(grep -oE "\]\(\.\./[^)#]*\)" "$f" | sed "s/^(../../../../../../../../../../../;s)\$//"); do [ -e "docs/$l" ] || { echo "FAIL: broken relative link -> $l"; rc=1; }; done; RL="Shell-init generation@3 9 |Idempotent apply + push workflow@3 9 |Managed config surface@3 9 |Tool installation@4 9 |Neovim version gating@4 8 |Starship prompt@2 8 |Small tool configs@2 7 "; OIFS=$IFS; IFS="|"; for e in $RL; do IFS=$OIFS; h=${e%@*}; n=${e#*@}; [ "$(NUM "$h")" = "$n" ] || { echo "FAIL: \"$h\" re-rated to [$(NUM "$h")], want [$n] — 05-platform PRD headers cite these"; rc=1; }; IFS="|"; done; IFS=$OIFS; H=$(awk "/^## /{exit} {print}" "$f" | tr "\n" " " | tr -s " "); for s in "Decision 4" "canonical" "not a port target"; do echo "$H" | grep -qF "$s" || { echo "FAIL: the canonicality note was disturbed: $s"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 20m

# spec03 — `capabilities-provisioning.md`: R6's sort, and burrito out of the surface

Goal: land R6 in full and R5's provisioning half, plus the two stale board
links this file still carries.

Files: `.mi/docs/capabilities-provisioning.md` — and nothing else.

**The verify was proven RED on 2026-08-21** against the current file: five
ratio rises, the exact-order assertion, three burrito assertions and three
link assertions — twelve failures. The guards — 12 entries, the six C/U pairs
`05-platform`'s PRD headers cite, the L-12 / L-13 records inside the
managed-config entry, and the Decision 4 canonicality note in the head — pass
now and must still pass after.

## Boxes

- [ ] **B1 — the file is in R6's order, exactly.** R6 states it and the
      measurement confirms it: current ratios in file order are
      `6 7 6 1 4 6 6 6 5 -2 -1 0`, and the target is

      7  Declarative package set (`.chezmoidata/packages.yaml`)
      6  Shell-init generation (`run_after_generate-shell-init.sh`)
      6  Idempotent apply + push workflow
      6  Homebrew bootstrap (`run_once_before_install-homebrew.sh.tmpl`)
      6  Managed config surface (`home/dot_config/`)
      6  Starship prompt
      5  Small tool configs
      4  Neovim version gating
      1  Package installer (`run_onchange_install-packages.sh.tmpl`)
      0  Published docs site (`docs/`)  DEFER
      -1 wp-stat-overlay installer  DEFER
      -2 Windows config mirroring (…)  DO NOT PORT

      The five ratio-6 entries keep their existing relative order — that is
      the tie-break R6 chose precisely because it moves nothing it need not.
      Move each entry whole; re-word nothing; re-rate nothing.
- [ ] **B2 — the marked tail reads as one block, as R6 predicted.** After the
      sort the last three are `DEFER`, `DEFER`, `DO NOT PORT`. That is a
      consequence of the numbers, not a second sort key — do not reorder
      within the tail to "improve" it.
- [ ] **B3 — nothing is lost or re-rated.** 12 entries before, 12 after. The
      six pairs `05-platform` cites stay put: Shell-init 3 / 9 · Declarative
      package set 2 / 9 · Idempotent apply + push 3 / 9 · Package installer
      8 / 9 · Homebrew bootstrap 2 / 8 · Managed config surface 3 / 9. So do
      Neovim version gating 4 / 8, Starship 2 / 8, Small tool configs 2 / 7.
- [ ] **B4 — burrito leaves the surface being taken over (R5).** Remove
      `burrito` from the config list in `## Managed config surface
      (home/dot_config/)`, which currently reads "…nushell, nvim, wezterm,
      television, burrito, starship.toml, bat, …". Note that R5 calls this
      "the package list"; there is no package list in this file, and this is
      the file's only burrito mention, so the target is unambiguous.
- [ ] **B5 — the removal is recorded, not silent.** Deleting the word alone
      would make the entry a false description of the source tree, which does
      still contain `burrito/`. Add a bullet to the entry carrying: that the
      chezmoi source still holds `home/dot_config/burrito/burrito.toml` **and**
      a `burrito` `cargo_git` entry in `home/.chezmoidata/packages.yaml`, both
      verified live 2026-08-21; that burrito is `DO NOT PORT`, decided
      **2026-08-20** because it is no longer used (see the README's exclusion
      list); and that therefore neither the config dir nor the package carries
      into the rebuilt surface. The contract's rule is that an exclusion is
      recorded where a reader would look for it — a reader of this entry is
      exactly that reader.
- [ ] **B6 — the two stale board links resolve.** `(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/prd/05-platform/prd.md)`
      and `(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/prd/06-help/prd.md)` both point at a directory that does not
      exist; the board is `.mi/prds/`. Fix both to `../prds/…`, and leave every
      other link alone — the verify walks every relative link in the file and
      fails on any that does not resolve from `.mi/docs/`.
- [ ] **B7 — the head is untouched apart from nothing.** The Decision 4
      canonicality paragraph (commit 56c9f0d) and the "Correction it forces"
      note about `capabilities.md`'s cross-platform bootstrap both stay as
      they are; the second is the evidence behind Question 4 and must not be
      pre-empted here.

## Out of scope

- `05-platform/**` PRDs — W0.4f owns two of them, and
  `02-package-provisioning/packages-installer` (which still lists
  `burrito/brr` in its required set) is in **no** W0.4 child's `files` list.
  Route it, do not fix it.
- `capabilities.md` — R1.
