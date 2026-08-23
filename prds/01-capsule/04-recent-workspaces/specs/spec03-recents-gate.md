---
est: 0.75h
footprint:
  - tests/capsule-recents.sh
---

# spec03 — the recents gate (`tests/capsule-recents.sh`)

Write `tests/capsule-recents.sh`, the standing proof for spec01 and spec02:
three stages, no television TUI, no docker daemon, no network. Style and
safety follow `tests/capsule-lifecycle.sh` — `gates/lib.sh`, a tallying `chk`,
`/usr/bin/grep` always (plain `grep` is ugrep here), scratch machines under
`gates_tmpdir`, `env -i` with an explicit PATH on every `nu` call, the live
tree untouched, and a counterfactual for every text assertion.

## Design

`bash tests/capsule-recents.sh [--tree|--keys|--hermetic]`; no argument runs
all three.

### `--tree` — the two managed files as text

Every check a function, so each counterfactual (a deliberately broken scratch
copy) runs the same check and must FAIL.

- `capsule.nu`: `_capsule_recents_read`, `_capsule_shquote`,
  `_capsule_recents_pick` appear once each and all three before
  `def capsule [`; `def "capsule recent" [` appears once, after
  `def "capsule clean" [`.
- The picker's flag set is present verbatim in the file:
  `--input-header "Recent"`, `--no-sort`, `--no-preview`, and
  `--keybindings 'enter="confirm_selection"'`.
  Counterfactual: a copy with `--no-sort` deleted must FAIL. `--no-sort` is
  the flag that makes R1's recency order survive into the screen, so it gets
  its own broken copy rather than riding on the set.
- The tv call goes through `^tv`: exactly one `^tv ` in the file, and zero
  lines matching `^\s*tv ` — a bare call would be invisible to a PATH shim.
