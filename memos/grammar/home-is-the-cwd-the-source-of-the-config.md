---
kind: grammar
description: the dotfiles repo's working copy at `~/dev/dotfiles` is `home/`'s source; chezmoi deploys from it, the manual reads from it, the record lives beside it
read_when: "running a command that names a path, or writing one that another reader will copy"
---

# home-is-the-cwd-the-source-of-the-config

The repo at `~/dev/dotfiles` is the **source** of the configuration, not the
deployed configuration itself. `home/` is what chezmoi deploys to `~`; the
manual at `home/dot_config/nushell/help/manual/` is the document the shell's
`?` and `help` read after deployment, the same file under both paths; the
memos record at `memos/` lives beside `home/`, not under it, because it
is about the source not the deployment.

Two spellings in commands and prose stay separate: `chezmoi source-path`
returns the **source** directory (a chezmoi command resolving to this
repo); `home/` is the *path within* the source. A line in a memo that says
"edit `home/dot_config/nushell/config.nu`" is the path inside the repo
checked out at `~/dev/dotfiles`; a line that says "edit
`~/.config/nushell/config.nu`" is the deployed path on the machine.

A `git status` in this repo is dirty when `home/` is dirty, not when `~` is
dirty; chezmoi owns the deployed state and the deployed state is
regenerable, so the source is the only thing the repo tracks. See
`a-retirement-is-two-edits`: a retirement deletes the source AND the
target on the same commit, because the deployed state cannot be inferred
from the source alone.