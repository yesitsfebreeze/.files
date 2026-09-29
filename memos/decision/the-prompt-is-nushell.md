---
kind: decision
date: 2026-09-29
status: decided
description: The prompt is drawn by nushell itself (prompt.nu) — starship, its config and its per-render spawn are gone
read_when: "touching the prompt, prompt.nu or the SGR constants, or asking where starship went and why the blue duration segment is empty"
---

# the-prompt-is-nushell

## Decision

prompt.nu draws the prompt at ~0.6ms a render. Starship is removed from the
Brewfile, its config from chezmoi, its generated init from the generator —
the prompt is the shell's own code, and the render path has zero external
processes. The git block and the language-version blocks come from gitseg
caches that background jobs refresh (the-git-block-is-a-cache); every other
block is a constant or an env lookup.

## Why

- Starship was the last external process between every command and its
  result: 229ms median per render measured under load ~74, ~20-40ms at
  rest. Its modules were all static for this prompt — the os glyph, the
  username, the directory, the duration character — and the two slow ones
  (git status, toolchain probing) were already cached by gitseg.
- The parity work hexdumped the real prompt output rather than trusting the
  config file, and the dumps paid twice: the powerline arrows and the
  character glyphs were EMPTY strings (the look is adjacent colour blocks),
  and the blue duration segment had never fired once — nushell's
  `$env.CMD_DURATION_MS` is not updated per command (measured 0.115.1: "0"
  after `sleep 1`), so a block the config faithfully carried was dead
  weight for its whole life.

## Consequences

- The SGR constants in prompt.nu are byte sequences from those dumps, and
  the render is diffed against them in internals/nushell-modules — a
  visual change to the prompt is now a deliberate edit of those constants,
  not a starship.toml rebuild.
- The blue duration segment stays empty, deliberately. A real per-command
  duration cannot be built on nushell 0.115: pre_prompt fires only at
  submit (~3ms after Enter, before the command runs), the after-command
  render fires no hook at all, and PROMPT_COMMAND closures run in an
  isolated env — writes are silently discarded, so no render-count state
  is possible. The fix belongs upstream; a tick machine against these
  semantics was built, measured as broken, and deleted.
- The directory block's truncation rules (repo-relative inside a repo, one
  leading `…`, last-three collapse) were derived by measurement and are
  documented in internals/nushell-modules — they are ours to maintain now.
- A language block appears one render late the first time a directory with
  its marker is entered (probe job, one-hour cache); an absent tool caches
  an empty answer, not a retry.