- One store path: `_capsule_recents_read` opens `(_capsule_recents)` and
  nothing else, and exactly one NON-COMMENT line in the file names
  `recents.nuon` — C.2's `_capsule_recents` def. Comment lines are skipped
  because a second mention already sits in the credentials header, and a
  comment must no more satisfy this check than fake an rm site
  (`tests/capsule-lifecycle.sh`'s rule, same direction). A second literal is
  the drift this check exists to catch.
- `wezterm.lua`: the `s` entry with `SendString("capsule recent\r")`; the `o`
  entry with `SpawnCommandInNewTab` whose args carry `nu_config`, `nu_env`
  and `"capsule recent"`; no literal `.config/nushell/config.nu` inside the
  `o` entry (the reuse check in text form).

### `--keys` — the compiled key table

`wezterm --config-file <repo>/home/dot_config/wezterm/wezterm.lua show-keys
--lua` under an isolated `HOME`, once, into a file. Skip the whole stage with
a named SKIP line — never a PASS — when `wezterm` is absent.

- `'S'` / `'CTRL'` is `SendString 'capsule\u{20}recent\r'`. The dump escapes
  the space as `\u{20}` (measured 2026-08-23 on wezterm 20240203 against this
  config plus these entries), so the literal `capsule recent` is not in the
  dump at all and a check that greps for it can never pass.
- `'O'` / `'CTRL'` is `SpawnCommandInNewTab`, its args end
  `'--execute', 'capsule\u{20}recent'`, and its `domain` is
  `'CurrentPaneDomain'`.
- The `O` args name `$HOME/.config/nushell/config.nu` and `env.nu` for the
  isolated HOME — proof the locals were reused, since a hardcoded path would
  print the developer's home instead.
- `'T'` / `'CTRL'` and `'T'` / `'SHIFT|CTRL'` are still
  `SpawnTab 'CurrentPaneDomain'` (the PRD's decision, and the node's second
  acceptance line).
- `'D'`, `'B'`, `'F6'`, `'Q'`, `'X'` are all still present.

### `--hermetic` — the real defs, a recording `tv` shim, no terminal

One machine per scenario: an isolated `HOME`, a `bin` dir first on PATH
holding a recording `tv` shim that appends its argv to `tv.log` and prints the
line named by `$TVPICK`, and a seeded store. `PATH` is the shim dir plus the
nushell directory plus `/usr/bin:/bin`, so no real `tv` is reachable.

Drive the defs with
`env -i HOME=… PATH=… nu -n --no-history -c "source <capsule.nu>; …"`, and
take the mutated-copy controls through the same harness (C.2's
`nu_cap_with` shape).

1. **Prune on read.** Store of three, middle one deleted →
   `_capsule_recents_read` returns the two live entries in stored order, and
   the file on disk now holds exactly those two.
2. **No needless write.** Store where every entry exists → the file's bytes
   are unchanged (`shasum` before and after).
3. **No store.** No file → `[]`, and no file is created.
4. **The TTY guard fires first.** `capsule recent` under `-c` exits non-zero
   with `interactive-only`, and `tv.log` does not exist. `$nu.is-interactive`
   is false under `-c` and true under `--execute` (measured on nushell
   0.114.1, 2026-08-23), which is why this stage proves the guard here and
   the helpers separately.
5. **The argv.** `_capsule_recents_pick` logs exactly one invocation
   carrying `--input-header Recent`, `--no-sort`, `--no-preview` and
   `--keybindings enter="confirm_selection"`, and returns the shim's line.
6. **The order is the store's order.** Run the recorded source command
   through `sh -c` and compare its lines to the store, in order. This is the
   newest-first proof that needs no terminal; what a tv screen does with
   `--no-sort` is manual box 1.
7. **Hostile names.** A directory whose name holds a space and a single quote
   round-trips through the source command byte-identically. Counterfactual: a
   copy of `capsule.nu` whose `_capsule_shquote` returns its argument
   unquoted must FAIL this check.
8. **The real tv accepts this exact flag set.** Run `tv` (the real one, if
   installed) with the flag set the shim recorded, stdin `/dev/null`, and
   assert the exit is not 2 and stderr carries no
   `Error parsing CLI arguments`. Control, so the check can fail: the same
   call with `--keybindings 'confirm_selection = "enter"'` — the config-file
   form — must produce that error. Measured on television 0.15.9, 2026-08-23:
   the correct form reaches the TUI and aborts for want of a terminal (exit
   1, crash report), the inverse form and any junk are rejected at argument
   parsing, and an unknown flag exits 2. SKIP with a named line when `tv` is
   absent.
9. **The composition is text, and says so.** `capsule recent`'s body is
   read → pick → `capsule`, and its non-interactive guard makes the whole
   def undrivable in this harness. Assert the three call sites in `--tree`
   and name the manual boxes that cover the live path; do not fake a pass
   with a check that cannot fail.

Register the gate as a wave-4 gate. `gates/waves.tsv` is **held by another
worker**: land the test file and report the registration row as owed —
`external bash tests/capsule-recents.sh` on the wave-4 row, which is where
C.4 sits.

## Acceptance

- [x] `bash tests/capsule-recents.sh` exits 0 with zero `FAIL` lines and
      prints a `PASS`/`FAIL` tally.
- [x] Each of the three stages runs alone: `--tree`, `--keys`, `--hermetic`.
- [x] Every text assertion in `--tree` has a counterfactual that FAILS it,
      including the `--no-sort` deletion and the unquoted `_capsule_shquote`.
- [x] The `--hermetic` stage never reaches a real `tv` or a real `docker`:
      asserted as a precondition check that neither binary exists on the
      scenario `PATH` outside the shim dir.
- [x] The gate leaves the live tree untouched: `snapshot_paths` /
      `assert_unchanged` over `home/dot_config/nushell/capsule.nu` and
      `home/dot_config/wezterm/wezterm.lua`, and nothing is written under
      `$HOME/.cache/capsule`.
- [x] Forcing one check's helper to return success unconditionally turns at
      least one control red — the selftest rule, executed and quoted.
- [x] `bash tests/capsule-lifecycle.sh` still passes — the sibling gate over
      the same `capsule.nu` is undisturbed. Baseline measured 2026-08-23
      before this node: `--tree` is 24 pass, 0 fail.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/capsule-recents.sh; echo "exit=$?"
bash tests/capsule-recents.sh --tree     | /usr/bin/grep -c '^FAIL'
bash tests/capsule-recents.sh --keys     | /usr/bin/grep -c '^FAIL'
bash tests/capsule-recents.sh --hermetic | /usr/bin/grep -c '^FAIL'
bash tests/capsule-lifecycle.sh | tail -2
```
