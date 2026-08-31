---
complexity: 18
footprint:
  - home/dot_config/nvim/lua/config/lazy.lua
  - home/dot_config/nushell/help-check.nu
  - home/dot_config/nushell/help/README.md
  - tests/nvim-plugin-manager.sh
---

# spec01 — the Neovim surface resolves: one non-installing spawn, the seven rules, the three `desc` states

R2 for the 61 **global** `nvim-map` targets. One `nvim --headless` per run
dumps `nvim_get_keymap` for every mode; the corpus's written `lhs` is
normalized before comparison; and a target's `desc` is read in three states —
explicit (must equal the live `desc`), `null` (existence only), absent
(compare against the entry's `title`). The buffer-local eight stay
`unresolved` and belong to sibling `04-nvim-buffer-maps`; the ~156
undocumented live maps belong to `05-allowlist`.

**The spawn observes, it never provisions.** Measured 2026-08-29: lazy.nvim
git-cloned `persistence.nvim` from the network in the middle of a check run,
because the lockfile named it and the store did not hold it, and the clone
chatter on stdout killed the JSON parse — that is the `help-check.nu:166`
death `01-check-plumbing` recorded twice. `--clean`/`--noplugin` are NOT the
fix and are the trap next to it: either one skips the plugin directories and
Neovim answers with its own 123 defaults, which the check reported as 54 stale
and 1 mismatched, every one false. So the guard is an env variable —
`HELP_CHECK=1`, read in `lua/config/lazy.lua` — that turns `install.missing`
and the update `checker` off while leaving every plugin loadable.

**Every way the dump can be degraded raises**, because a degraded dump looks
exactly like drift and gets read as our bug: no `init.lua`; lazy.nvim absent
(a *failed check*, never a bootstrap clone); the install guard not in force,
read back from `lazy.core.config.options.install.missing` on every run rather
than assumed; any declared plugin absent from the store, whose maps would
otherwise silently read as stale; and a zero-map dump.

The dump is written to a **file** named by `HELP_CHECK_DUMP`, never to stdout:
stdout is shared with anything the config or a plugin prints, which is how the
clone was found.

**What already stands** (built and measured 2026-08-29, uncommitted in the
tree): every box below was executed by the Verify block, which exits 0 whole
under `set -e -o pipefail`. The boxes are ticked against those runs. Re-run
the block rather than trusting the ticks — two of its numbers (61 targets,
217 live maps) moved by three during this round when
`07-multiplexer/06-nvim-session` landed, and a count in prose is a reading of
the day it was taken.

## Acceptance

- [x] `home/dot_config/nvim/lua/config/lazy.lua` reads `HELP_CHECK`, and under
      it `install.missing` and `checker.enabled` are both false while an
      ordinary launch keeps `install.missing = true` and
      `checker.enabled = true`
- [x] a headless spawn with `HELP_CHECK=1` against a staged machine whose
      plugin store is missing one lockfile plugin **raises** naming that
      plugin, and the store is byte-for-byte unchanged afterwards — nothing
      was cloned
- [x] with the guard forced off, the same machine's store GAINS the plugin and
      `_hc_nvim_live` raises "the spawn was allowed to install plugins" — the
      readback assertion is proven able to fail
- [x] a machine with no `~/.config/nvim/init.lua` raises, and a machine whose
      `lazy.nvim` is absent raises with lazy's own message, rc 1, without
      cloning lazy.nvim
- [x] all 61 global `nvim-map` targets resolve through `_hc_norm_lhs` against
      the live dump (raw `lhs` comparison resolves 30 of them), and the
      corpus README's table carries the `<space>` → `" "` row
- [x] the three `desc` states each behave, proven by mutation on a staged
      machine: an explicit `desc` drifted in the config reports **mismatched**;
      the map deleted reports **stale**; `desc` removed from the corpus target
      reports **mismatched against the entry's title**; `desc: null` with a
      drifted live `desc` reports **nothing**
- [x] `bash tests/nvim-plugin-manager.sh` exits 0, asserting both directions of
      the guard and carrying a counterfactual that forces `local checking`
      false and requires the `HELP_CHECK` row to go red
- [x] `bash tests/nvim-colorscheme.sh` exits 0 — its `install = { colorscheme
      = { "` extractor still matches, which is why `missing` is the LAST key
- [x] `help --check` on a staged machine reaches its report and exits 1 on the
      drift count, with `mismatched: 0` and zero stale on the nvim surface —
      not on a JSON parse error

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
P=prds/06-help/04-drift-check/03-nvim-resolver/probe
SCRATCH=$(mktemp -d)

# nushell renders an `error make` message WRAPPED, at the width of whatever
# it is printing to, with a `| ` continuation on every line — so a needle of
# more than a few words matches interactively and misses in a redirect.
# Every assertion on a raise message goes through this.
flat() { tr '\n' ' ' | sed 's/ *| */ /g' | tr -s ' '; }

# ── the guard, in the config and in both gates that read the file ───────────
grep -n 'HELP_CHECK' home/dot_config/nvim/lua/config/lazy.lua
bash tests/nvim-plugin-manager.sh > "$SCRATCH/pm.out" 2>&1; echo "plugin-manager rc=$?"
# Print the count AND assert it separately: a bare `grep -c` exits 1 on a zero
# count, so under `set -e -o pipefail` the EXPECTED answer aborts the block.
f=$( grep -c '^FAIL' "$SCRATCH/pm.out" ) || true
echo "plugin-manager FAILs: $f (expect 0)"; test "$f" -eq 0
grep -E '^PASS  (R6: install.missing|HELP_CHECK=1:|counterfactual: guard removed)' "$SCRATCH/pm.out"
bash tests/nvim-colorscheme.sh > "$SCRATCH/cs.out" 2>&1; echo "colorscheme rc=$?"
f=$( grep -c '^FAIL' "$SCRATCH/cs.out" ) || true
echo "colorscheme FAILs: $f (expect 0)"; test "$f" -eq 0

# ── a complete machine: the dump, and the seven rules ──────────────────────
bash $P/mk-machine.sh "$SCRATCH/full" > /dev/null
bash $P/nu-c.sh "$SCRATCH/full" '
let maps = (_hc_nvim_live)
let g = (_hc_targets | where kind == "nvim-map" and scope != "buffer")
let raw  = ($g | where {|x| ($maps | where mode == $x.mode and lhs == $x.lhs | is-not-empty)} | length)
let norm = ($g | where {|x| ($maps | where mode == $x.mode and lhs == (_hc_norm_lhs $x.lhs) | is-not-empty)} | length)
print $"live ($maps | length) · targets ($g | length) · raw ($raw) · normalized ($norm)"
if $norm != ($g | length) { error make {msg: "not every global target resolves"} }
'
grep -nF '| `<space>` | `" "`' home/dot_config/nushell/help/README.md

# ── a degraded store raises, and NOTHING is cloned ─────────────────────────
bash $P/mk-machine.sh "$SCRATCH/degraded" persistence.nvim > /dev/null
before=$( ls "$SCRATCH/degraded/home/.local/share/nvim/lazy" | wc -l )
out=$( bash $P/nu-c.sh "$SCRATCH/degraded" '_hc_nvim_live | length' 2>&1 ) && rc=0 || rc=$?
after=$( ls "$SCRATCH/degraded/home/.local/share/nvim/lazy" | wc -l )
echo "degraded rc=$rc store $before -> $after"
test "$rc" -ne 0
test "$before" -eq "$after"
printf '%s\n' "$out" | flat | grep -q 'declared but not installed'

# ── the counterfactual: guard off, and the store GROWS (needs the network) ──
bash $P/mk-machine.sh "$SCRATCH/noguard" persistence.nvim > /dev/null
perl -i -pe 's/^local checking = .*$/local checking = false/' \
  "$SCRATCH/noguard/home/.config/nvim/lua/config/lazy.lua"
before=$( ls "$SCRATCH/noguard/home/.local/share/nvim/lazy" | wc -l )
out=$( bash $P/nu-c.sh "$SCRATCH/noguard" '_hc_nvim_live | length' 2>&1 ) && rc=0 || rc=$?
after=$( ls "$SCRATCH/noguard/home/.local/share/nvim/lazy" | wc -l )
echo "noguard rc=$rc store $before -> $after (expect it to GROW: the guard is what stops the clone)"
test "$rc" -ne 0
printf '%s\n' "$out" | flat | grep -q 'allowed to install plugins'

# ── the two missing-config raises ──────────────────────────────────────────
bash $P/mk-machine.sh "$SCRATCH/noconfig" > /dev/null
rm -rf "$SCRATCH/noconfig/home/.config/nvim"
# Both of these RAISE, so the nu run exits 1. Capture first and grep the
# variable: under `set -e -o pipefail` a pipeline whose left side exits 1
# kills the block even when the grep on the right succeeds.
out=$( bash $P/nu-c.sh "$SCRATCH/noconfig" '_hc_nvim_live | length' 2>&1 ) || true
printf '%s\n' "$out" | flat | grep -q 'init.lua is missing'
bash $P/mk-machine.sh "$SCRATCH/nolazy" > /dev/null
rm -rf "$SCRATCH/nolazy/home/.local/share/nvim/lazy/lazy.nvim"
out=$( bash $P/nu-c.sh "$SCRATCH/nolazy" '_hc_nvim_live | length' 2>&1 ) || true
printf '%s\n' "$out" | flat | grep -q 'lazy.nvim is not installed'
test ! -d "$SCRATCH/nolazy/home/.local/share/nvim/lazy/lazy.nvim"

# ── the three desc states, by mutation ─────────────────────────────────────
# mutations.sh asserts each expectation itself and exits non-zero on any
# mismatch, so this line is a check and not a printout.
bash $P/mutations.sh "$SCRATCH/full"; echo "mutations rc=$?"

# ── end to end ─────────────────────────────────────────────────────────────
bash $P/mk-machine.sh "$SCRATCH/e2e" > /dev/null
out=$( bash $P/nu-c.sh "$SCRATCH/e2e" 'help --check' 2>&1 ) && rc=0 || rc=$?
echo "help --check rc=$rc (expect 1 — the corpus has known shell drift)"
printf '%s\n' "$out" | head -8
test "$rc" -eq 1
printf '%s\n' "$out" | grep -q 'mismatched: 0'
# The failure this replaced: the run used to die in `from json` on lazy's
# clone chatter. Assert its absence positively rather than with `grep -v`,
# which is true of any line and proves nothing.
if printf '%s\n' "$out" | grep -q 'parsing JSON'; then
  echo "STILL DYING IN from json — the dump is reaching the parser off stdout"; exit 1
fi
```
