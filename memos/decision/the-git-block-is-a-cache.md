---
kind: decision
date: 2026-09-29
status: decided
description: The prompt's git block is drawn from a cache a background job refreshes, and the ahead/behind arrow is gone — the prompt never waits for git
read_when: "touching the prompt, starship.toml or gitseg.nu, or asking why the git block lags a commit or where the right prompt and the up-arrow went"
---

# the-git-block-is-a-cache

## Decision

The prompt renders instantly and never runs `git` on the critical path.
starship.toml keeps the static segments (os, username, directory, language
versions, duration) and draws a literal `GITSEG` where the git block used to
be; gitseg.nu replaces it per render with a segment read from a cache file
that a pre_prompt `job spawn` refreshes. The right prompt is off
(PROMPT_COMMAND_RIGHT is `""`), and the git block no longer shows the
ahead/behind `⇡`.

## Why

- Measured 2026-09-29: `git status` in a working repo is the slowest thing
  the prompt ever did — 479ms of starship in-process time in kern2 under
  load, 2.9s raw — and nushell evaluates PROMPT_COMMAND synchronously, so
  it sat between every command and its result. The starship spawn itself
  (~85ms under the same load) is the floor left; removing the git scan is
  what makes the prompt sub-snappy.
- The `⇡` computation (`git rev-list --left-right @{u}...HEAD`) was the
  largest single cost inside git_status and walked the whole upstream
  history per render for a reminder `git push` already answers.
- The right prompt was a second full starship spawn per render whose
  measured output was empty: a spawn a render for nothing.
- `job spawn` is the one async primitive this tree already trusts —
  capsule.nu used it for credential refresh — so the "loader then replace
  view" pattern costs ~100 lines of nushell, not a framework. The same
  reasoning gated `stty sane` in the PWD hook behind a TUI sniff instead
  of paying ~50ms on every cd.

## Consequences

- The git block can lag reality by one refresh cycle: after `git commit`
  the new state shows on the first prompt that renders after the job
  lands. `⋯` marks the gap when a cache is cold.
- The cache is one file per repo root under `$state/nushell/gitseg/`,
  written atomically (tmp + rename, pid-suffixed) so two panes in one repo
  never interleave.
- starship.toml now lives under chezmoi (`home/dot_config/starship.toml`);
  it was the one shell config the repo did not manage.
- `~`'s prompt is unchanged: a non-git directory shows the same arrows
  around an empty segment that the old empty git modules produced.