---
state: open
claim: 
priority: 22
est:
mode: afk
needs:
  - 03-editor/09-lsp
footprint:
  - home/dot_config/nvim/lua/plugins/lsp.lua
  - tests/nvim-lsp.sh
verify: "bash tests/nvim-lsp.sh"
origin: derived
from: 03-editor/07-formatting
---

# An offline launch discards the first save

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: on a cold Neovim session with the network unreachable, the **first
write is silently thrown away** — the buffer is not written, the file stays
byte-identical, and the user sees `E5113 … ENOTCONN` where they expected a
saved file. Found 2026-08-23 by
[`07-formatting`](../../../03-editor/07-formatting/prd.md)'s analyst while
measuring conform's failure surface, reproduced twice, and **not** conform's
bug.

**The consequence for a requested PRD, which is why this is filed rather than
recorded as a memo:**
[`03-editor/09-lsp`](../../../03-editor/09-lsp/prd.md) is `done`, and its
mason setup is what ships this. Mason's registry promise rejects *inside*
whatever blocking call is pumping the event loop at the time. `format_on_save`
(`format_lines_sync` → `vim.wait`) is such a call, so the rejection propagates
out of `BufWritePre` and aborts the write. The analyst reproduced the same
abort through `table-mode.lua:39`'s `nvim_exec2` instead of conform, which is
what establishes the owner: **any** `BufWritePre` consumer that pumps the loop
inherits it, so fixing it in one plugin's config fixes one symptom. E.11 will
ship on top of this, and E.15 already has.

This is data loss on a laptop that woke up on a train, which is the ordinary
case for this configuration, not an exotic one.

## Requirements
- [ ] **R1** — Reproduce it before changing anything: cold XDG root, network
      unreachable, one `BufWritePre` consumer that pumps the loop. Record the
      exact error, and record that the file is byte-identical afterwards —
      "the write failed" and "the write was discarded" are different bugs and
      only the second one is this node.
- [ ] **R2** — The mason registry refresh must not be able to reject into an
      unrelated blocking call. Name the mechanism chosen and why; a
      `pcall` around one call site is a symptom fix and does not satisfy this.
- [ ] **R3** — Whatever lands must keep working **offline by default**.
      **Corrected 2026-08-23, hours after this node was filed: the workaround
      this requirement was built on does not work.** R3 said "the measured
      workaround is seeding `mason/registries`". The E.11 implementer tried
      exactly that and measured it false — **5 of 5** identical probe runs
      still aborted on a seeded root. Draining the pending work under `pcall`
      before the write also failed, at **1/6 and then 3/6**, which is the
      shape of the real thing: it is a **race** on which blocking call happens
      to be pumping the loop when mason's refused promise rejects, not a
      missing cache.

      Its three-arm control is the measurement to build on, and it is why the
      E.11 gate can be trusted at all:

      | arm                              | aborts |
      |----------------------------------|--------|
      | full config, undrained           | 2/5    |
      | full config, drained             | 2/5    |
      | isolated, no `lua/plugins/lsp.lua` | 0/5  |

      `lsp.lua` is the only file that loads mason, so removing it takes the
      abort rate to zero — that is what identifies the owner, and it is how
      E.11's probes measure conform rather than this bug. A fix must therefore
      change the **rejection path**, not the cache, and R4's counterfactual
      has to survive a 2-in-5 race: a single green run proves nothing here.
- [ ] **R4** — A counterfactual that goes red with the fix reverted, per
      [`a-counterfactual-proves-its-own-mutation`](../../../memos/a-counterfactual-proves-its-own-mutation.md).
      An offline reproduction is the hard part; if it cannot be made
      hermetic, say so with the measurement rather than shipping a check that
      cannot fail.

## Acceptance
- [ ] A cold offline launch writes the first save: the file's mtime and
      content change, quoted before and after.
- [ ] The reproduction from R1 is quoted in full, including the
      byte-identical evidence.
- [ ] `bash tests/nvim-lsp.sh` passes with the new counterfactual, output
      quoted.

## Out of scope
- conform.nvim's own configuration. It is one victim of this, not the cause,
  and [`07-formatting`](../../../03-editor/07-formatting/prd.md) ships
  independently of the fix.
- Making mason work offline in general — only that its failure must not eat
  an unrelated write.
