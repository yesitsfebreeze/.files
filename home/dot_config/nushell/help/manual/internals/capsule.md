# Capsule

> The container tool: lifecycle, credentials and the image.

Notes harvested from the capsule sources.

## `capsule.nu`

```
const CAPSULE_IMAGE = "capsule:latest"
```

capsule.nu — one directory, one dev container, one CLI (01-capsule/01, task C.2): `capsule [dir] [--rebuild]` plus the `list`/`clean` subcommands. Sourced by config.nu at the MODULES anchor; parses standalone under `nu -n`, and no def here depends on anything config.nu sets up — which is what lets anything source it in isolation.

EVERY DOCKER CALL GOES THROUGH `^docker`, so a PATH shim can observe or stand in for every one, and this file can be exercised against a recording shim without ever touching the real daemon. `^` also forces the external, so a `docker` def or alias in scope cannot silently take over.

THE TOOL HAS NO WORKING DIRECTORY OF ITS OWN (R5, finding C-3): everything downstream of argument parsing uses the expanded `$target` only, and no directory change is ever made here. The legacy `mount` failed on exactly this — it moved itself to a non-existent hardcoded directory and mounted a `workspace/` subdirectory instead of the directory it was handed. The regression spellings are kept out of this comment entirely, so a grep of the source for `cd ` or `workspace` returns a hit only if the bug has come back. Do not name them here.

REBUILD DETECTION IS A CONTENT HASH IN AN IMAGE LABEL, NOT MTIME AND NOT A SIDE STATE FILE: the sha256 of the Dockerfile it was built from rides on the image as the `capsule.dockerfile` label, so a `touch` never triggers a rebuild and there is no second file to drift. The AUTO path updates the IMAGE ONLY and attaches to the existing container as-is; `--rebuild` is the one recreate gesture, because recreation destroys container-local state and the cheap mistake has to be the safe one (R2, R4 — and what help/capsule.nuon already promises).

CREDENTIALS (01-capsule/03, task C.3) ARRIVE BY READ-ONLY MOUNT AND NEVER
BY IMAGE LAYER. The Dockerfile has no COPY and no ADD, so nothing from the
host can enter the image; the host's keys, identity and exported agent
tokens are bound in `:ro` at run time. Two rules carry the reason with
them, because both have already been got wrong somewhere:
  * THE EXPORT DIRECTORY IS ~/.cache/capsule/creds, NOT ~/.config/capsule.
    `~/.config/capsule` is the docker BUILD CONTEXT (_capsule_build passes
    it as the context path), so a token written there would be one
    `COPY .` away from a layer. The legacy config made the mirror-image
    mistake and wrote a plaintext token inside the dotfiles tree itself.
  * THE CREDS PATH IS BOUND AS A DIRECTORY, NEVER AS INDIVIDUAL FILES. A
    file bind pins an inode; the refresh replaces each file by rename
    (atomic), which changes the inode, so a file bind would keep showing
    an already-running container the old token forever. A directory bind
    shows the rename immediately, which is what lets a rotated credential
    heal a RUNNING capsule (R5).
The image name. C.2 owns it; nothing else builds or tags it — anything
exercising the build uses a throwaway tag of its own.

```
const CAPSULE_PREFIX = "capsule-"
```

The container name prefix (R1, R6).

```
const CAPSULE_HASH_LABEL = "capsule.dockerfile"
```

Image label: sha256 of the Dockerfile the image was built from.

```
const CAPSULE_DIR_LABEL = "capsule.dir"
```

Container label: the absolute directory mounted. Ownership marker — `list` and `clean` only ever see containers that carry it AND the name prefix.

```
def _capsule_dockerfile [] { $env.HOME | path join ".config" "capsule" "Dockerfile" }
```

The one Dockerfile — the chezmoi target of C.1 (01-capsule/02-dev-image).

```
def _capsule_creds_dir [] { $env.HOME | path join ".cache" "capsule" "creds" }
```

