# spec01 — shadow `ls` at the LISTING anchor

Delivers R1–R4: capture the builtin as `core-ls`, add the icon map and
`decorate-ls`, shadow `ls`, define `l`/`ll`/`la`. All of it lands under the
`# ── LISTING ──` anchor in `home/dot_config/nushell/config.nu`, which
`04-shell/01-core-config` reserved for this node. The live implementation at
`~/.config/nushell/config.nu:64-142` is the model; the one thing that must NOT
be copied from it is the `du -sb` call (live bug L-1).

**Est:** 1h

**Footprint:** `home/dot_config/nushell/config.nu`

## The block, in parse order

Replace the two reservation lines under `# ── LISTING ──` ("Reserved for
04-shell/06…", "Empty as this node lands."). Keep the anchor line itself and
keep the "This anchor is BEFORE the funnel…" paragraph — the anchors gate
(`tests/nushell-core.sh --tree`) asserts all ten anchor lines in order.

1. **`const LS_ICONS`** — copy the extension→glyph map VERBATIM from
   `~/.config/nushell/config.nu:64-77`. The glyphs are Nerd Font private-use
   codepoints; retyping them corrupts silently. Keys are lowercase extensions.
2. **`alias core-ls = ls`** — before `def ls`. Alias targets bind at parse
   time, so `core-ls` stays bound to the builtin and the wrapper cannot
   recurse (R1).
3. **`def decorate-ls [du: bool]: table -> table`** — model at live `:89-118`,
   with the du call rewritten per R3 (below). Behavior:
   - `sort-by type modified`: dirs group together, newest last, freshest row
     nearest the prompt (R2).
   - `insert icon`: dir rows get the dir glyph; file rows look up the
     lowercased extension in `LS_ICONS`, generic-file glyph as fallback; then
     `move icon --before name` (R2).
   - With `du: true`, swap each dir's inode size for its recursive on-disk
     size, from ONE `du` spawn over all dir names, rows matched back by the
     path `du` echoes (R3).
4. **`def ls [...]`** — redeclare the builtin's flags explicitly, not
   `--wrapped`: `--all (-a)`, `--long (-l)`, `--short-names (-s)`,
   `--full-paths (-f)`, `--du (-D)`, `--directory (-d)`, `--mime-type (-m)`,
   `...pattern: string`. Empty pattern becomes `["."]` — the builtin's empty
   spread (`ls ...[]`) returns nothing rather than the cwd (R1). Pass every
   flag except `-D` through to `core-ls`, then pipe through `decorate-ls $du`.
   Two deliberate deviations from the builtin's own letters, both from the
   live wrapper: `-D` is OUR du decoration (the builtin spells `--directory`
   `-D`, here it is `-d`), and the builtin's own `--du` is not exposed at all —
   its native flag also walks the tree, and `decorate-ls` owns recursive dir
   sizing.
5. **`def l`/`ll`/`la`** — as live `:140-142`: `l [path: string = "."]` runs
   `ls $path`, `ll` runs `ls -l $path`, `la` runs `ls -a $path` (R4).

## The du call (R3)

- Spawn: `do { ^du -sk ...$dirs } | complete` — one spawn, both streams
  captured, nothing discarded. `-sk` prints allocated 1024-byte blocks;
  multiply by 1024 and `into filesize`. Never `-sb` (macOS `du` has no `-b`)
  and never `gdu` (not in the required package set).
- Parse stdout rows with `parse -r '(?<size>\d+)\s+(?<name>.+)'`.
- **Failure surfaces once, never silently** — this is the constraint that
  outranks the flag. L-1 survived because `e> /dev/null` ate the usage banner
  and the `default $row.size` fallback quietly restored inode sizes:
  - No parsed rows while `$dirs` is non-empty → `print -e` ONE notice naming
    `du`, its exit code and the first stderr line; every dir keeps its inode
    size.
  - Non-zero exit WITH parsed rows (e.g. one unreadable subtree) → use the
    rows, still `print -e` one notice. `print -e` keeps the table pipeline
    clean.
- Dirs a `du` row did not cover keep their inode size via
  `default $row.size` — that fallback is fine only because the failure case
  above already spoke.

## Hands off the manual

`home/dot_config/nushell/help/shell.nuon` already carries the `ls`, `ls -D`
and `l / ll / la` entries, sourced to this PRD, describing exactly this
behavior. Do not edit them — a `use` edit invalidates its review digest in
`use-review.nuon`. If the implementation is forced to diverge from an entry,
file a correction in the backlog instead.

## Acceptance

Hermetic = scratch HOME via `env -i`, empty `~/.cache/nushell/init/*.nu`
stubs, repo `config.nu` + `dirstack.nu` + `pass.nu` copied in — the harness
`tests/nushell-core.sh` stages, never the live `~/.config`. `pass.nu` joined
the stage 2026-08-22: `04-shell/02` landed `source ~/.config/nushell/pass.nu`
at the MODULES anchor after this spec was written, and a `source` of a missing
file is a parse error that takes the whole scratch shell down
(`tests/nushell-core.sh:257` stages it for the same reason).

- [x] Hermetic: `ls | columns` puts `icon` immediately before `name`; rows
      arrive sorted by `type` then `modified`. — shell-listing H1
      `icon,name,type,size,modified`, H2 `big,node_modules,.hid7,canary42.md`.
- [x] Hermetic: with a poison `du` stub first on PATH, plain `ls` in a dir
      containing subdirs never invokes it; `ls -D` does, exactly once. —
      shell-listing H3: 0 invocations plain, 1 line in the stub log for `-D`
      covering both dirs in one spawn.
- [x] Hermetic: `ls -D` over a fixture dir holding a 2 MiB file reports that
      dir ≥ 2 MiB; plain `ls` reports the same dir < 1 MiB. The number is
      checked, not "it printed something" — L-1's failure mode was a
      plausible wrong number. — shell-listing H4: du=2097152, plain=96.
- [x] Hermetic: with a `du` stub that prints a usage banner to stderr and
      exits non-zero, `ls -D` emits exactly one failure notice on stderr and
      the table shows inode sizes. — shell-listing H5: stderr
      `ls -D: du produced no sizes, exit 64: du: invalid option`, size 96 =
      plain 96.
- [x] Hermetic: `l`, `ll`, `la` all resolve; `la` lists a dotfile `l` omits;
      `ll | columns` is a strict superset of `l | columns`. — shell-listing
      H6, all three.
- [x] `/usr/bin/grep -c 'du -sb' home/dot_config/nushell/config.nu` is 0, and
      the `du` spawn line pipes through `complete` with no `e> /dev/null`. —
      grep count 0; spawn `let res = (do { ^du -sk ...$dirs } | complete)`;
      shell-listing T2 plus its reverted-spawn counterfactual.
- [x] `bash tests/nushell-core.sh` stays green end to end (anchors, funnel
      order, hermetic pty flows). — EXIT=0, 0 FAIL lines, 2026-08-22.

## Verify

```sh
cd /Users/feb/dev/dotfiles
S=$(mktemp -d); mkdir -p "$S/.cache/nushell/init" "$S/.config/nushell" "$S/fix/big"
touch "$S"/.cache/nushell/init/{starship,zoxide,television}.nu
cp home/dot_config/nushell/config.nu home/dot_config/nushell/dirstack.nu home/dot_config/nushell/pass.nu "$S/.config/nushell/"
dd if=/dev/zero of="$S/fix/big/blob" bs=1024 count=2048 2>/dev/null
NU="$(command -v nu)"
env -i HOME="$S" TERM=dumb PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$NU" -n -c 'source ~/.config/nushell/config.nu
    print (ls ~/fix | columns | str join ",")
    print (ls -D ~/fix | where type == "dir" | get size | first | into int)'
# expect: icon,... with icon before name; then a number >= 2097152
/usr/bin/grep -c 'du -sb' home/dot_config/nushell/config.nu   # expect 0
bash tests/nushell-core.sh
```
