---
atomic: bisect-which-command-expands-the-format
subject: -e` arrived literal and `-d` did not, which is the whole defect; testing the same popup as a key binding, inside a template, and through `run-shell` is what separated the expander from the expandee
date: 2026-09-02
runs: 0
---

## Do

1. Run the same command three ways — as the direct argument of a key binding, inside the body it will really live in, and through `run-shell` — with a stub on `PATH` that prints every argument and the environment variable back.
2. Compare which arguments came back expanded and which came back as literal `#{...}`.

## Done when

- One route returns the expanded value and the others return the literal, so the expander is named rather than guessed.

## Fails when
