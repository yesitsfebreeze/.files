---
state: open
priority: 15
est:
mode: afk
needs:
verify: "bash gates/wave-status.sh --validate"
origin: derived
from: 04-shell/10-litellm-launcher
claim: 
---

# `S.10`'s gate is committed and registered nowhere, so the registry's own validation is red

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/waves.tsv` names no row for **`S.10`**
([`04-shell/10-litellm-launcher`](../../../04-shell/10-litellm-launcher/prd.md)),
and its gate `tests/shell-litellm.sh` is committed but referenced by nothing.
Measured 2026-08-28, `bash gates/wave-status.sh --validate` → `EXIT=1`:

```
FAIL  registry: every board task appears in a wave row (missing: S.10)
FAIL  registry: every script under tests/ is named by a row
      (unreferenced: shell-litellm.sh)
```

`grep -n "S\.10\|litellm" gates/waves.tsv` returns **nothing**. Both files are
clean in git, so this predates the round that found it: `S.10` landed at
`0b77a71` with its gate, and the registry row was never added.

**The consequence, and it is the reason this is a node rather than a memo.**
The registry exists so that "every landed node has a registered gate" is a
checkable claim. For `04-shell/10-litellm-launcher` that claim is **false
today**, and `tests/shell-litellm.sh` is therefore never run by
`just gates` — the one command the delivery epic points at for the whole set.
A node whose gate no sweep executes is a `done` node whose proof is not wired
up, which is the property this family of corrections exists to protect.

It also makes `bash gates/selftest.sh` exit 1, so any node that treats a green
`selftest` as a precondition reads a red as a green.

**Found while collecting `06-help/05-agent-interface`**, whose implementer hit
it running the repo gates over its own footprint and reported it rather than
fixing it. Nothing in that node's footprint touches either file.

## Requirements
- [ ] **R1** — `gates/waves.tsv` gains the row that registers
      `tests/shell-litellm.sh` against `S.10`, in the wave the dependency
      graph actually puts it in. Read the wave off the node's `needs:` and the
      existing rows' shape; do not guess a wave to make the validation pass.
- [ ] **R2** — `bash gates/wave-status.sh --validate` exits 0 with both
      assertions still saying something true, tally quoted not asserted.
- [ ] **R3** — `bash gates/selftest.sh` exits 0, or the remaining reason it
      does not is named here and shown to be a different fault from this one.
- [ ] **R4** — **Sweep for the same class rather than fixing the instance.**
      `S.10` was missed because nothing failed loudly when its row was
      omitted. Check every `done` node with a `tests/` gate for a registry
      row, and report the count — if `S.10` is the only one, that is worth
      knowing; if it is not, the others are the same defect.

## Acceptance
- [ ] `bash gates/wave-status.sh --validate` exits 0, both previously failing
      assertions quoted as passing.
- [ ] `tests/shell-litellm.sh` runs as part of its wave's sweep, shown by the
      sweep's own output naming it — not by the row existing.
- [ ] The census from R4 is written down, whatever number it comes to.

## Out of scope
- The content of `tests/shell-litellm.sh`. It is committed and passes; this is
  about the registry never naming it.
- Every other assertion in `wave-status.sh --validate`. The other four pass.
