---
memo: an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen
kind: note
status: decided
subject: A check of the form "X is not on the screen" passes when there is no screen; five of them in one harness were green for that reason before a positive precondition was added beside each
date: 2026-08-29
prds:
  - 01-capsule/04-recent-workspaces
  - 00-delivery/corrections
---

# An absence assertion needs a positive precondition

## The rule

**Never assert an absence without asserting, in the same breath, that the
thing you are looking at exists.** `chk_hasnt "beta is gone" "$screen"` is
green when `$screen` is the picker with beta correctly pruned — and equally
green when the picker never opened, when the pane died, when the keystroke was
dropped, and when `get-text` returned an empty string. Four of those five are
failures, and the check reports all five identically.

The fix is one line and it goes *before* the absence, never after:

```sh
chk_has   "the picker actually opened"      "Recent"     "$scr"   # <- this
chk_hasnt "FIRST open — beta is absent"     "/work/beta" "$scr"
```

## Where it was measured

`tests/capsule-recents-gui.sh`, built 2026-08-29 to drive the five C.4 manual
boxes. The harness went through six runs, and **every red but one was a check
that could not discriminate rather than a defect in the thing under test**:

| symptom | what was actually wrong |
|---|---|
| "typing does not narrow", `1 / 3` | the fixture. Three dirs under a 100-char shared prefix all fuzzy-match `beta`, because tv matches SUBSEQUENCES — `b`,`e`,`t`,`a` occur in order inside the prefix |
| "the origin pane is not untouched" | the marker was grepped from a screen that also carries the ECHO of the command that sets it, so it could never pass |
| "one more tab" — got 11, wanted 12 | a dropped keystroke, not a broken binding |
| "typing does not narrow" again | the RETRY. Retyping appends, so attempt two searched `betabeta`, which matches nothing — the retry made the green unreachable |
| "beta is absent" **green**, three siblings red | the picker never opened. The absence check passed on a blank screen; only its neighbours, which assert presence, showed anything was wrong |

The last row is this memo. `5c` was the one green in a group of reds, and it
was the least trustworthy line in the file.

## Why it is worth a memo

The board already holds
[`a-chk-message-substitution-resets-the-status-it-reports`](a-chk-message-substitution-resets-the-status-it-reports.md)
and
[`a-counterfactual-proves-its-own-mutation`](a-counterfactual-proves-its-own-mutation.md),
and this is the third of the same family: a check whose green does not mean
what its label says. The session that wrote it had also just found three such
checks on this board — `02-terminal`'s config-field probe, `tree-links`'
fail-closed assertion, and `shell-init`'s S1.10 — so the failure mode is not
rare and is not a beginner's mistake. It survives review because a green line
reads as good news.

**A counterfactual would not have caught it.** `--selftest` proves the harness
can go red: remove the binding and no picker opens. But CF1's red arrives
through the *positive* assertions, and an absence check is green in that
counterfactual too — it agrees with the counterfactual for the wrong reason.
Proving a check can fail is not the same as proving it fails for its own
subject, which is why the pairing rule is stated as a rule rather than left to
the self-test to find.
