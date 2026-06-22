# leadermode — concept & design

`leadermode` gives Nushell a **which-key style leader overlay**: one chord opens a
menu, subsequent keys are swallowed and dispatched, and menus nest into a real
prefix tree. It lives in `home/dot_config/nushell/leadermode.nu`, is sourced by
`config.nu`, and is bound to **ctrl+space**.

## Why it has to be built, not configured

reedline (nu's line editor) has **no native multi-key prefix**. Every keybinding
is one chord → one event; there is no `<leader> g s` chord tree, and no community
plugin provides one. So a leader is emulated with the only two primitives the
runtime exposes:

1. **`executehostcommand`** — one reedline chord (ctrl+space) runs the nu command
   `leader`.
2. **`input listen`** — `leader` then reads keys raw in a loop. While that loop
   runs, reedline is not reading, so the overlay genuinely owns the keyboard. Each
   key either dispatches a menu row or is swallowed.

## The menu tree

`_leader_menu` returns a list of rows. A row is one of three kinds:

| Row shape | Kind | Behaviour |
|-----------|------|-----------|
| `{ key, desc, find: {closure} }` | `find` | closure returns a `finder` selection; `_leader_open` acts on it (file→edit, dir→cd, grep→edit@line, commit→git show) |
| `{ key, desc, run: {closure} }` | `run` | arbitrary closure; output prints. A `cd` inside it does **not** propagate (closure env is scoped) — use `find` for cd |
| `{ key, desc, menu: [ …rows ] }` | `menu` | descend into a nested level |

The default tree: `f` resumes the last finder search (refind), shift-`F` starts a
fresh one, and `g` opens a git submenu (`s`/`l`/`d`). Extend by editing
`_leader_menu` — no other code changes needed.

## Dispatch — the pure core

Two pure helpers decide everything; the loop is just I/O around them:

- **`_leader_resolve [menu, code]`** → the row bound to that key, or `null`. Keys
  are matched on `input listen`'s `.code`, which is **case-sensitive** — a shifted
  letter arrives as its uppercase char, so `f` and `F` are distinct rows that never
  collide.
- **`_leader_kind [row]`** → `"menu" | "find" | "run"`, checked in that precedence.

`_leader_run` loops: render the level, read a key, `esc` returns `"back"`, an
unmapped key is swallowed, otherwise resolve + classify + act. A submenu recurses;
its `"back"` re-renders the parent, its `"done"` (an action fired below) exits the
whole overlay. The recursion is `--env` end to end, so a `cd` from `_leader_open`
propagates out through every level to the shell.

```
ctrl+space ─▶ leader ─▶ _leader_run(root)
                          │ render level (_leader_prompt)
                          │ input listen ─▶ key
                          │   esc        ─▶ return "back"
                          │   unmapped   ─▶ swallow, loop
                          │   resolve+kind:
                          │     menu ─▶ _leader_run(sub) ─▶ "back": re-render · "done": exit
                          │     find ─▶ _leader_open(do find) ─▶ "done"
                          │     run  ─▶ do run               ─▶ "done"
```

## Constraints

- **Interactive only** — `input listen` needs a tty; `leader` no-ops otherwise.
- **nu #13891**: `input listen` ignores `use_kitty_protocol`, so *modifier* combos
  inside the loop are unreliable. Keep menu keys plain chars; `esc` is the
  bail/back. (The f/F split works because shift is folded into the char itself, not
  reported as a separate modifier.)

## Testing

`_leader_resolve` and `_leader_kind`, plus the real `_leader_menu`'s validity
(every row has key+desc, unique top-level keys, expected kinds), are covered
headless in `tests/nushell/leadermode-test.nu` — run `just test`. The interactive
loop and the `do`-closure side effects are verified by hand.

See also [finder — concept & design](finder.md), the search engine leader routes into.
