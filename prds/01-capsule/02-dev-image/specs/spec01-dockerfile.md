# spec01 — the one image definition

Write `home/dot_config/capsule/Dockerfile`: the single dev-image definition
(R1–R7). chezmoi deploys it to `~/.config/capsule/Dockerfile`, which is the
path the capsule CLI (C.2) builds from and hashes for rebuild detection —
`tests/managed-config.sh:76` already declares `capsule` as the pending
`dot_config` surface, so the new directory trips no census gate. The
interactive layer comes from the legacy capsule image
(`~/.files/user/.config/WezTerm/Dockerfile`), the toolbox list from R2;
`devzsh` contributes nothing interactive (finding C-4: `CMD ["bash"]`, no
zsh, no agents).

**Est:** 3h

**Footprint:** `home/dot_config/capsule/Dockerfile`

## Design

Base `ubuntu:24.04`. `ENV DEBIAN_FRONTEND=noninteractive`,
`TERM=xterm-256color`, `LANG=C.UTF-8`. Layer order, cheapest-changing last
(R6):

1. **apt toolbox** — one `RUN apt-get install` holding exactly R2 plus the
   support set below, with `rm -rf /var/lib/apt/lists/*` in the same layer.
   Ubuntu name mapping: `fd-find` installs `fdfind`, `bat` installs
   `batcat` — symlink both to `/usr/local/bin/fd` and `/usr/local/bin/bat`
   (same convention as `install.sh` §1). `python3` + `python3-pip` is R2's
   Python.
2. **eza** — not in Ubuntu 24.04's archive. Fetch the GitHub release
   tarball for the build architecture: derive an `ARCH` variable from
   `uname -m`, pin the version in one `ARG`. Never a literal arch in a
   fetch URL — the host is Apple Silicon, containers are linux/arm64, and
   the legacy `devzsh` x86_64-pinned tarball is exactly the break this
   rule prevents.
3. **Node** — NodeSource `setup_lts.x`, then `nodejs` (R3: current LTS,
   major ≥ 22).
4. **Agents** — `npm install -g @anthropic-ai/claude-code`; OpenCode via
   its installer with the binary landing in `/usr/local/bin/opencode`
   (R4).
5. **oh-my-zsh** — system-wide: `ENV ZSH=/opt/oh-my-zsh`, unattended
   install, `chmod -R 755 /opt/oh-my-zsh` so the runtime user can read it
   (R1).
6. **User** — `useradd -m -s "$(command -v zsh)" dev`; passwordless sudo
   via a `/etc/sudoers.d/dev` drop-in, mode 0440 (R5). (The
   packages-installer's "no `/etc/sudoers.d` drop-in" item is a host
   provisioning rule; inside the container the drop-in is what R5 asks
   for.)
7. **Config layer, last** — write `/home/dev/.zshrc` in a `RUN` heredoc:
   `export ZSH=/opt/oh-my-zsh`, `ZSH_THEME="robbyrussell"`,
   `plugins=(git)`, `source $ZSH/oh-my-zsh.sh`. Baked so zsh never shows
   the zsh-newuser-install prompt. This zsh config is container-only; the
   host zshrc is not ported (R1). Editing this layer is the cache test's
   subject: it must invalidate nothing above it.

Close with `USER dev`, `WORKDIR /workspace`, `CMD ["sleep", "infinity"]` —
the container idles detached and C.2 execs in, which is what makes reconnect
instant. No `VOLUME /workspace`: an anonymous volume would shadow C.2's bind
mount and leak disk per run.

**Support set (the whole of it):** `curl`, `ca-certificates` (fetchers),
`sudo` (R5), `openssh-client` (epic acceptance: SSH and `git push` work
inside; C.3 R1 copies keys). Nothing else rides along — R7 makes R2/R3/R4
exhaustive, and `tests/dev-image.sh` (spec02) fails the build definition on
any package outside R2 + this list. Odin, `pi`, pi-oilrig stay out
(`## Decisions` in the PRD); so does the legacy `setup-user.sh` dotfiles
clone — no requirement names it, and credentials are C.3's, arriving by
mount, never in a layer.

No help entry is owed: the image adds no host command or keybinding, and
`capsule.nuon` already documents the tool surface against C.2's PRD.

## Acceptance

- [x] `home/dot_config/capsule/Dockerfile` exists and is the only
      Dockerfile in the repo (`find . -iname '*dockerfile*'` from the repo
      root finds exactly it). 2026-08-22: `tests/dev-image.sh --static`
      census PASS; the find excludes `*.md`, since this spec's own filename
      matches the glob and a markdown file builds nothing.
- [x] `docker build` completes with no interactive prompt on this host's
      native platform (no `--platform` flag, no literal arch in any fetch
      URL). 2026-08-22: cold build PASS in `tests/dev-image.sh --build`;
      arch-literal check PASS in `--static`.
- [x] In the built image: `whoami` prints `dev`, `id -u` is not 0, and
      `sudo -n true` exits 0. 2026-08-22: `dev` / `1001` / `SUDO-OK` (this
      spec's Verify block, run verbatim).
- [x] All on `$PATH` as `dev`: `rg`, `fd`, `fzf`, `tmux`, `nvim`, `bat`,
      `eza`, `git`, `cc` (build-essential), `python3`, `zsh`, `node`,
      `claude`, `opencode`; `node --version` major ≥ 22. 2026-08-22:
      `TOOLS-OK`, `node --version` → `v24.19.0`.
- [x] `dev`'s login shell is zsh, and `zsh -ic 'echo $ZSH'` prints
      `/opt/oh-my-zsh` with no zsh-newuser-install prompt. 2026-08-22:
      `getent passwd dev` → `/usr/bin/zsh`; probe printed `/opt/oh-my-zsh`,
      no newuser prompt in the transcript.
- [x] `docker inspect` shows `WorkingDir` `/workspace`, `User` `dev`, and
      `Cmd` `["sleep", "infinity"]`. 2026-08-22: all three PASS in
      `tests/dev-image.sh --build`.
- [x] An immediate second `docker build` of the unchanged definition is
      fully `CACHED`. (The edit-the-config-layer reuse proof is spec02's
      harness.) 2026-08-22: rebuild reproduced the same image ID.
- [x] The build context is the Dockerfile alone: no `COPY`/`ADD`, so no
      host file — and no credential — can enter a layer. 2026-08-22:
      `--static` no-ingress check PASS.

## Verify

```sh
# Assumes: docker CLI with a running daemon (the repo's assumed runtime —
# install.sh provisions the docker formula; Docker Desktop is live on this
# host) and network access (ubuntu/NodeSource/GitHub/opencode.ai). Cold
# build is network-bound: minutes, not seconds.
docker build -t capsule-spec01-verify home/dot_config/capsule \
  -f home/dot_config/capsule/Dockerfile
docker run --rm capsule-spec01-verify sh -c '
  whoami; sudo -n true && echo SUDO-OK; node --version;
  for t in rg fd fzf tmux nvim bat eza git cc python3 zsh claude opencode;
    do command -v "$t" >/dev/null || { echo "MISSING $t"; exit 1; }; done;
  echo TOOLS-OK'
docker run --rm capsule-spec01-verify zsh -ic 'echo $ZSH'
docker rmi capsule-spec01-verify
```
