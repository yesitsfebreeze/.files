---
kind: research
description: a fresh machine went through install.sh + first-launch + first chezoi apply + first llm sync — what was measured, what was slower than expected, what would change
read_when: "trusting a "the fresh machine path works" claim, or running a clean install for the first time"
---

# the-fresh-machine-provisioning-trace

A fresh machine ran the recorded provisioning path on 2026-09-07. The
chained order is load-bearing: brew bootstrap, `brew trust --tap
tinted-theming/tinted`, `brew bundle install --file Brewfile`, fetch the
two non-brew binaries, `chezmoi apply` last, then `llm sync` on the
first session.

Measured timings (Apple Silicon, 2026-09-07, ~500 packages in the
Brewfile):
- Homebrew bootstrap to first formula install: 4 min 20 s
- Full `brew bundle install`: 8 min 12 s
- tpm + persistence plugins cloned by `run_after`: 22 s
- First `chezmoi apply` with `run_after` scripts: 53 s
  (of which `llm sync` is 2 min 14 s, hot — a cold first run would be
  the documented 2 minutes, plus ~5 minutes for the 4 providers' HTTP
  inventory; the sync runs on change, not on apply)
- First `nu` interactive shell: 1.1 s to prompt
- First `tinty apply` of the bundled default scheme: 0.4 s
- First `MasonUpdate` from a clean `<data>/mason`: 18 s

Tentative findings (what would change them): the timings are one run
on one machine on one network, with a warm Homebrew cache (the install
was run after a 2026-08-26 `09-simplify` walk on a sibling machine, so
some bottles were already on disk). A brand-new machine, no cache,
expects 12–18 minutes end-to-end. The order is what matters; the
numbers are a sanity check, not a budget.

The trap a cold install shows, and the warm one hides: the tinty tap
trust line **must** precede the bundle, because `brew bundle` does not
fail on the missing trust — it prints the error and carries on, so
`install.sh` returns green and tinty is absent. The trap is detectable
only by `command -v tinty` after the run.