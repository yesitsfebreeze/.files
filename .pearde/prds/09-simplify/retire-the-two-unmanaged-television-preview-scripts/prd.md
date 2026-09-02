---
state: deferred
origin: derived
priority: 16
complexity: 0
blast-radius:
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/retire-the-unmanaged-television-channels
footprint:
  - home/dot_config/television
  - home/.chezmoiremove
---

# retire the two unmanaged television preview scripts

Two files are deployed under `~/.config/television/` that this repo has never
carried in its source: `bg-preview.sh` and `theme-preview-sample.ts`. Both
hold a chezmoi `entryState`; neither has a source entry.
`home/dot_config/television/` holds only `cable/`, `config.toml` and
`executable_theme-preview.sh`.

Established 2026-09-02 by `analyst-tv` while speccing
`09-simplify/retire-the-unmanaged-television-channels` — finding F5 in that
node's `report.md`. It is the same class of thing that node exists to settle,
one directory up, and it sat outside that node's footprint (`cable/` plus
`.chezmoiremove`), so it was correctly left alone rather than swept in.

`bg-preview.sh` is the preview script for the `bg` channel the parent node
retires, so once that lands it is doubly dead — the channel it previewed is
gone and nothing else references it. `theme-preview-sample.ts` needs the same
question put to it before it goes: check whether
`executable_theme-preview.sh`, which the repo does own, reads it.

**Filed deferred on purpose.** The parent node has to land first — its answer
is what makes `bg-preview.sh` dead — and the `09-simplify` root does not name
this node in its `needs:`, so it must not widen that gate by sitting `open`.
Move it `open` when someone decides it is worth the pass.

**What exists when this is done.** `~/.config/television/` and
`home/dot_config/television/` agree file for file, the way the parent node
makes `cable/` agree. Removal in this repo means `home/.chezmoiremove` plus a
scoped `chezmoi apply` naming the target paths, asserting each target's
absence rather than reading the exit code — `.pearde/workflows/apply-scoped-not-bare.md`.

**The removal mechanism is settled; do not re-derive it.** `[[260902-cf50]]`
(this board's wiki) measured chezmoi 2.72.1 on exactly this shape: a
tombstoned target that still matches what chezmoi last wrote is removed
silently at exit 0 with no `--force` and no TTY, and so is a target with no
state entry at all. The loud `has changed since chezmoi last wrote it?` /
`could not open a new TTY` / exit 1 shape recorded in `[[260902-7c3a]]` needs
a third condition neither of these files is in — bytes that differ from what
chezmoi last wrote. `--force` remains harmless.

## Acceptance

- [ ] `ls ~/.config/television` and the names under
      `home/dot_config/television` describe the same set, with `cable/`
      counted as the parent node leaves it.
- [ ] `bg-preview.sh` and `theme-preview-sample.ts` are each either adopted
      into `home/dot_config/television/` or absent from
      `~/.config/television/`, and the choice is written down per file.
