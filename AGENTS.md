Working contract for agents in this repo. Read this before touching anything.

## What this repo is

A rebuild of the dotfiles that used to live in `~/.files` (legacy, zsh-era)
and `~/.config/*` (chezmoi-managed): rate every existing capability, take
over only what earns its place, and ship a minimal daily-driver config.
Nothing is ported because it exists; it is ported because a rating in
`docs/capabilities-*.md` says it earns its place.

## Where things live

| Path | What it is |
|---|---|
| `home/` | The chezmoi source. Find it live with `chezmoi source-path` — never a literal path; `~/.local/share/chezmoi` is a stale clone, never the source |
| `docs/` | Rated capability inventories and background research |
| `memos/` | The record: every settled claim as one memo, `SYSTEM.md` the entry point. `just memos-check` regenerates the index and gates it |
| `pearde/` | The board: `prds/` (PRDs and nothing else), `workflows/`, `settings.md`, `vision.md`. `.pearde` is a symlink to it |
| `home/dot_config/nushell/help/manual/` | The environment manual, read with `?` or `help` in the shell. `guide/` and `reference/` are generated from `.nuon` surfaces (`just manual`); `internals/` is hand-written |
| `scripts/` | `board-guard.py` (claim/requirement checks), `memos-check.py` (the memos gate + index), `generate-manual.mjs` |
| `justfile` | Task runner: `push`, `manual`, `memos-check`, the two board-guard targets |
| `install.sh` | Package + provisioning bootstrap |
| `.claude/skills/pearde/README.md` | The board protocol — a symlink to `~/dev/infra/pearde`, not vendored here |

## Scope decisions

- macOS host only; Linux matters only inside containers.
- Nushell is the host shell; zsh survives only inside capsule dev containers.
- One container tool (Capsule), one image definition.
- Two finders, deliberately: television in the shell, telescope in the
  editor. fzf is the one accepted third picker, reached only through
  `zoxide query --interactive`.
- tmux owns multiplexing (windows, panes, splits, copy, status,
  persistence); WezTerm keeps only local chrome (font, grid, opacity,
  launchd PATH, capsule send-keys).
- tinty owns the palette; every reader (tmux, Neovim, television, the
  shell) is downstream of one `tinty apply`. Nothing below it hardcodes hex.
- Minimal base first — see `.pearde/prds/README.md`'s exclusion list.

## Hard-won constraints

Carry these into any requirement that touches them, with the reason:
television needs a real TTY; reedline has no chord trees; OSC 133
double-marking causes phantom prompt lines; `use_kitty_protocol` leaks an
escape through the WezTerm pty; lualine's `auto` theme breaks on base16; an
unrotated LSP log can hit double-digit GB; a `dofile` must never become a
`require` (module-name caching hands back the first read on a second call).

## Working the board

Read `.claude/skills/pearde/README.md` for states, the loop and worker
briefs. Before suggesting or writing any shell/editor workflow, read `?` —
it is what stops the standard failure mode of reaching for `fzf` when
television is the picker, `grep` when `rg` is, `find` when `fd` is. Add a
manual entry with every keybinding or command in the same change: the drift
checker is gone, so nothing will tell you if you skip it.

`09-simplify`'s five invariants (`.pearde/prds/09-simplify/prd.md`, I1–I5)
govern every config change in this repo: no changelog comments, no PRD
node for anything outside `home/`, no stale counts in prose, a built-in
over a wrapper, and every child proven by deploying and using it.

No dated correction lives in this file. If you find it wrong, fix the
sentence — do not append a paragraph explaining that it used to be wrong.
