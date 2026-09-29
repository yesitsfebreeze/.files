Working contract for agents in this repo. Read this before touching anything.

## What this repo is

A minimal macOS daily-driver: nushell + tmux + WezTerm + nvim +
television, deployed by dotfiles.sh (a replacing copy, no manager, no
templates). Read LLMs.txt first — it links the subsystem explanations in
docs/llms/*.txt, and those files are kept true in the same change as the
behavior they describe.

## Where things live

| Path | What it is |
|---|---|
| `home/` | The deploy source, REAL filenames — dotfiles.sh copies it over `$HOME` |
| `hooks/` | The deploy hooks, run in dotfiles.sh's fixed order |
| `removed.txt` | The retirement ledger — append a target path when a source file goes |
| `LLMs.txt` + `docs/llms/` | The agent map and the subsystem explanations; `?` searches them with the manual |
| `home/.config/nushell/help/` | The user-facing manual, read with `?` or `help`. `guide/` and `reference/` are generated from `.nuon` surfaces (`just manual`); `internals/` is hand-written |
| `scripts/` | `generate-manual.mjs` |
| `justfile` | Task runner: `deploy`, `push`, `manual` |
| `install.sh` | Package + provisioning bootstrap for a fresh machine |

## Scope decisions

- Host: macOS only.
- Nushell is the host shell; zsh survives only inside capsule dev containers.
- One container tool (Capsule), one image definition.
- Two finders, deliberately: television in the shell, telescope in the
  editor. fzf is the one accepted third picker, reached only through
  `zoxide query --interactive` and tv-go's channel step, theme/font pickers
  and session search — the three things television cannot do (accept the
  last match, re-run a preview on every focus, re-run the source on every
  keystroke).
- tmux owns multiplexing (windows, panes, splits, copy, status,
  persistence); WezTerm keeps only local chrome (font, grid, background image,
  launchd PATH, capsule send-keys).
- tinty owns the palette; every reader (tmux, Neovim, television, the
  shell) is downstream of one `tinty apply`. Nothing below it hardcodes hex.
- Minimal base first — nothing is ported because it exists; the dated
  reasons live in `docs/llms/decisions.txt`.

## Hard-won constraints

Carry these into any requirement that touches them, with the reason:
television needs a real TTY; reedline has no chord trees; OSC 133
double-marking causes phantom prompt lines; `use_kitty_protocol` leaks an
escape through the WezTerm pty; lualine's `auto` theme breaks on base16; an
unrotated LSP log can hit double-digit GB; a `dofile` must never become a
`require` (module-name caching hands back the first read on a second call).

Before suggesting or writing any shell/editor workflow, read `?` — it is
what stops the standard failure mode of reaching for `fzf` when
television is the picker, `grep` when `rg` is, `find` when `fd` is. Add a
manual entry with every keybinding or command in the same change, and
update the matching `docs/llms/*.txt` in the same change: nothing will
tell you if you skip either.

No dated correction lives in this file. If you find it wrong, fix the
sentence — do not append a paragraph explaining that it used to be wrong.
