# Feature: Agent interface

Parent: [Help epic](00-epic.md) · C 3 · U 8 · net-new

## Summary

Agents are a first-class reader of this manual, not an afterthought. An agent
that runs one command should learn how to operate this environment correctly —
which finder is installed, how navigation works, what the keys do — instead of
guessing from defaults.

## Requirements

1. **Structured output.** `help --json` emits the full manual as one JSON
   document: topics, entries, and every field from
   [01-content-model](01-content-model.md). Stable field names — this is an
   interface, so renaming a field is a breaking change.
2. **Document output.** `help --md` emits the whole manual as markdown,
   grouped by topic. This is what gets pasted into an issue, read by an agent
   that prefers prose, or written to a file for review.
3. **Plain by default under capture.** With stdout not a TTY, plain `help`
   already emits unstyled text ([02](02-help-command.md), requirement 7), so
   an agent that just runs `help` gets something usable without knowing about
   any flag. `--json` is the optimization, not the requirement.
4. **Discovery.** Agents only use what they know exists, so:
   - `AGENTS.md` states that `help` is the manual and should be consulted
     before suggesting shell or editor workflows;
   - the entry for a surface names the tool actually installed, so an agent
     reads "television (`tv`)" and stops reaching for `fzf`;
   - the `agents` topic documents the agent-facing surface itself: `cc`/`cr`
     ([04-shell/08](../04-shell/08-claude-launchers.md)), how capsules get
     credentials ([01-capsule/03](../01-capsule/03-credential-propagation.md)),
     and `help --json` itself.
5. **Idioms, not just keys.** Include the handful of "do it this way here"
   rules an agent would otherwise get wrong: `rg`/`fd` over `grep`/`find`,
   `tv` as the picker, nushell pipelines return structured data (so
   `| where`, not `| grep`), and the fact that `cd` in this shell can create
   directories.
6. **Honest boundaries.** Entries mark host-only vs container-available
   ([02](02-help-command.md), requirement 9) so an agent inside a capsule
   isn't told about WezTerm keys it cannot press.

## Acceptance criteria

- `help --json | jq '.topics | length'` works, and every entry visible in
  `help --all` is present in the JSON.
- A fresh agent session, given only the output of `help`, can navigate
  (bare-word jump), find a file (`Ctrl-Space` or telescope), and start a
  capsule — without inventing a tool that isn't installed.
- `help --md > manual.md` produces a document readable top to bottom.
- Renaming a JSON field requires updating this PRD's field list.
