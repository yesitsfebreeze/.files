---
complexity: 4
footprint:
  - home/.chezmoiremove
---

# spec04 — the deleted files leave the machine, not just the repo

`chezmoi apply` does not remove a target whose source file is gone. Measured
2026-09-02: after applying this PRD's deletions, four files were still
deployed under `~/.config`. This is net-new — no requirement covers it, and
without it the deletions are true of the repo and false of the machine.

**Already stands**: nothing. The four orphans were removed by hand on the
development machine to let the acceptance run, which is exactly why the
mechanism is needed: a hand `rm` fixes one machine and no other.

**Left to finish**: add `home/.chezmoiremove` naming the four retired
targets, relative to the destination root:

```
.config/nushell/help-check.nu
.config/nushell/help/use-review.nuon
.config/nushell/help/why-review.nuon
.config/television/cable/manual.toml
```

`.chezmoiremove` is chezmoi's own mechanism, which is why it beats a script:
the repo says what should not exist and `chezmoi apply` enforces it, on this
machine and on the next one. Three things to get right:

- **Paths are destination-relative and carry no `dot_` prefix** — they are
  targets, not source names, so `.config/...` and never `dot_config/...`.
- **It is a removal, so it must be safe on a machine that never had these
  files.** chezmoi treats an absent target as satisfied; verify that rather
  than assuming it.
- **It is permanent state.** Every future `chezmoi apply` re-applies it, so
  the file may only ever name paths that are retired for good.

Check with the concurrent `09-simplify/07-provisioning` node before landing:
`home/.chezmoiremove` is a provisioning-layer file, and if that node
introduces one too, these four lines belong in its copy rather than in a
second file.

## Acceptance

- [x] `home/.chezmoiremove` exists and names exactly the four retired targets
      — `grep -c . home/.chezmoiremove` → `4`, and the four lines are the four
      targets verbatim. Written bare, with no comment header: this spec's own
      verify block forbids one, because `grep -c .` counts comment lines toward
      the 4 and `grep -q 'dot_'` matches the words "dot_ prefix" in any prose
      explaining the rule. The why therefore lives in this spec, not the file.
- [x] every path in it is destination-relative and none begins with `dot_` —
      `grep -q 'dot_'` and `grep -qE '^(/|~)'` both find nothing.
- [x] `chezmoi apply --dry-run` reports no error and names no path outside
      those four for removal — exits 0; `chezmoi status | awk '$1 ~ /D/ || $2
      ~ /D/'` prints nothing once the four are absent, and printed exactly
      `MD .config/television/cable/manual.toml` while one was present.
- [x] after `chezmoi apply`, none of the four exists under `$HOME` — all four
      `absent`. **Proven by falsification, not by their prior absence**: the
      four were already gone (removed by hand in pass one), so the first run
      of this block passed on a mechanism it never exercised. Recreating
      `~/.config/television/cable/manual.toml` and re-applying gave
      `REMOVED — .chezmoiremove fires`.
- [x] a second `chezmoi apply` is a no-op — running it on a machine where the
      four are already absent succeeds — ran twice, both exit 0, all four
      still `absent`.

**Trap found while proving this, worth more than the box.** A recreated target
is `M`odified relative to what chezmoi last wrote, so chezmoi asks a TTY before
removing it and dies `could not open a new TTY` when there is none. The first
falsification attempt sent stderr to `/dev/null` and read the surviving file as
"the mechanism did not fire" — a false negative that would have condemned a
working file. Read `chezmoi status`: `D` in the second column is the honest
statement that the removal is armed, independent of whether a prompt let it
run. `--force` clears the guard in a non-interactive check.

## Verify and Proof

```sh
set -e
cd /Users/feb/dev/dotfiles
test -f home/.chezmoiremove
test "$(grep -c . home/.chezmoiremove)" -eq 4
if grep -q 'dot_' home/.chezmoiremove; then echo "FAIL: grep -q 'dot_' home/.chezmoiremove"; exit 1; fi
if grep -qE '^(/|~)' home/.chezmoiremove; then echo "FAIL: grep -qE '^(/|~)' home/.chezmoiremove"; exit 1; fi
chezmoi apply --dry-run >/dev/null
chezmoi apply ~/.config/nushell ~/.config/television >/dev/null
# Post-state, not the act: absent is success, and absent stays true on a re-run.
while read -r p; do [ -n "$p" ] && test ! -e "$HOME/$p"; done < home/.chezmoiremove
chezmoi apply ~/.config/nushell ~/.config/television >/dev/null
while read -r p; do [ -n "$p" ] && test ! -e "$HOME/$p"; done < home/.chezmoiremove
echo spec04 OK
```
