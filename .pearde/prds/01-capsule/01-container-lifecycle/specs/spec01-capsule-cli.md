# spec01 — capsule.nu, the one CLI

Write `home/dot_config/nushell/capsule.nu`: the `capsule` command and its
`list`/`clean` subcommands (R1–R7), sourced from config.nu's MODULES anchor.
This is design-from-requirements, not porting — the legacy `mount`/`justfile`
path never ran (finding C-3), and nothing in it is behaviour to preserve.

**Est:** 3.5h

**Footprint:** `home/dot_config/nushell/capsule.nu`,
`home/dot_config/nushell/config.nu` (one source line — **serial-after-S.4**,
that lane holds config.nu), `tests/nushell-core.sh` (one `cp` line in
`mk_machine`)

## Design

The file parses standalone under `nu -n` (theme.nu precedent): the gate
sources it directly, and no def depends on anything config.nu sets up.
All docker calls go through `^docker`, so a PATH shim can observe every one.

**Constants, named once at the top:**

- Dockerfile: `~/.config/capsule/Dockerfile` — the chezmoi target of C.1's
  spec01, literal path.
- Image: `capsule:latest`. C.2 owns this name; nothing else builds or tags
  it (dev-image's own gate uses throwaway `capsule-gate-*` tags).
- Container name prefix: `capsule-` (R1, R6).
- Image label `capsule.dockerfile` = sha256 of the Dockerfile it was built
  from; container label `capsule.dir` = the absolute directory mounted.
- Recents: `~/.cache/capsule/recents.nuon` (C.4 R1's path — state, not
  config, so `chezmoi apply` never touches it).

**Helpers, in parse order, each used by exactly one concern:**

- `_capsule_name [dir]` (R1): `capsule-<san>-<hash8>`. `<san>` is the
  directory basename with every character outside `[A-Za-z0-9_.-]` replaced
  by `-`; `<hash8>` is the first 8 hex chars of `($dir | hash sha256)` over
  the absolute path. The hash is always appended, not only on collision:
  same dir → same name on every invocation, two `api` dirs in different
  parents → different names, with no registry to consult.
- `_capsule_hash`: `open --raw <dockerfile> | hash sha256`. Content hash,
  not mtime: stored in the image label there is no side state file, and a
  `touch` does not trigger a rebuild (R3).
- `_capsule_image_hash`: `^docker image inspect capsule:latest --format
  '{{index .Config.Labels "capsule.dockerfile"}}'` through `complete`;
  empty string when the image is absent.
- `_capsule_build`: `^docker build -t capsule:latest --label
  capsule.dockerfile=<hash> -f <dockerfile> ~/.config/capsule`. Build
  output streams to the terminal. Non-zero exit → `error make`; the
  container is never touched after a failed build. No `--platform` flag —
  native linux/arm64, C.1's rule.
- `_capsule_state [name]`: `^docker container inspect` through `complete` →
  `{exists: bool, running: bool, dir_label: string}` (from
  `.State.Running` and the `capsule.dir` label).
- `_capsule_owned` (R6): the one set both `list` and `clean` operate on —
  `^docker ps -a --filter label=capsule.dir --format
  '{{.Names}}\t{{.Label "capsule.dir"}}\t{{.State}}'`, parsed, then
  filtered to names starting `capsule-`. Label AND prefix: strictly
  narrower than the prefix R6 requires, so a hand-made container that
  happens to be named `capsule-x` is still never touched.
- `_capsule_record [dir]` (R7, format per C.4 R1): `mkdir ~/.cache/capsule`,
  then `[$dir] ++ (old | where {|d| $d != $dir}) | first 20 | save -f`.
  Wrapped in `try`; on failure print one line to stderr and continue — a
  read-only cache dir must not block the attach.

**`def capsule [dir?: path, --rebuild]`** — the flow:

1. `target` = `$dir` or `$env.PWD`, `path expand`ed. Not an existing
   directory → `error make` naming it. Everything downstream uses
   `$target` only — the tool has no working directory of its own and never
   calls `cd` (R5, finding C-3).
2. `which docker` empty → `error make` naming Docker Desktop. Dockerfile
   absent → `error make` naming `chezmoi apply`.
3. Build when `--rebuild` or `_capsule_hash != _capsule_image_hash` (R3,
   R4). Otherwise never — no implicit rebuild.
4. `name = _capsule_name $target`.
5. `--rebuild` and the container exists (either state): `^docker rm -f
   $name` (R4 — rebuild recreates). **The auto path never removes a
   container:** a hash-triggered rebuild updates the image only, and the
   existing container is attached as-is. R2's letter — running means exec —
   and the safe-cheap-mistake rule: recreation destroys container-local
   state, so `--rebuild` is the one recreate gesture, exactly what the
   shipped manual (`help/capsule.nuon`) already promises.
6. Container absent: `^docker run -d --name $name --label
   capsule.dir=($target) -v ($target):/workspace capsule:latest`. The
   image's `CMD ["sleep","infinity"]` idles it detached. A name conflict
   with a container that lacks the `capsule.dir` label → `error make`
   naming the foreign container; never adopt, never remove it.
7. Exists but stopped: `^docker start $name` (R2).
8. `_capsule_record $target` — after the container is confirmed up, before
   the attach, because `exec` blocks until the shell exits (R7).
9. `^docker exec -it $name zsh`. The image's `WORKDIR /workspace` puts the
   shell in the mounted directory; no `-w` flag to drift from it.

**`def "capsule list"`** (R6): `_capsule_owned` rendered as a nu table with
columns `name`, `dir`, `status` — `status` is `running` or `stopped`
(anything docker reports other than `running` is stopped).

**`def "capsule clean" [--all]`** (R6): from `_capsule_owned`, remove the
stopped rows with `^docker rm`; with `--all` also the running rows with
`^docker rm -f`. Return the removed names; an empty set returns an empty
list and touches nothing.

**The three `^docker rm` sites, and the guard over each.** Enumerated,
never claimed universally: what stood here was a universal claim that every
removal went through `_capsule_owned`, and the `--rebuild` recreate never
reads that set at all — measured false and retired by
[`capsule-rm-guard-attribution`](../../../00-delivery/corrections/capsule-rm-guard-attribution/prd.md).

- `capsule` step 7, the `--rebuild` recreate (`^docker rm -f $name`) —
  guarded by step 6's refusal on an empty `dir_label`.
- `capsule clean`'s stopped branch (`^docker rm $row.name`) — guarded by
  `_capsule_owned`.
- `capsule clean`'s running branch, `--all` only (`^docker rm -f
  $row.name`) — guarded by `_capsule_owned`.

The two guards are not the same test. `_capsule_owned` is label-key AND
name prefix; step 6 tests the label's VALUE. They agree on every container
this tool can create, because the create line always writes a non-empty
`capsule.dir`. They diverge on one input nothing here can produce: a
container someone else named `capsule-*` and labelled with an EMPTY
`capsule.dir` — step 6 refuses that one, `clean` removes it. That seam is
definitional rather than a reach onto a genuinely foreign container, and
closing it would change a guard. `capsule.nu`'s `capsule clean` header
carries the same enumeration, and `tests/capsule-lifecycle.sh` holds it
down as `RM_SITES` plus `attribution_ok`.

**config.nu** (serial-after-S.4): add `source ~/.config/nushell/capsule.nu`
at the MODULES anchor, after the zoxide.nu line, before `# ── PALETTE ──`.
A source of a missing file is a parse error, so the module and this line
land in the same change.

**tests/nushell-core.sh**: add
`cp "$NUSHELL_SRC/capsule.nu" "$M/home/.config/nushell/capsule.nu"` beside
the zoxide.nu line in `mk_machine` — without it that gate's scratch
machines hit `nu::parser::sourced_file_not_found` on the new source line.

No help entries are owed: `help/capsule.nuon` already documents `capsule
[dir]`, `--rebuild`, `list` and `clean` against this PRD. Its `capsule
clean` entry still hedges on the invocation R6 has since settled — that
correction is 06-help work with an independent re-read attached (recorded
in `w0-4-s2-corrections/capsule`), not this spec's.

## Acceptance

- [x] `nu -n -c 'source home/dot_config/nushell/capsule.nu'` exits 0 —
      the module parses standalone.
- [x] Naming: for two directories both named `api` under different parents,
      `_capsule_name` yields different names; twice for the same directory,
      the identical name; every name matches `^capsule-[A-Za-z0-9_.-]+$`.
- [~] Fresh directory, no image: `capsule` builds the image, creates the
      container, lands in zsh at `/workspace` with the directory's contents
      visible (`ls` inside shows them).
- [~] Second `capsule` in the same directory: no build, no create — attach
      only, well under one second to the prompt.
- [~] Append a comment to `~/.config/capsule/Dockerfile`, run `capsule`:
      exactly one rebuild; the existing container is attached, not
      recreated (same container id before and after).
- [~] `capsule --rebuild`: image rebuilt, container id changes.
- [~] From an unrelated cwd, `capsule /some/path`: `docker inspect --format
      '{{json .Mounts}}'` shows the workspace bind with `Source` exactly
      `/some/path` — not the cwd, not `/some/path/workspace`.
- [~] With one running capsule, one stopped capsule and one non-capsule
      container present: `capsule list` shows exactly the two capsules with
      dir and status; `capsule clean` removes only the stopped one;
      `capsule clean --all` removes the running one; the non-capsule
      container survives both.
- [~] After mounting two directories, `~/.cache/capsule/recents.nuon` holds
      both, most recent first, no duplicates.
- [x] config.nu sources capsule.nu exactly once, under MODULES, after
      zoxide.nu, before PALETTE; `bash tests/nushell-core.sh` still passes.

## Verify

```sh
# Parse + naming (hermetic).
nu -n -c 'source home/dot_config/nushell/capsule.nu'
# Real-docker flow (assumes Docker Desktop running; cold build is
# network-bound). Run interactively from a scratch directory:
#   capsule                      # build + create + attach; ls; exit
#   time capsule                 # attach only, < 1s to exec
#   capsule /tmp/<other-dir>     # then:
docker inspect --format '{{json .Mounts}}' <name>
capsule list
capsule clean
bash tests/nushell-core.sh
```
