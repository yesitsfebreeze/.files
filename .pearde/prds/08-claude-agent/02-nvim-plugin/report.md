# 08-claude-agent/02-nvim-plugin — implementer report

Verdict: BLOCKED

Two walls, both needing a decision I am not allowed to take alone. spec01 is
four boxes of five closed and one measured false; spec02 cannot be started at
all, because the directories it writes into were deleted from this repo by a
recorded decision.

## The walls

### 1. spec02 writes into `tests/` and `gates/`, which this repo retired

spec02's whole footprint is `tests/nvim-claude.sh` and an edit to
`gates/nvim-seed-registry.sh`. Neither directory exists:

```
$ ls -d tests gates
ls: gates: No such file or directory
ls: tests: No such file or directory
$ git log --diff-filter=D --oneline -1 -- tests/nvim-small-plugins.sh
ad3f1a6 retire tests and gates; move the why into a searchable docs site
```

The deletion is a decision on the record, taken by the user on 2026-08-31 and
held in `.pearde/memos/tests-and-gates-retire-a-dev-setup-is-not-a-product.md`
("`tests/` (53 scripts) and `gates/` (26 files …) are **deleted** … and no
replacement runner is written"). `AGENTS.md` restates it: "**There are no
tests.**"

spec01's `## Verify and Proof` block runs into the same wall — it calls
`bash tests/nvim-keymaps.sh`, `bash gates/nvim-seed-registry.sh` and
`bash tests/nvim-small-plugins.sh`, all three deleted in that same commit.

The specs were written 2026-08-31 21:12, hours after the retirement landed,
from a probe pass that predated it. They are not wrong about the mechanism
they describe; they are addressed to a repo that no longer exists.

**Question for the orchestrator.** Does the retirement decision supersede
spec02 — in which case spec02 should be rewritten or dropped and spec01's
Verify block replaced with the direct probes I ran below — or does spec02
stand and the retirement is being reversed for this node? Writing a gate into
a directory the user deleted on purpose is not a call an implementer takes,
and re-scoping spec02 myself would be redefining the spec.

### 2. spec01 box 4 is not satisfiable — measured, twice

The box asks that inside a real tmux session `claude-tmux`'s returned config
read `{ toggle_key = "<C-j>", split_size = 30, split_side = "bottom" }`. Two
of the three hold. `split_side` does not, and cannot.

`claudecode.nvim`'s `terminal.setup()` ends with
`get_provider().setup(defaults)` (`lua/claudecode/terminal.lua:584`) where
`defaults.split_side = "right"` (`terminal.lua:11`), and `claude-tmux`'s
provider setup force-merges what it is handed over its own state
(`lua/claude-tmux/init.lua:164`,
`vim.tbl_deep_extend("force", state.config or {}, config)`). The value
`claude.lua` passes is therefore overwritten every time. There is no way to
route `"bottom"` through claudecode either: its validator accepts only
`"left"` or `"right"` and warns away anything else (`terminal.lua:206`,
`terminal.lua:454-458`).

Measured inside a real tmux session on a private socket, firing the real
`:ClaudeCode` command, with two different inputs:

```
# input 1 — claude.lua as it stands, split_side = "bottom"
CT-CONFIG=true { … split_side = "right", split_size = 30, … toggle_key = "<C-j>" }
panes: %0 h=49 w=139   %1 h=49 w=60     # a right split of a 200x50 window

# input 2 — the same file with split_side = "left"
AFTER-FIRE split_side=right split_size=30 toggle_key=<C-j>
panes: %0 h=49 w=139   %1 h=49 w=60     # identical
```

So `split_side = "bottom"` in `home/dot_config/nvim/lua/plugins/claude.lua` is
dead configuration, and the pane Claude opens in is a right split, not a
bottom one. This also corrects `probe/pass-one.md`, which recorded
"`t.open(nil,nil)` created a real tmux bottom split" — true when the provider
is driven directly, false on the `:ClaudeCode` path the user actually presses,
because claudecode's re-setup runs last.

**Question for the orchestrator.** Is a right split acceptable (drop
`split_side` from `claude.lua` as dead, and correct the box), or is a bottom
split the requirement (in which case `claude.lua` must re-assert
`claude_tmux.setup{…}` *after* `require("claudecode").setup(opts)` — the
provider reads `state.config.split_side` at open time, `init.lua:201`, so it
would win, but that is a behaviour change to a file carrying uncommitted user
edits and not something a spec box authorises me to invent).

Both findings are on the knowledge base:
`.pearde/wiki/sources/nvim/260902-79f9.md` and `…/260902-5a05.md`.

## What I did land

`home/dot_config/nvim/lazy-lock.json` — the three pins, and nothing else:

```
$ git diff --stat home/dot_config/nvim/lazy-lock.json
 home/dot_config/nvim/lazy-lock.json | 3 +++
 1 file changed, 3 insertions(+)
+  "claude-tmux.nvim": { "branch": "main", "commit": "90b221c423385eb18a234e52378a18bc14f6dd5f" },
+  "claudecode.nvim": { "branch": "main", "commit": "2390c6e45c4789072c293ac69de051d169668b29" },
+  "snacks.nvim": { "branch": "main", "commit": "882c996cf28183f4d63640de0b4c02ec886d01f2" },
$ python3 -c "…json.load…"
23 entries; sorted: True
```

The trap the spec warned about held: no `Lazy! sync` was run, the three lines
were written by hand at the commits the live store actually carries, and no
other line moved.

## Box status

`specs/spec01.md` — 4 of 5 closed, evidence appended to the spec under
`## Measured`.

| Box | | What closed it |
|---|---|---|
| 1 lockfile pins | `[x]` | 3 insertions, 23 entries, sorted, nothing else moved |
| 2 live store | `[x]` | `rev-parse HEAD` = `2390c6e45c…`, `90b221c423…`, `882c996cf2…`, all branch `main`; `git calls: 0` in both `HELP_CHECK=1` runs; `~/.config/nvim` never read or written |
| 3 headless stubs | `[x]` | `CMD-STUBS=14/14`, `PRELOAD-claudecode=false`, `ANY-claudecode-in-package.loaded=false`, `git calls: 0`, nine leader key stubs — see the prefix note below |
| 4 tmux provider | `[ ]` | not met; wall 2 above |
| 5 outside tmux | `[x]` | `PROVIDER-TYPE=string VAL=auto`, `CT-REQUIRE=true`, `CT-IS-AVAILABLE=false`, `FIRE-ClaudeCode=true` |

`specs/spec02.md` — 0 of 6. Nothing can be ticked; the tree it writes into is
gone.

### The keymap prefix has moved, and the spec text has not

Spec01 box 3 and the probe both say `<leader>a*`. The tree's uncommitted
`claude.lua` moved the group to `<leader>x`, with the reason written in the
file ("`a` sat on the generic leader namespace, and Claude gets a solo
whichkey prefix instead"). Measured:

```
CLAUDE-KEY-STUBS=11
  n <Space>x  :: Claude          n <Space>xC :: Continue Claude
  n <Space>xa :: Accept diff     n <Space>xb :: Add current buffer
  n <Space>xc :: Toggle Claude   n <Space>xd :: Deny diff
  n <Space>xf :: Focus Claude    n <Space>xm :: Select Claude model
  n <Space>xr :: Resume Claude   v/x <Space>xs :: Send to Claude
PRELOAD-claudecode=false
```

Nine `<leader>x<char>` stubs plus the group — the count and shape the spec
asks for, under a different letter. I ticked the box and named the divergence
rather than change a deliberate uncommitted edit to match stale spec prose.
`04-help-entries` will need `<leader>x*`, not `<leader>a*`.

Also worth carrying: `nvim_get_keymap` returns the raw `lhs`, so
`keytrans(m.lhs)` gives `<Space>xc`, never the literal `<leader>xc`. A probe
matching on `"<leader>"` finds nothing and reads as a missing keymap. My first
pass hit exactly that and reported `LEADER-X-STUBS=0` against a config that
was fine.

## The seeding trap, measured

Seeding a staged plugin store with **symlinks** into the live store makes
lazy.nvim call every seeded plugin `not installed` — its root scan reads the
dirent type, and a symlink's type is `link`, not `directory`. The first run
printed `Plugin claudecode.nvim is not installed` (and the same for
tinted-nvim, persistence.nvim, oil.nvim), `:ClaudeCode` failed with
`Vim:Plugin claudecode.nvim is not installed`, and `require("claudecode")`
still answered — with stock defaults, `split_width_percentage=nil`,
`terminal_cmd=nil`, which reads like a config bug rather than a staging bug.
Re-seeding the identical 23 with `cp -Rc` (APFS clonefile, so still instant)
made everything load and the real merged config appear
(`SPLITW=0.3`, `TERMINAL-CMD=cll`, `DIFF-LAYOUT=vertical`).

The failure is silent in the shape that matters: the probe still exits 0 and
still prints a plausible config. Any replacement harness must copy, never
link.

## Outside my footprint — declared, not fixed

- **I ran `just manual`, reading the brief's "the repo's own gate" as the one
  repo-level check left. It is a generator, not a gate, and it wrote.** The
  working tree went from 200 modified files to 204; one is my
  `lazy-lock.json`, so **three previously-clean generated pages under
  `home/dot_config/nushell/help/manual/` became dirty**. Every change is
  downstream of `.nuon` surfaces that were *already* modified by other
  in-flight work (the `Ctrl-Space` → `F3`/`Shift+F3` rename, `F4` copy mode,
  the `pearde` alias entry), so the regeneration moved the pages toward their
  sources rather than away. I cannot name which three: the generator rewrites
  all ten guide/reference pages unconditionally, so mtimes no longer separate
  them. I left them regenerated rather than guess-revert, because reverting
  three of ten would leave the manual internally inconsistent —
  `reference/find.md` already says `F3` while a reverted `guide/history.md`
  would still link `Ctrl-Space / F1`. **This is the orchestrator's to confirm
  or undo.**
- The live store `~/.local/share/nvim/lazy/` holds two abandoned clone
  directories, `recenter.nvim.cloning` and `vim-scrolloff.cloning`, plus
  `smear-cursor.nvim`, none of which are in this repo's `lazy-lock.json`.
  Residue of the pre-cutover deployed config. Not touched.
- `claude.lua` as it stands in the tree carries work well beyond pass one — a
  `terminal_cmd = "cll"` spawn and a `CLAUDE_CONFIG_DIR` login-profile
  resolver reading `~/.claude/.last-login` and checking for `"oauthAccount"`.
  Neither is described by either spec. It is uncommitted, and I left it
  exactly as found; a later spec should account for it, because the profile
  resolver contradicts the PRD's own constraint that "the nvim-launched
  instance uses the default profile".

## How to reproduce

No `tests/` runner exists, so this is the direct staging I used; it is what
spec01's Verify block should become if the retirement decision stands.

```sh
SB=<scratch>
mkdir -p "$SB/config" "$SB/data/nvim/lazy" "$SB/state" "$SB/cache" "$SB/bin"
cp -R home/dot_config/nvim "$SB/config/nvim"
# seed every lazy-lock.json key + lazy.nvim from ~/.local/share/nvim/lazy
# with `cp -Rc` — NEVER symlinks, see above
printf '#!/bin/sh\necho "$@" >> "$GITLOG"\ncase "$1" in clone|fetch|pull|remote|ls-remote|submodule) exit 42;; esac\nexec /usr/bin/git "$@"\n' > "$SB/bin/git"
chmod +x "$SB/bin/git"
export XDG_CONFIG_HOME="$SB/config" XDG_DATA_HOME="$SB/data" \
       XDG_STATE_HOME="$SB/state" XDG_CACHE_HOME="$SB/cache" \
       PATH="$SB/bin:$PATH" HELP_CHECK=1 GITLOG="$SB/git-calls.log"
nvim --headless -u "$SB/config/nvim/init.lua" -l "$SB/probeA.lua"
# and the tmux half, on a private socket so the user's session is untouched:
tmux -L cprobe new-session -d -x 200 -y 50 "sh $SB/run-in-tmux.sh; sleep 20"
```

The probe scripts are `probeA.lua` (stubs, load state, outside-tmux fire),
`probeB.lua` (keymaps by `keytrans`) and `probeT.lua` / `probeT2.lua` (the
in-tmux provider and the two-input `split_side` measurement). They are
adaptations of `probe/probe.lua`, `probe6.lua` and `probe8.lua` and live only
in the scratch directory; say the word and I will copy them into `probe/`.

## Grammar

No term in the brief was undefined for me. `grammar.py show blocked` and
`grammar.py show verdict` both answer "not defined on this board" — the two
words the contract turns on are the two it does not define. Worth adding.
