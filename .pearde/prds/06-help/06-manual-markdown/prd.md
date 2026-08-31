---
state: done
commit:
claim:
priority: 8
est: 2h
task: H.6
mode: afk
needs:
  - 06-help/01-content-model
  - 06-help/03-browser
  - 04-shell/04-television
footprint:
  - scripts/generate-manual.mjs
  - home/dot_config/nushell/help/manual/
  - home/dot_config/nushell/help/README.md
  - home/dot_config/television/cable/docs.toml
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/help/shell.nuon
  - justfile
verify: ""
---

# The manual as markdown, and `?`

Parent: [Help epic](../prd.md) · C 3 · U 8 · net-new

Purpose: `help` answers "what is this key called". Nothing answered "I
remember a sentence about OSC 52 and I want the file it is in". A fumadocs
site was built for that on 2026-08-31 and deleted the same day — a manual you
have to `npm run dev` before you can read is a manual nobody reads. This node
is what replaced it: the same content as plain markdown shipped with the
shell, and one television channel that greps every line of it and opens the
hit in `$EDITOR` at that line. The decision is
[the memo(../../../../prds/memos/the-manual-is-markdown-a-site-you-must-start-is-not-read.md).

## Requirements
- [x] **R1** — **The manual is markdown under the chezmoi source**, at
      `home/dot_config/nushell/help/manual/`, deployed by `chezmoi apply` to
      `~/.config/nushell/help/manual/` beside the `.nuon` corpus it is
      generated from. No build step, no server, no `node_modules` — reading it
      requires nothing but the files.
- [x] **R2** — **`guide/` and `reference/` are generated**, by
      `scripts/generate-manual.mjs` (`just manual`), from `tasks.nuon`,
      `topics.nuon` and the four surfaces — the same inputs `help` reads, so
      the pages and the shell cannot disagree (epic I1). Every generated file
      opens with a GENERATED banner naming the script. 14 guide pages, 9
      reference pages, 101 entries as of 2026-08-31, 112 after the claude `<leader>a*` set landed the same day.
- [x] **R3** — **`internals/` and `index.md` are hand-written**, and are the
      one place a long *why about a file* lives — the constraints the configs
      used to carry as comments. Nine files, ~4,000 lines, moved across from
      the deleted site's MDX with `<Callout>` flattened to a blockquote,
      `<Cards>` to a list, and `/docs/...` links rewritten relative.
- [x] **R4** — **A `docs` cable channel**, line-level: `rg` over every line of
      that tree, `bat` preview at the hit, `enter` opens `$EDITOR` at that
      line. Rows carry the SHORT relative path (an absolute `/Users/...`
      prefix is 30 columns of picker saying nothing); the `output` template
      re-absolutises with a literal `~/` prefix, because `finder.nu`'s
      `GrepList` decode `path expand`s the file field against the **caller's**
      cwd, which is not the channel's.
- [x] **R5** — **`docs`, and `?` as its alias.** Both are `finder --start
      docs`, so the existing typed decode and `_finder_open` do the opening
      and the `Ctrl-Space` remote lists the channel for free — `_finder_type`
      gains one arm, `"text" | "docs" => "GrepList"`, and nothing else in
      finder.nu changes. Interactive-only, guarded like `finder` itself.
- [x] **R6** — **It does not replace `manual`.** That channel matches an
      ENTRY out of the corpus and prints it; this one matches a LINE of prose
      and opens the file. Two searches, deliberately: a key you half-remember
      versus a sentence you half-remember. Both cable files say so.
- [x] **R7** — **Both new invocations are documented in the same change**,
      as `shell.nuon` entries sharing `does: "search-manual"` so the guide
      renders them as one block, with `verify` targets `{kind: "command",
      name: "docs"}` and `{kind: "alias", name: "?"}` for `help --check`.

## Acceptance
- [x] `tv list-channels` lists `docs` — checked on tv 0.15.9, deployed.
- [x] The channel's source command returns 3,676 rows over the deployed tree.
- [x] Driven through a pty (`script -q /dev/null tv docs`, query "parse
      time", `enter`), the confirmed row is
      `~/.config/nushell/help/manual/internals/tmux.md:312` — literal tilde
      prefix, real line number, which is R4's whole mechanism.
- [x] `_finder_decode {produces: "GrepList", results: [that row]}` returns
      `{file: /Users/feb/.config/.../internals/tmux.md, line: 312, text: ""}`,
      so `_finder_open` runs `nvim +312 <file>`.
- [x] `nu -n -c 'source ~/.config/nushell/help.nu; docs'` errors with the
      interactive-only guard rather than parsing wrong or hanging.
- [x] `scope aliases` carries `?` and `scope commands` carries `docs` after
      sourcing help.nu.
- [ ] A person runs `?`, types a phrase, and lands in Neovim on the right
      line. **Not done** — the pty drive above proves the row tv emits and
      the decode of it, not the editor launch. Belongs with the other
      never-verified checks: `manual → internals/unverified`.
- [x] `help --check` reports **stale 0, mismatched 0** with the two new
      entries in place, and neither `docs` nor `?` appears in its findings —
      so both `verify` targets resolve against the live shell. It still exits
      non-zero on **16 undocumented** bindings, every one of them
      pre-existing and unrelated: four television-init bindings
      (`tv_completion`, `tv_history`, `tv_shell_history`,
      `tv_smart_autocomplete`) and twelve `<leader>a*` Neovim maps belonging
      to [`08-claude-agent`](../../08-claude-agent/prd.md), which is unbuilt.
      Three `unresolved` are the known buffer-local autopairs/`q` maps.

## Out of scope
- Anchors, cross-page link resolution, and a full-text index. `rg` re-reads
  the tree per keystroke; at ~8k lines that is free and at 80k it would not be.
- Editing from the picker landing on the chezmoi *source* rather than the
  deployed copy. It lands on the deployed copy, and for `internals/` that is a
  trap — an edit there is lost at the next `chezmoi apply`. Recorded in the
  memo rather than solved.

## Owed to a reader
The two new `shell.nuon` entries have **no `use-review.nuon` row and no
`why-review.nuon` row**. The session that wrote them may not also vouch for
them, and the gate that used to refuse a self-vouched row was deleted with
`tests/` on 2026-08-31 — so this is a debt recorded in prose rather than one
the tree enforces. A reader who did not write them owes both rows.
