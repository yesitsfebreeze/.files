---
complexity: 8
footprint:
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - home/dot_config/nushell/help/why-review.nuon
---

# spec01 — `cdi` and `idioms` name the zi/cdi fzf pair, re-digested

Two text edits in `home/dot_config/nushell/help/shell.nuon` (R1, R2), each
re-digested through the gate's own helpers by a reader distinct from the
author (R3), plus the R4 census reported below for the orchestrator to
triage — nothing outside the two named entries is touched.

## R1 — `cdi` names its own picker

`cdi`'s `use` field (`shell.nuon:41`) is byte-identical to:

```
Alias for `zi` — the same picker under the name muscle memory reaches for.
```

Replace it with:

```
Alias for `zi` — the same fzf picker, not television, under the name muscle memory reaches for.
```

No other field of the `cdi` entry changes — `title`, `also`, `verify`,
`source` stand as they are.

**Pre-computed target digest** (verified by replicating `use-digest` from
`tests/help-content-model.nu` against the *current* `cdi` row before trusting
it — reproduces the recorded `3a8f2a6e5bdbbb23` exactly):

```
use-digest(new use, "prds/04-shell/03-zoxide/prd.md") = 5858094e40fddff5
```

`use-review.nuon`'s `cdi` row (currently `digest: "3a8f2a6e5bdbbb23"`,
`reviewer: "implementer-cdi-r1"`) is replaced with a fresh row: `digest:
"5858094e40fddff5"`, a `reviewer` who is not the session that wrote the new
`use` text, `date` set to the day of the edit. `cdi` carries no `why` field,
so `why-review.nuon` has no row for it and none is added.

## R2 — `idioms` names the pair, in `use` and in `also`

`idioms`'s `use` field (`shell.nuon:395`) is byte-identical to:

```
Nothing to run — four rules that stop an agent guessing. Search with `rg` and find with `fd`, never `grep`/`find`. Pick with television (`tv`) — the single exception is `zi`, which opens fzf, and it is the only place fzf belongs. Nushell commands return structured data, so filter with `| where`, not `| grep`. And `cd` here can create the directory it is given.
```

Replace it with:

```
Nothing to run — four rules that stop an agent guessing. Search with `rg` and find with `fd`, never `grep`/`find`. Pick with television (`tv`) — the single exception is `zi`/`cdi`, which open fzf, and it is the only place fzf belongs. Nushell commands return structured data, so filter with `| where`, not `| grep`. And `cd` here can create the directory it is given.
```

(One clause change: `zi`, which opens → `zi`/`cdi`, which open — everything
else byte-identical.) `title`, `topic`, `mode`, `why`, `verify`, `source`
stand as they are.

`idioms`'s `also` (`shell.nuon:398`) is currently
`["grep", "tv channel", "cd <path>"]`. Replace with
`["grep", "tv channel", "cd <path>", "zi", "cdi"]` — both ids already exist
in `shell.nuon`, so the gate's `also`-resolution check (every `also` target
must be a real entry id) passes on both.

**Pre-computed target digests**, same verification method as R1 — replicated
`use-digest`/`why-digest` against the *current* `idioms` row first and
reproduced the recorded `1acb724adbd09dab` / `27c66c667c57cd84` exactly
before trusting the new-text computation:

```
use-digest(new use, "prds/06-help/05-agent-interface/prd.md") = 3d5492ead89d795b
why-digest(new use, <idioms' unchanged why text>)             = d4c9704dea64ad73
```

Both `use-review.nuon`'s and `why-review.nuon`'s `idioms` rows change —
`use` is part of both digests, `why` is untouched but its digest still keys
on the `use`/`why` *pair*, so editing `use` alone invalidates it too:

- `use-review.nuon` `idioms` row: `digest: "3d5492ead89d795b"`.
- `why-review.nuon` `idioms` row: `digest: "d4c9704dea64ad73"`.

`also` is not part of either digest formula (`use-digest` keys on
`use`+`source`, `why-digest` on `use`+`why`) — the `also` edit needs no
re-digest of its own, only the `use` edit does.

## R3 — review ritual and retiring the stale note

For both re-digested rows (the `cdi` row in `use-review.nuon`, and the
`idioms` rows in `use-review.nuon` and `why-review.nuon`): the `reviewer`
recording the new digest must not be the same identity as whoever authored
the new `use` text — same shape as `cdi-manual-source` R2
(`prds/00-delivery/corrections/cdi-manual-source/prd.md`). Record `author`
and a distinct `reviewer` on each new row, and a `note` describing what the
reader actually checked (the digest replication above, plus that no other
field moved).

`use-review.nuon:156`'s existing `idioms` row note ends "... `idioms` does
not link `cdi` in `also`." — that is the defect this spec fixes, so the note
is retired (not left standing beside its own fix): the new row's note
describes the fix, not the old gap.

## R4 — census (report, do not fix)

Grepped `home/dot_config/nushell/help/*.nuon` for `use`/`why` text implying a
picker (fzf, television/tv, telescope) without naming which. Full population
below — copy this table into the implementer's DONE report verbatim; nothing
in this section is edited by this spec beyond the two entries R1/R2 already
cover.

