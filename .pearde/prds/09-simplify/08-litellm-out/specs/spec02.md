---
complexity: 14
footprint:
  - ~/dev/llm-router
  - .pearde/prds/00-delivery/decisions/fzf-model-picker/prd.md
---

# spec02 — stand the router up as a project of its own

The six files spec01 deleted become `~/dev/llm-router`: a git repo with
`bin/`, a `README.md` and an `install.sh` that puts the five commands on
PATH. Nothing in this repo points at it; `cll` is simply on PATH again, which
is all `claude.lua` needs.

This spec writes **outside this repo**, on purpose — that is the whole point
of the node. Its only file inside the board is the one line R4 asks for.

## What already stands

`probe/stage-the-router-project.sh` builds this exact shape in a throwaway
directory from `git show HEAD:...` and proves it works from there:

- the five scripts parse — three are bash, **two are python3**
  (`litellm-gen-config`, `llm-quota`), so a bash-only syntax gate is wrong;
- `cll` finds `litellm-env` through PATH, not through a fixed directory
  (`cll:19` is `. "$(dirname "$(command -v litellm-env)")/litellm-env"`), so
  the set is relocatable as long as the whole `bin/` goes on PATH together;
- run from the staged project, `cll --list` exits 0 and prints the catalogue.

## What is left

1. `mkdir -p ~/dev/llm-router/bin && git -C ~/dev/llm-router init`.
2. Take the six files from the commit before spec01 lands
   (`git show <sha>:home/dot_local/bin/executable_<n>`), write them to
   `~/dev/llm-router/bin/<n>` mode 755, and `litellm.nu` to the project root.
3. `install.sh`: `ln -sf ~/dev/llm-router/bin/* ~/.local/bin/` — same names,
   so it overwrites this machine's five orphans rather than leaving a shadow
   of them ahead on PATH. `~/.local/bin` is already first in `env.nu`'s PATH
   repair, so nothing in this repo changes.
4. `README.md` naming the three couplings the move does not fix, so the next
   reader is not surprised by them:
   - it reads another tool's credential store, `~/.pi/agent/auth.json`;
   - `cll` execs `nu -c 'source ~/.config/nushell/config.nu; cc …'` for the
     native branch, so its Max-plan hop still needs this dotfiles repo's
     `claude.nu` on the machine;
   - `cll` hardcodes nineteen Claude Code state directories to symlink into
     its own profile.
   None of the three is this node's work to fix — the PRD says so — but an
   unwritten coupling is one that breaks silently.
5. `litellm.nu` ships in the project but is sourced by nothing. It is the
   nushell skin — `llm`, `llm quota`, `llm regen`, `cll` tab-completion — and
   those four gestures are gone from the shell until someone wires it back
   from the project. That is the loss this node accepts; name it in the
   README so it is a choice and not a regression.
6. `.pearde/prds/00-delivery/decisions/fzf-model-picker/prd.md` gains one line
   saying the picker now lives in `~/dev/llm-router/bin/cll` (R4).

## Compute cost

None. Every command here is local; `cll --list` reads a cached catalogue and
does not call a provider.

## Acceptance

- [ ] `~/dev/llm-router` is a git repo holding `bin/` with the five commands mode 755, `litellm.nu`, `README.md` and `install.sh`
- [ ] Each of the five parses under its own shebang — `bash -n` for three, `python3 -m py_compile` for `litellm-gen-config` and `llm-quota`
- [ ] `~/dev/llm-router/install.sh` is idempotent: running it twice leaves five links in `~/.local/bin` and exits 0 both times
- [ ] `nu -l -c 'which cll'` answers a path, and that path resolves into `~/dev/llm-router/bin`
- [ ] `cll --list` exits 0 and prints at least one model name
- [ ] No file under `~/.local/bin` for these five names is a regular file any more — each is a symlink into the project
- [ ] `README.md` names all three couplings and the four lost shell gestures
- [ ] The `fzf-model-picker` decision node says where the picker now lives

## Verify and Proof

```sh
set -eu
P="$HOME/dev/llm-router"

test -d "$P/.git"
for f in cll litellm-env litellm-gen-config litellm-up llm-quota; do
  test -x "$P/bin/$f"
  case "$(head -1 "$P/bin/$f")" in
    *python3*) python3 -m py_compile "$P/bin/$f" ;;
    *)         bash -n "$P/bin/$f" ;;
  esac
done
test -f "$P/README.md" && test -f "$P/litellm.nu"

# idempotent install, asserted on the post-state both times
sh "$P/install.sh" >/dev/null
sh "$P/install.sh" >/dev/null
for f in cll litellm-env litellm-gen-config litellm-up llm-quota; do
  if [ ! -L "$HOME/.local/bin/$f" ]; then echo "FAIL: $f is not a link"; exit 1; fi
  case "$(readlink "$HOME/.local/bin/$f")" in
    "$P"/bin/*) ;;
    *) echo "FAIL: $f does not point into the project"; exit 1 ;;
  esac
done

# the shell that loads the config finds it — `nu -c` would not
w=$(nu -l -c 'which cll | get path | first')
case "$(readlink -f "$w" 2>/dev/null || readlink "$w")" in
  "$P"/bin/cll) ;; *) echo "FAIL: which cll -> $w"; exit 1 ;;
esac

cll --list | head -1 | grep -q .

grep -q 'pi/agent/auth.json' "$P/README.md"
grep -q 'claude.nu' "$P/README.md"
grep -q 'llm-router' .pearde/prds/00-delivery/decisions/fzf-model-picker/prd.md

echo OK
```
