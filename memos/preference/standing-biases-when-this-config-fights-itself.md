---
kind: preference
description: the standing biases for this config — delete over document, built-in over wrapper, no changelog comments in a config, deployment proven not asserted
read_when: "the user is choosing between writing more, deleting more, or moving on"
---

# standing-biases-when-this-config-fights-itself

When the configuration fights itself — a new file, a new line, a second
explanation for a behaviour the manual already measures — these biases
hold:

- **Delete over document.** A behaviour that does not earn its place
  does not earn a paragraph either. A deletion is what the bias picks
  first, in every disagreement.
- **Built-in over wrapper.** A built-in tool (nushell, tmux,
  television) is preferred over a wrapper that does the same thing.
  The wrapper is the second mechanism, and two mechanisms for one job
  is the cost. `tv` owns the picker screens; `fd` finds; `rg` searches;
  `nu` is the shell. A wrapper that re-implements one of those is
  a deletion, not a refactor.
- **No changelog comments in a config.** A comment says what a line does
  or the one trap that breaks it. "Used to", "removed on", "stood
  here" is git's job (`git blame`), not the config's. Configs
  carrying a changelog have comments that drown the config; measure
  before the comment is kept. The I1 invariant of `09-simplify` is
  this in rule form.
- **Deployment proven, never asserted.** Every change that affects a
  file the user types in is `chezmoi apply`'d, then used, before the
  change is settled. A commit that has not been applied has not
  finished — `chezmoiremove` is a permanent uninstaller only because
  the deployed path is the one tested, not the source. I5 of
  `09-simplify` is this in rule form.
- **The smaller, the better.** Stated 2026-09-02. An item stays only if
  removing it loses something the daily driver needs. When in doubt,
  delete.