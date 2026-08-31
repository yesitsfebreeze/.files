---
complexity: 24
footprint:
  - home/dot_config/nushell/help-check.nu
  - tests/help-drift-check.sh
---

# spec01 — the report, the exit code, and a gate that has been watched go red

R4, R5, R7, plus `tests/help-drift-check.sh`.

## The report

One counts line naming every surface it actually read, then the four classes
in order — stale, mismatched, undocumented, unresolved — each printed even
when empty, because "0 stale" and "the stale section is missing" are
different statements and only one of them is reassuring.

**Stale is the dangerous class** and is why the check exists: it sends a
reader — or an agent — to a key that does nothing. Undocumented is the common
one. Mismatched is a title that has quietly stopped describing its map.
Unresolved is the check admitting it could not see.

## The exit code

`error make`, never `exit`. `exit 1` inside a def closes the INTERACTIVE
shell, so `help --check` typed at a prompt would end the session. The report
prints before the raise, so a failing run still shows what drifted. Only
stale, mismatched and undocumented fail the run; unresolved does not, because
a surface the check cannot see is not the manual's defect.

## The gate: five stages, and every one has been watched go red

`--clean` `--shell` `--terminal` `--nvim` `--degraded`, plus `--selftest`.

The four acceptance mutations, each demanding a SPECIFIC finding:

1. a key the manual documents, unbound in `tmux.conf` → STALE, naming the key
   and its table;
2. a key added to a table this config OWNS (`jump`) with no entry →
   UNDOCUMENTED (the reverse direction is deliberately not run over `root` or
   `copy-mode-vi`: those are tmux's own tables full of shipped defaults, and
   reporting them would drown the real finding);
3. a wezterm key the manual documents, unbound → STALE;
4. **the Neovim-default collision** — a documented map at an lhs nothing
   binds → STALE with the NORMALIZED lhs quoted, so `<leader>zz` reading as
   `' zz'` is visible rather than looking like a formatting bug.

`--degraded` is the other half and matters as much: four ways a reader can be
blind — tmux conf missing, tmux conf that does not load cleanly, wezterm conf
missing, a corpus file gone — each RAISES rather than reporting drift. A
degraded surface is indistinguishable from drift and reads as the manual's
fault.

## Two traps the gate itself fell into, recorded

- **`open … | append … | save -f` on the same file left the corpus
  unchanged.** Two mutations were being measured against a corpus nobody had
  mutated — a green box on nothing. They are textual inserts now, and the
  gate asserts the file grew before it looks for the finding.
- **`awk -v rec="$body"` with newlines truncated the file to zero bytes**,
  which reads as "no entries" rather than as an error.

## Acceptance

- [x] `bash tests/help-drift-check.sh` exits 0 — 36 PASS, no FAIL.
- [x] `--selftest` exits 0: the conf mutations are proven through tmux itself,
      and `has_finding` is proven to say no.
- [x] All four acceptance mutations produce their specific finding.
- [x] All four degraded readers raise.
- [x] The report names every surface with a non-zero live count.
- [x] No `exit 1` anywhere in the checker; the failure is `error make`.
- [x] No tmux server is left on the probe socket or the default one.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/help-drift-check.sh
bash tests/help-drift-check.sh --selftest
tmux ls 2>&1 | grep -q 'no server running'
```

Run 2026-08-30: rc 0 (36 PASS), selftest rc 0, socket clean.
