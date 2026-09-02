---
state: deferred
origin: derived
priority: 14
complexity: 0
blast-radius:
repo:
time:
  est:
  actual:
needs:
footprint:
  - home/.chezmoi.toml.tmpl
---

# silence the chezmoi config-template drift warning

Every `chezmoi` invocation on this machine prints:

```
chezmoi: warning: config file template has changed, run chezmoi init to
regenerate config file
```

Established 2026-09-02 by `analyst-tv` while speccing
`09-simplify/retire-the-unmanaged-television-channels` — finding F9 in that
node's `report.md`. It affected no result there, and it was outside that
footprint.

It means `home/.chezmoi.toml.tmpl` has drifted from the config chezmoi
generated on this machine. The warning is cheap to live with and cheap to
clear, but it is on the front of every chezmoi command a worker runs, which
means every verify block that captures stderr carries it and every worker has
to learn to ignore it. That is the cost: it trains readers to skim chezmoi's
own warnings.

**Two shapes, and the node has to choose deliberately.** Running `chezmoi
init` regenerates the config from the template and the warning goes — but it
also rewrites whatever the generated config currently holds, and if this
machine's config was hand-edited after generation, that edit is what
disappears. So: diff the generated config against what the template would
produce *before* regenerating, and if they differ in anything but noise, the
template is what needs the change, not the machine.

**Filed deferred on purpose.** Nothing on the board is blocked by it and it
belongs to nobody's current pass. Move it `open` when someone decides the
noise is worth a pass, or fold it into whatever next touches
`home/.chezmoi.toml.tmpl`.

## Acceptance

- [ ] A bare `chezmoi status` prints no `config file template has changed`
      warning on this machine.
- [ ] Whatever the generated config held that the template did not is either
      written into the template or written down as deliberately dropped.