| entry (file:line) | field | text | verdict |
|---|---|---|---|
| `cdi` (shell.nuon:41) | use | "the same picker" | **fixed by R1 above** |
| `idioms` (shell.nuon:395, :398) | use, also | names only `zi` | **fixed by R2 above** |
| `help --fuzzy` (shell.nuon:213) | use | "opens every entry in this manual as a picker" | gap — no `why` field to fall back on either; `why-review.nuon:92`'s `tv channel` row independently confirms this picker is television's `manual` cable channel, but the entry itself never says so |
| `Ctrl-R` (shell.nuon:225) | use | "a picker opens over the commands..." | gap, and sharper than it looks: live-checked `~/.config/nushell/config.nu:554` — `hist_picker_local` runs `tv_history_local`, i.e. this genuinely is television, the same as `Alt-R`'s `tv_shell_history` two entries down. `Alt-R`'s `use` (shell.nuon:236) names television explicitly; `Ctrl-R`'s does not, for the same kind of picker — an asymmetry across a documented pair, same shape as the zi/cdi gap this PRD fixes |
| `Ctrl+Shift+S` (terminal.nuon:244) | use | "a fuzzy-selectable list ... opens" | gap — names no tool at all. `01-capsule/04-recent-workspaces` is `blocked` (per `AGENTS.md`'s Known gaps), so the live mechanism (tv channel vs. a WezTerm-native selector) is not yet confirmable from this tree |
| `Ctrl+Shift+T` (terminal.nuon:257) | use | "Same picker as `Ctrl+Shift+S`" | gap — inherits the above by delegation |
| `capsule [dir]` (capsule.nuon:11) | use | "recorded for the recent-workspace picker" | gap — same family as the two terminal.nuon rows, tool unnamed |
| `<leader>fb` (nvim.nuon:283) | use | "get the open buffers as a picker" | minor gap — never says `telescope` in its own text, though `source:` and the file's own scope (nvim.nuon is telescope's surface, `topics.nuon:13` says so) make the tool inferable from context in a way `cdi`'s bare `also` hop was not |
| `mkcd` (shell.nuon:103, :107) | use, why | "picker jumps" / "recent-dirs picker" | not a gap — this is the funnel concept entry; it deliberately covers every jump route (real `cd`, zoxide, picker, bare-word) at once, so staying generic here is correct, not an omission |
| `Ctrl-Space / F1` (shell.nuon:152) | why | "picker entry point" | not a gap — the entry's own `use` already establishes television via "channel" (tv-specific vocabulary the `tv channel` entry defines), and the `why` here is qualifying that same established channel/tv context, not introducing a new unnamed one |
| `Ctrl-Q` (shell.nuon:170) | use | "finder picks" | not a gap — same "channel" vocabulary as above, and the same clause separately names "jumps" (zoxide) beside "finder picks" (tv), so the two picker families are already told apart |
| `finder` (shell.nuon:184) | why | "new pickers are new channels" | not a gap — "channel" is tv-specific vocabulary, unambiguous in context |

Twelve entries carry a `use`/`why` mention worth a verdict: two are R1/R2
(fixed by this spec), six are gaps outside this PRD's scope (`help --fuzzy`,
`Ctrl-R`, `Ctrl+Shift+S`, `Ctrl+Shift+T`, `capsule [dir]`, and the minor
`<leader>fb`), and four are not gaps — recorded so the same ground is not
re-walked by a later census.

## Acceptance

- [x] `cdi`'s `use` field reads exactly the new text above; every other field
      of the `cdi` entry is unchanged. Verified: `shell.nuon:41` now reads
      `Alias for \`zi\` — the same fzf picker, not television, under the name
      muscle memory reaches for.`; diffed the surrounding entry (`title`,
      `also`, `verify`, `source`) against the pre-edit read and nothing else
      moved.
- [x] `idioms`'s `use` and `also` fields read exactly the new text above;
      every other field of the `idioms` entry is unchanged. Verified:
      `shell.nuon:395` now reads `... the single exception is \`zi\`/\`cdi\`,
      which open fzf, ...` and `shell.nuon:398`'s `also` is now
      `["grep", "tv channel", "cd <path>", "zi", "cdi"]`; `title`, `topic`,
      `mode`, `why`, `verify`, `source` unchanged.
- [x] `use-review.nuon`'s `cdi` row carries `digest: "5858094e40fddff5"`,
      an `author` and a `reviewer` that are not the same identity. Verified
      by reading `use-review.nuon:123` — digest matches, `author:
      "implementer-zi-cdi-picker-exception"`, `reviewer:
      "reader-zi-cdi-picker-exception"`, distinct identities.
- [x] `use-review.nuon`'s `idioms` row carries `digest: "3d5492ead89d795b"`,
      an `author` and a `reviewer` that are not the same identity, and its
      note no longer describes the `cdi`-omission defect as still standing.
      Verified by reading `use-review.nuon:156` — digest matches, distinct
      author/reviewer, and `rg -n 'does not link .cdi. in .also.'
      home/dot_config/nushell/help/use-review.nuon` finds nothing (exit 1).
- [x] `why-review.nuon`'s `idioms` row carries `digest: "d4c9704dea64ad73"`,
      an `author` and a `reviewer` that are not the same identity. Verified
      by reading `why-review.nuon:100` — digest matches, `author:
      "implementer-zi-cdi-picker-exception"`, `reviewer:
      "reader-zi-cdi-picker-exception"`, distinct identities.
- [x] The R4 census table above is quoted in the implementer's DONE report,
      unedited beyond formatting. Quoted verbatim in the DONE report below.

## Verify and Proof

```sh
nu tests/help-content-model.nu
rg -n 'fzf' home/dot_config/nushell/help/
```

Both commands are scoped to this PRD's footprint (the help corpus and its
own gate) — neither reaches outside `home/dot_config/nushell/help/` or
`tests/help-content-model.nu`.
