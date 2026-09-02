---
memo: a-retirement-is-two-edits-and-is-proven-at-the-deployed-path
kind: decision
status: decided
tags:
  - memo
  - kind/decision
  - status/decided
subject: retiring a file from this configuration is two edits — the source file goes and its deployed target path is listed in home/.chezmoiremove — and the retirement is proven at the target path, never at the source or by an apply's exit code
date: 2026-09-02
prds:
  - 09-simplify/retire-the-unmanaged-television-channels
  - 09-simplify/retire-the-two-unmanaged-television-preview-scripts
---

# a-retirement-is-two-edits-and-is-proven-at-the-deployed-path — deleting the source is half of it

## Decision

A file leaves this configuration in **two edits, in the same change**:

1. the source file is deleted from `home/`, and
2. its destination-relative target path is appended to `home/.chezmoiremove`
   — one path per line, relative to `$HOME`, no `dot_` prefix and no leading
   `./`.

The retirement is then deployed by naming the **target** paths to
`chezmoi apply` — `chezmoi apply ~/.config/television/cable/alias.toml`, one
name per retired file. Applying `.chezmoiremove` itself, or the directory
above the targets, deploys nothing.

It is proven at the deployed path and nowhere else:

```sh
test ! -e ~/.config/<name>
grep -qxF '<target>' home/.chezmoiremove
```

The apply's own exit code is not the proof. Where the retirement is intended
and the target may have drifted, `chezmoi apply --force <target>`.

## Why

`chezmoi apply` only writes and updates; it never reaps an orphan. Deleting a
source file makes the deletion true of the repo and false of every machine the
file was already deployed to — chezmoi simply stops managing the path and
leaves the copy where it is. Measured in this repo on 2026-09-02: four source
files deleted, a scoped apply run, all four targets still present under
`~/.config`. Recorded as
[[deleting-a-chezmoi-source-is-half-a-retirement-the-other-hal]].

The second edit is the part the repo carries. Fixing it by hand — `rm
~/.config/…` — retires the file on the machine in front of you and on no
other; the next machine still holding the old deploy never hears about it. The
`.chezmoiremove` line travels with the commit, so the retirement holds
wherever the configuration lands.

The proof has to sit at the target because the removal is state-dependent and
can fail loudly. When the target is byte-identical to what chezmoi last wrote
and chezmoi's state still knows the entry, a scoped apply removes it silently
at exit 0. When the target differs from what chezmoi last wrote — or chezmoi
has already forgotten the entry — apply *prompts*, and with no controlling
terminal that is not a skip: it is `could not open a new TTY` and exit 1 for
the whole apply. So a green headless apply is not evidence the file is gone,
and a red one is not evidence the retirement is wrong. Only `test ! -e` at the
target path settles it.

This board has already been living the rule rather than deciding it. Both
`retire-the-unmanaged-television-channels` and
`retire-the-two-unmanaged-television-preview-scripts` were worked this way,
`home/.chezmoiremove` has grown to eighteen lines across those passes, and
`.pearde/workflows/apply-scoped-not-bare.md` has nine runs encoding the same
steps. The memo makes the call explicit so the next retirement does not
re-derive it from a workflow's step 3.

## Alternatives considered

**A bare `rm` at the target, source deletion only** — the obvious one, and the
one the tool's behaviour invites. It leaves nothing in the repo that says the
path was retired, so the deletion is a property of one machine's filesystem
rather than of the configuration. Every other machine keeps the orphan, and
nothing in a later checkout can tell a file that was never deployed from one
that was deployed and abandoned.

**Trust the apply's exit code as the proof** — cheapest to write, and wrong in
both directions. A scoped apply that removed nothing exits 0 exactly as
happily as one that worked, and an apply that hit an edited target exits 1
while the retirement is entirely correct. Verifying the observable — the
target path's absence — is the only check that measures the thing the
retirement is for.

**Assert at the source path (`test ! -e home/dot_config/…`)** — passes the
moment the first edit lands, which is precisely the half of the retirement
that has no effect on any machine. It would have gone green on the 2026-09-02
measurement where all four targets were still deployed.

**`chezmoi apply --force` everywhere, as the default** — it answers the prompt
and gets headless applies green, but it also overwrites unrelated local edits
on every path in the same run. Kept as the narrow escape hatch for a
deliberate retirement, not promoted to the standing verb.

## Consequences

- Every retirement is now a two-line diff at minimum, and a review that sees a
  deleted file under `home/` with no matching `.chezmoiremove` line should
  read as incomplete.
- `home/.chezmoiremove` grows monotonically and is never pruned. A line for a
  path no machine still carries is inert, so the cost is a file that only ever
  gets longer.
- A retirement can still turn a headless deploy red on a machine where the
  user had edited the file being retired. That is not fixed here — the deploy
  script owes either `--force` where the retirement is intended, or an
  absence assertion in place of trusting the apply.
- Nothing here retires a path this repo never managed by any route other than
  `.chezmoiremove`; that premise was settled separately on
  `retire-the-unmanaged-television-channels` and is not reopened.
