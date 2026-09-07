---
kind: knowledge
description: capsule is one directory, one container, one CLI — content-hash rebuild detection, creds by read-only directory mount, never an image layer
read_when: "touching capsule, the Dockerfile, or container credentials"
---

# capsule-is-one-directory-one-container

One directory, one dev container, one CLI (`capsule [dir] [--rebuild]` plus
`list`/`clean`). The rules each backed by a failure:

- **Every docker and tv call goes through `^docker`/`^tv`**, so a PATH shim can
  observe or stand in for every one and the tool can be exercised against a
  recording shim without touching the real daemon.
- **The tool has no working directory of its own**: everything downstream of
  argument parsing uses the expanded `$target` only; no `cd` is ever made. The
  legacy `mount` failed on exactly this — it moved itself to a non-existent
  hardcoded directory and mounted a `workspace/` subdirectory instead of the
  directory it was handed.
- **Rebuild detection is a content hash in an image label**, not mtime and not
  a side state file: the sha256 of the Dockerfile rides on the image as
  `capsule.dockerfile`, so a `touch` never triggers a rebuild and there is no
  second file to drift. The auto path updates the image only and attaches to
  the existing container; `--rebuild` is the one recreate gesture, because
  recreation destroys container-local state and the cheap mistake has to be
  the safe one.
- **Credentials arrive by read-only mount and never by image layer** — no
  COPY, no ADD in the Dockerfile. The export directory is
  `~/.cache/capsule/creds`, **not** `~/.config/capsule`: the latter is the
  docker **build context**, so a token there is one `COPY .` away from a
  layer. The creds path is bound as a **directory**, never as individual
  files — a file bind pins an inode and the refresh replaces each file by
  rename, so a file bind would keep showing a running container the old token
  forever; a directory bind shows the rename immediately, which lets a rotated
  credential heal a running capsule.
- **`--rebuild`'s removal guard is the `capsule.dir` label being non-empty**:
  with the emptiness test neutered, `--rebuild` against a same-named container
  carrying no label asked docker to remove it (measured). Nothing holds that
  down but the refusal; a refactor re-runs that counterfactual by hand.

Container names are deterministic — `capsule-<sanitised-basename>-<hash8>`,
the hash always appended — so the same directory is the same container on
every invocation and two `api` dirs in different parents differ, with no
registry to consult. Recents are state in `~/.cache/capsule`, never
`~/.config`, so `chezmoi apply` never touches them.