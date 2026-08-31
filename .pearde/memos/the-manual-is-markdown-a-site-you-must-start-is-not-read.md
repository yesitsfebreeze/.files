---
memo: the-manual-is-markdown-a-site-you-must-start-is-not-read
kind: decision
status: decided
subject: the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
date: 2026-08-31
prds:
  - 06-help
  - 06-help/03-browser
  - 04-shell/04-television
---

# the-manual-is-markdown-a-site-you-must-start-is-not-read — `?` replaces localhost:3000

## Decision

`docs-site/` — the fumadocs site added earlier the same day by
[the tests-and-gates memo](tests-and-gates-retire-a-dev-setup-is-not-a-product.md)
— is **deleted**, Next.js, `node_modules`, `npm run dev` and all. The manual
it rendered becomes plain markdown under
`home/dot_config/nushell/help/manual/`, shipped to
`~/.config/nushell/help/manual/` by `chezmoi apply` like every other file in
this configuration:

- `manual/guide/*.md` — generated from `tasks.nuon` and the four surfaces
- `manual/reference/*.md` — generated from `topics.nuon` and the same surfaces
- `manual/internals/*.md` — hand-written, moved across from the site's
  `content/docs/internals/*.mdx` with the MDX components flattened
- `manual/index.md` — hand-written

The generator moves from `docs-site/scripts/generate-manual.mjs` to
`scripts/generate-manual.mjs` and emits markdown instead of MDX. `just manual`
runs it. Nothing else builds.

The search is a television channel, `docs` (`home/dot_config/television/cable/docs.toml`):
`rg` over every line of that tree, `bat` preview at the hit, and enter opens
the file in `$EDITOR` at that line. `?` is the alias — `docs` spelled out is
the same command — and it goes through `finder --start docs`, so the existing
`GrepList` decode and `_finder_open` do the opening and the Ctrl-Space remote
lists it beside every other channel for free.

## What it beat

**Keeping the site.** It is a better renderer: sidebar, `⌘K`, anchors,
cross-links that resolve. It also cost `npm install`, a `node_modules` the
size of the rest of the repo, and a dev server that had to be running before
a single sentence could be read. The measurement is behavioural and it is the
whole argument: in the hours it existed, nobody started it.

**A single compiled `index.html`, opened by `?`.** This was the first shape
asked for, and it is genuinely better than a dev server — one file, no
install, `⌘F` searches it. It was dropped for the same reason as the site,
one step further along: it is still a browser leaving the terminal, and the
thing you find in it is a rendered copy you cannot edit. The channel lands
you in Neovim on the file itself.

**Extending the existing `manual` channel instead of adding one.** `manual`
matches an *entry* — one key or one command, by id and title, out of the
`.nuon` corpus — and prints it. `docs` matches a *line of prose* anywhere in
the manual and opens the file there. Folding the second into the first would
have mixed two row shapes in one picker and cost the entry search its
precision. They stay separate: `manual` for a key you half-remember, `docs`
for a sentence you half-remember.

## What it costs, recorded

The rendered niceties are gone. Tables are pipe tables read in a text editor,
the links between pages are relative paths that nothing resolves for you, and
there is no full-text index — `rg` re-reads the tree on every keystroke of
the picker, which at ~8,000 lines is free and at ten times that would not be.

Editing lands on the **deployed** copy under `~/.config`, not on the chezmoi
source. For `internals/` that is a real trap: an edit made from the picker is
lost at the next `chezmoi apply`. Edit `home/dot_config/nushell/help/manual/`
in the repo and apply. For `guide/` and `reference/` it does not arise —
those are generated, carry a GENERATED banner, and the source is the `.nuon`
surface.
