---
kind: routine
name: bisect-which-command-expands-the-format
description: -e` arrived literal and `-d` did not, which is the whole defect; testing the same popup as a key binding, inside a template, and through `run-shell` is what separated the expander from the expandee
read_when: "executing bisect-which-command-expands-the-format"
---

# bisect-which-command-expands-the-format

_Origin: `pearde/workflows/bisect-which-command-expands-the-format.md` (workflow subject: "-e` arrived literal and `-d` did not, which is the whole defect; testing the same popup as a key binding, inside a template, and through `run-shell` is what separated the expander from the expandee")_


## Do

1. Run the same command three ways — as the direct argument of a key binding, inside the body it will really live in, and through `run-shell` — with a stub on `PATH` that prints every argument and the environment variable back.
2. Compare which arguments came back expanded and which came back as literal `#{...}`.

## Done when

- One route returns the expanded value and the others return the literal, so the expander is named rather than guessed.

## Fails when
