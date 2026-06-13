# Setup Docs — static, searchable documentation browser

A single self-contained HTML file that indexes this repo's documentation so you
can **search and read how to use this setup** offline — no server, no network,
no dependencies.

## Use it

Open `docs/index.html` in any browser.

- Type in the search box for instant full-text search across every doc.
- Press `/` to focus search, `↑`/`↓` to move, `Enter` to open, `Esc` to clear.
- Without a query the sidebar shows everything grouped by section.

## What it contains

The builder scans the repo and renders these into the browser:

| Section | Source |
|---------|--------|
| Guide | `README.md` |
| Project layer | `.proj/**/*.md` |
| Rules | `.claude/rules/**/*.md` |
| Output styles | `.claude/output-styles/*.md` |
| Agents | `.claude/agents/*.md` |
| Skills | `.claude/skills/**/*.md` |

`.claude/`, `.proj/`, and `.kern/` are gitignored, so their markdown is
**pre-rendered into `index.html`** at build time — the doc site stays portable
and committable even though its sources are not.

## Rebuild

```sh
python docs/build.py          # regenerate docs/index.html
python docs/build.py --check  # list what would be included, no write
```

The build has **zero third-party dependencies** (pure Python 3) and is
**deterministic** — unchanged sources produce byte-identical output, so it is
safe to run on a loop or in a pre-commit hook.