The exported credential material (C.3). Runtime state, so it sits in ~/.cache and deliberately OUTSIDE the docker build context — see the credentials note in this file's header for why that is a hard rule.

```
def _capsule_setup_script [] { $env.HOME | path join ".config" "capsule" "setup-credentials.sh" }
```

The first-run container-side setup script, as chezmoi deploys it. Mounted read-only and run once on the create path; C.3's spec02 owns its contents.

```
def _capsule_name [dir: string] {
```

_capsule_name (R1): capsule-<san>-<hash8>. <san> is the directory basename with every character outside [A-Za-z0-9_.-] replaced by `-`; <hash8> is the first 8 hex chars of the sha256 of the absolute path. The hash is ALWAYS appended, not only on collision: same dir -> same name on every invocation, two `api` dirs in different parents -> different names, no registry to consult.

```
def _capsule_hash [] { open --raw (_capsule_dockerfile) | hash sha256 }
```

_capsule_hash: content hash of the Dockerfile as deployed.

```
def _capsule_image_hash [] {
```

_capsule_image_hash: the hash the current image was built from; "" when the image is absent.

```
def _capsule_build [] {
```

_capsule_build: build output streams to the terminal. Non-zero exit aborts the def — the container is never touched after a failed build. No --platform flag: native linux/arm64, C.1's rule.

```
def _capsule_state [name: string] {
```

_capsule_state: {exists, running, dir_label} for one container name. dir_label empty on an existing container means it is NOT ours (R6's ownership marker) — never adopt it, never remove it.

dir_label is load-bearing: it is what guards the `--rebuild` REMOVAL. Step 6 of `capsule` refuses on an empty dir_label, and step 7's `^docker rm -f $name` never consults _capsule_owned — so nothing else stands between a forced rebuild and a container this tool did not create. Measured 2026-08-23: with the emptiness test neutered, `--rebuild` against a same-named container carrying no capsule.dir label asks docker to remove it. Nothing holds that down but the refusal itself, so a refactor here has to re-run that counterfactual by hand: neuter the emptiness test, point `--rebuild` at a same-named container with no `capsule.dir` label, and confirm it refuses.

Empty here really does mean "no marker": `index .Config.Labels` prints the empty string for a container that has no such label — measured against docker 29.4.0 and against text/template's `index` on a nil map, an empty map and a missing key. It never prints <no value>, which would read as non-empty and open the guard.

```
def _capsule_owned [] {
```

_capsule_owned (R6): the ONE set both `list` and `clean` operate on. Label AND prefix — strictly narrower than the prefix R6 requires, so a hand-made container that happens to be named capsule-x is still never touched.

```
def _capsule_creds_write [name: string, content: any] {
```

_capsule_creds_write: publish one credential file, mode 0600, ATOMICALLY — write a temp name, set the mode on it, rename it into place. The rename is what a running container sees the instant it happens; an in-place rewrite would expose a half-written credential to whatever is reading it.

```
def _capsule_creds_drop [name: string] {
```

_capsule_creds_drop: remove one exported file. Called whenever the host source is gone, because a revoked or logged-out credential must DISAPPEAR rather than linger — a stale file that outlives its source is exactly the failure R5 names.

```
def _capsule_creds_fresh [] {
```

_capsule_creds_fresh: true when every exported file is younger than 60s. The short-circuit exists because the export is not free (measured on this host, 2026-08-23: `git credential fill` through the `!gh auth git-credential` helper 0.75–1.16s, the keychain read 0.34–0.50s), and a burst of mounts must not fire a burst of `gh` calls.

```
def _capsule_refresh_git [] {
```

_capsule_refresh_git (R3): the host's github.com HTTPS credential, in git-credential-store format.

GIT_TERMINAL_PROMPT=0 IS LOAD-BEARING, NOT DEFENSIVE: with no helper reachable, `git credential fill` blocks on a terminal prompt, so a hermetic run would HANG instead of failing (verified 2026-08-23: with an empty HOME it exits 128 with "terminal prompts disabled").

Both fields go through `url encode --all` because the store format is a URL: a token containing `:`, `@` or `/` silently corrupts the line otherwise, and the corruption is invisible until a push fails.

```
def _capsule_refresh_claude_credentials [] {
```

_capsule_refresh_claude_credentials (R4): the agent's OAuth payload.

THIS IS THE MACOS FACT R4's ORIGINAL WORDING MISSED. On this host Claude Code keeps its tokens in the LOGIN KEYCHAIN and `~/.claude/.credentials.json` does not exist (verified 2026-08-23), so mounting `~/.claude` would have propagated no credential at all. The keychain item's payload is byte-for-byte the format that file would hold, so it is exported unchanged; the file is the fallback for a Linux-style layout.

Parse-checked before publishing: a truncated credential file makes the agent die on a parse error instead of falling back to a login flow.

```
def _capsule_refresh_claude_json [] {
```

_capsule_refresh_claude_json (R4): a FILTERED PROJECTION of ~/.claude.json, never a copy. It exists only so the agent skips onboarding.

The host file is ~671 KB and its `mcpServers` and `projects` keys name host paths and every project the user has ever opened. Copying it would drag phantom MCP servers (which fail once per prompt inside a container) and the whole project history into every capsule. Six keys, by name, and nothing else — widening this list is a decision, not a default.

```
def _capsule_refresh_opencode [] {
```

_capsule_refresh_opencode (R4): the agent's auth file only. NOT the rest of ~/.local/share/opencode — that is a 94 MB live SQLite database with WAL sidecars, and a Docker Desktop bind is the wrong medium for a live WAL.

```
def _capsule_refresh_creds [] {
```

_capsule_refresh_creds (R3, R4, R5): export the host's credential material into one 0700 directory, four files at 0600. Each file is written only when its host source answers and REMOVED when it does not.

Notably absent, and each absence measured rather than assumed: the whole of `~/.claude` (it holds history.jsonl and projects/ — every transcript from every project, and a capsule is where third-party code runs), `~/.claude.json` itself (host-path settings that fail once per prompt), and `~/.local/share/opencode` (the SQLite store above). R4's purpose — the preinstalled agents work with no login flow — is met by the four files.

```
def _capsule_cred_mounts [] {
```

_capsule_cred_mounts (R1, R2, R3, R5): the `-v` flags, in order, that go BETWEEN the workspace bind and the image name.

`:ro` ON EVERY ONE, and it is not decoration: nothing the container does can write back to the host's keys or config. The SSH keys in particular are copied container-local by the setup script precisely because their modes must be changed without touching the host copy.

A SOURCE THAT DOES NOT EXIST IS SKIPPED, NOT PASSED: docker materialises a missing bind source as an empty DIRECTORY on the host, and a `~/.gitconfig` turned into a directory is real damage.

Two staleness notes. `~/.gitconfig` and the setup script are FILE binds, so a host edit that replaces the file (`git config` writes by rename) is invisible to containers that already exist — `capsule --rebuild` is the fix, and that is acceptable for identity and aliases. And a capsule created BEFORE C.3 landed has no credential mounts at all, because docker cannot add mounts to an existing container: `capsule --rebuild` is again the fix.

```
def capsule [dir?: path, --rebuild] {
```

capsule [dir] [--rebuild] — mount a directory (default: $env.PWD) into its per-directory dev container and attach an interactive zsh at /workspace.

```
let target = ($dir | default $env.PWD | path expand)
```

1 — the target. Everything downstream uses $target only (R5).

```
let name = (_capsule_name $target)
```

3 — the name and its container state. Resolved BEFORE the build now, because C.3's credential refresh has to know whether this invocation is a create or an attach: the create path pays for the export up front, the attach path must not.

```
if $rebuild or not $state.exists {
```

4 — the credential export (C.3 R3/R4/R5). AFTER the docker and Dockerfile preconditions, never before: a missing docker must mean NOTHING happened, and that has to include leaving no credential directory behind.

SYNCHRONOUS ON THE CREATE PATH, BACKGROUNDED ON THE ATTACH PATH. The mount source must exist before `docker run`, and a cold start is dominated by docker anyway — but the export costs ~1.5s, which would break C.2 R2's "well under one second" warm attach. Backgrounded, the parent then blocks in `docker exec` for the whole session, so the job finishes long before anything inside reads a credential; and because the creds path is a DIRECTORY bind, the fresh token appears inside the already-running session rather than only on the next mount.

```
if $rebuild or ((_capsule_hash) != (_capsule_image_hash)) { _capsule_build }
```

5 — build when forced or when the Dockerfile hash no longer matches the image label (R3, R4). Otherwise never — no implicit rebuild.

```
if $state.exists and ($state.dir_label | is-empty) {
```

6 — a container of this name that lacks the capsule.dir label is foreign: never adopt, never remove — checked BEFORE the --rebuild rm, so even a forced rebuild cannot destroy someone else's container.

```
if $rebuild and $state.exists { ^docker rm -f $name | ignore }
```

7 — only --rebuild recreates (R4). The auto path never removes a container: a hash-triggered rebuild updated the image only, and the existing container is attached as-is. The removal below is covered by step 6's dir_label refusal, NOT by _capsule_owned — the site roster and both guards are enumerated at `capsule clean`.

```
^docker run -d --name $name --label $"($CAPSULE_DIR_LABEL)=($target)" -v $"($target):/workspace" ...(_capsule_cred_mounts) $CAPSULE_IMAGE | ignore
```

8 — create, detached; the image's CMD ["sleep","infinity"] idles it. The credential binds sit between the workspace bind and the image name, all `:ro` (C.3).

```
^docker start $name | ignore
```

9 — exists but stopped: start and attach (R2).

```
if not $exists and ((_capsule_setup_script) | path exists) {
```

10 — first-run credential setup (C.3 spec02), CREATE PATH ONLY. It runs as `dev`, the image's unprivileged user: C.1 R5 already creates that user and the script writes only inside $HOME, so the exec carries neither a user override nor any privilege escalation. The legacy setup script ran with root privileges and created users itself; none of that survives the consolidation. Both spellings are kept out of this comment entirely, so a grep of the source for a user override or a privilege escalation returns a hit only if one has come back. Do not name them here.

A non-zero exit is one stderr line and the flow CONTINUES to the attach, so a broken setup leaves a usable container to debug in rather than no container at all.

```
^docker exec -it $name zsh
```

12 — attach. The image's WORKDIR /workspace puts the shell in the mounted directory; no -w flag to drift from it.

```
def "capsule list" [] {
```

capsule list (R6): one row per capsule this tool owns — name, the directory it was made from, running or stopped.

```
def "capsule clean" [--all] {
```

capsule clean [--all] (R6): remove the STOPPED capsules; a bare invocation never kills a running container — the cheap mistake has to be the safe one. --all additionally stops and removes the running ones. Returns the removed names; an empty set returns an empty list and touches nothing.

THE THREE `docker rm` SITES, AND THE GUARD OVER EACH. Enumerated, never
claimed universally: what stood here was a universal claim, and it was
measurably false — it said every removal went through the _capsule_owned
set, and the `--rebuild` recreate never reads that set at all.
  * `capsule` step 7, the `--rebuild` recreate — guarded by step 6's
    dir_label refusal. See _capsule_state for why that field is
    load-bearing.
  * the stopped branch below — guarded by _capsule_owned.
  * the running branch below, --all only — guarded by _capsule_owned.

The two guards are not the same test. _capsule_owned is label-key AND name prefix; step 6 tests the label's VALUE. They agree on every container this tool can create, because the create line always writes a non-empty capsule.dir. They diverge on one input nothing here can produce: a container someone else named capsule-* and labelled with an EMPTY capsule.dir. Step 6 refuses that one; clean removes it.

The roster above is maintained by hand and nothing checks it. Adding a fourth removal site means adding it here in the same change, or the next reader trusts a list of three.

## `executable_setup-credentials.sh`

```
set -eu
```

!/usr/bin/env bash capsule's first-run credential setup (01-capsule/03, task C.3, spec02).

chezmoi deploys this to ~/.config/capsule/setup-credentials.sh (0755, the `executable_` prefix). The capsule CLI mounts it read-only at /opt/capsule/setup-credentials.sh and runs it ONCE, as `dev`, on the create path. It turns the read-only host mounts into working SSH, git and agent auth inside the container. Nothing it writes ever leaves the container.

IT LIVES BESIDE THE DOCKERFILE, AND THAT DIRECTORY IS THE BUILD CONTEXT. A script here is fine — the Dockerfile has no COPY and no ADD, and must not gain one — but a credential here would be one `COPY .` from an image layer. Never write generated material into ~/.config/capsule.

WHAT IT MAY ASSUME
  * It runs as `dev` (the image's unprivileged user, C.1 R5). It needs no
    root, creates no user and escalates no privilege: the image already
    made the user, which is the single biggest simplification over the
    legacy setup script, which created users, edited the privileged-user
    policy file, and cloned a dotfiles repo over SSH before any credential
    was known to work. Both spellings are kept out of this comment
    entirely, so a grep of the source finds one only if it has come back.
  * The image has git, openssh-client, bash, zsh and coreutils (C.1 R2 and
    its support set). It installs NOTHING — the toolbox is closed (C.1 R7).
  * Mounts, all read-only, all optional: /opt/capsule/host/ssh,
    /opt/capsule/host/gitconfig, and /opt/capsule/creds holding
    git-credentials, claude-credentials.json, claude.json and
    opencode-auth.json.

WHAT IT MUST NEVER DO
  * Write, chmod or chown anything under /opt/capsule — those are the
    read-only host mounts.
  * Write outside $HOME.
  * Print a credential, not even truncated: this runs with its output on
    the user's terminal, and a token in the scrollback is a token in the
    scrollback.
  * Install a package, or create a user.

It is IDEMPOTENT: `capsule --rebuild` re-runs it, and so may a human debugging inside a capsule. Every optional source is guarded — a missing source is one warning on stderr and a continue, never an abort.

```
install -d -m 700 "$HOME/.ssh"
```

── 1 — SSH (R1) ────────────────────────────────────────────────────────────

The keys are COPIED rather than used from the mount, and that is R1's point with its reason: Docker Desktop's macOS file sharing does not carry host file modes into the container in a form ssh will accept, and ssh refuses a private key it considers group- or world-readable ("Permissions ... are too open"). The mount stays read-only; the usable copy is container-local, so fixing modes can never change the host's keys.

```
if [ ! -f "$HOME/.ssh/known_hosts" ] && [ -f "$SSH_SRC/known_hosts" ]; then
```

NOTHING ELSE IS COPIED — explicitly not the host's own ~/.ssh/config and not .DS_Store. The host config is macOS-shaped: on this machine it is `Include ~/.orbstack/ssh/config`, a path that does not exist here, and the common macOS `UseKeychain yes` line makes Linux ssh abort EVERY invocation with "Bad configuration option: usekeychain". The legacy script copied the whole directory and inherited exactly that risk. known_hosts: seeded from the host copy only when we do not have one yet, so a second run never re-overwrites lines this script appended.

```
sorted="$(printf '%s\n' $privkeys | LC_ALL=C sort)"
```

$privkeys is a space-separated accumulator, and the split into words is exactly what is wanted here. shellcheck disable=SC2086

```
if [ "$nkeys" -gt 5 ]; then
```

ONE IdentityFile PER COPIED KEY, not a guessed "preferred" name: this host has both id_gh and id_rsa, and ssh tries each. `IdentitiesOnly yes` stops ssh offering anything else. Keep the count small — past about five keys GitHub answers "Too many authentication failures" before ssh reaches the right one.

```
{
```

The ssh config is GENERATED, never inherited.

```
for k in $sorted; do printf '  IdentityFile ~/.ssh/%s\n' "$k"; done
```

One word per key, deliberately split. shellcheck disable=SC2086

```
printf '  StrictHostKeyChecking accept-new\n'
```

accept-new, and NEVER the `no` value: `no` disables host verification entirely instead of only the prompt. accept-new is the backstop that keeps the first connection from prompting when the keyscan below could not run. The forbidden spelling is kept out of this comment entirely, so a grep of the source finds it only if it has come back.

```
if [ ! -f "$HOME/.ssh/known_hosts" ] || ! grep -q 'github\.com' "$HOME/.ssh/known_hosts"; then
```

Pre-add GitHub's host keys (R1). Best-effort: it needs the network, so a failure is a warning, not an abort — accept-new covers it.

```
if [ ! -f "$GITCONFIG_SRC" ]; then
```

── 2 — git identity and HTTPS credentials (R2, R3) ─────────────────────────

Container-local and WRITABLE (0600), so `git config --global` inside a capsule still works. Every line after the include is a correction to something the host config does that cannot work in a container, and each one costs a debugging session if it is dropped:

```
* The host routes github.com through `helper = !gh auth git-credential`.
  `gh` is NOT in the image's closed toolbox, so an inherited helper makes
  every HTTPS push shell out to a missing binary. The empty `helper =`
  reset followed by the store helper is the same trick the host config
  itself uses — and it must be repeated PER URL, because a URL-scoped
  helper list overrides the generic one: a top-level reset alone leaves
  `!gh auth git-credential` in place for github.com, which is the whole
  point of the exercise.
* `core.pager = delta` and `interactive.diffFilter = delta --color-only`
  are inherited from the host, and delta is not in the image either —
  without these overrides `git diff` and `git log` fail inside every
  capsule. `cat` is a no-op filter; leaving diffFilter empty makes git
  run an empty command.
* The include is what satisfies R2: author, committer, aliases and every
  other host preference arrive from the mounted file, so authorship
  inside a capsule matches the host without copying anything.
* The host's `[includeIf "gitdir:~/dev/_pi_extensions/"]` names a path
  that does not exist here. Git ignores a missing include silently, so
  nothing is owed — noted so nobody "fixes" it.
```

The credential store file is read STRAIGHT FROM THE READ-ONLY MOUNT. Nothing is copied, and that is what makes a rotated token heal: the host rewrites that file and a running container sees the new content immediately. `git credential-store` only writes on `approve`, which git does not call for a credential a helper supplied, so a read-only store is the normal path and not a lurking error.

```
if [ -f "$CREDS/claude-credentials.json" ]; then
```

── 3 — the agents (R4) ─────────────────────────────────────────────────────

A SYMLINK for the credential and a COPY for .claude.json, and the asymmetry is the interesting part:

```
* The credential is symlinked into the read-only mount so a host-side
  refresh reaches even a RUNNING capsule, and so the container
  physically cannot write a token anywhere. It also cannot run its own
  OAuth refresh — which is deliberate, not an oversight: Claude's
  refresh ROTATES the refresh token, so a capsule refreshing on its own
  would invalidate the host's login. Borrowing the host credential and
  failing closed is the correct trade. The visible failure mode is on
  the manual checklist: if the access token expires while a long-lived
  capsule sits idle, `claude` inside it asks to log in, and re-mounting
  (or running `claude` on the host) heals it.
* .claude.json is written by Claude Code on every run, so it must be
  writable and container-local; a symlink into the read-only mount would
  make the agent fail on startup. It is the filtered six-key projection
  the host exports, so the copy carries onboarding state and account
  identity and no token.
```

```
if [ -f "$CREDS/opencode-auth.json" ]; then
```

Same reasoning for OpenCode. Everything else it writes — its database, logs, snapshots — stays container-local, which is the point: the host's 94 MB SQLite store is deliberately not shared into a container.
