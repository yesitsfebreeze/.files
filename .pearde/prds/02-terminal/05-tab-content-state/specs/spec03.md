---
est: 0.5h
footprint:
  - home/dot_config/nushell/help/terminal.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - home/dot_config/nushell/help/why-review.nuon
---

# spec03 — the manual entry for the lit/dim tab bar

T.6 lands a visible behaviour, so T.6 lands its manual entry in the same
change (the working contract, and `06-help/04-drift-check` deps on this
node). One new entry, one `use-review` row, one `why-review` row. Land after
spec01: the entry describes landed behaviour.

The entry is a `cmd` entry with `verify: [{kind: "prose"}]`, following the
`nine tabs` entry in the same file — this node binds no key and adds no
command, and `prose` is the kind for a behaviour with no introspectable
handle. Do not invent a `wezterm-key` target for it: a tab colour is not
addressable from `show-keys`, and a target that resolves off something else
is a false pass.

## The entry

Append to `home/dot_config/nushell/help/terminal.nuon`, next to the
`nine tabs` entry — this pair is the tab bar's whole story.

```nuon
{
    cmd: "lit and dim tabs"
    title: "See which tabs have something running"
    use: "Nothing to press. A tab whose panes are all sitting at a prompt shows its digit in the dim inactive colour; a tab with a command running anywhere inside it shows the same digit lit, so one glance at the bar says where the work is. It settles by itself within five seconds of a command starting or finishing, with nothing to refresh, and a focused tab looks the same whether it is busy or not."
    topic: "terminal"
    mode: "terminal"
    also: ["nine tabs", "F5 <digit>"]
    why: "The signal is the pane's foreground process, not its prompt: OSC 133 prompt marking is deliberately off, because it double-marks starship's two-line prompt under WezTerm and leaves a phantom blank line behind. Which process counts as idle is learned rather than named — the first program WezTerm puts in a pane is that pane's baseline, so no shell name appears anywhere and the reading survives a change of shell. Five seconds is the status tick, and it is the whole mechanism rather than a delay: this WezTerm emits no event for a pane opening or closing, so the tick is what notices, and it is also what lets a tab go dim again after a process is killed from outside. Brightness and background are kept as two separate channels on purpose: the background says which tab has focus, the digit says which tabs are busy, so neither reading has to be decoded out of the other."
    verify: [{kind: "prose"}]
    source: "prds/02-terminal/05-tab-content-state/prd.md"
}
```

Constraints the gate holds this to, all of which the text above already
meets — re-check them rather than trusting this list:

- `title` opens with `See`, a base-form verb on `IMPERATIVE_VERBS`; one
  line, no trailing period.
- The opener rule ("a `key` entry never opens by restating its key") is
  scoped to `key` entries, so a `cmd` entry is exempt — but `use` opens with
  the gesture anyway, the way `nine tabs` does.
- `use` clears the five-word floor by a wide margin, and `why` states only
  mechanism the `use` does not: the `use` says *what you see and when*, the
  `why` says *what is being read, why it is learned and not named, and why
  the tick is the mechanism*.
- `also` targets must resolve. `nine tabs` and `F5 <digit>` are both ids in
  this file.
- `topic` is `terminal`, one of the nine in `topics.nuon`; `mode` is
  `terminal`, because this is host-only — a shell inside a container cannot
  see a tab bar.

## The two review rows

Both digests are the first 16 hex characters of a sha256 over a
`\n--\n`-joined pair, exactly as `tests/help-content-model.nu` computes
them. Compute them, never hand-write them:

```nu
# Run from a file, not with `nu -c`: an interpolated string nested inside
# another one is a parse error, so the two digests are bound first.
let e = (open home/dot_config/nushell/help/terminal.nuon
    | where {|r| ($r.cmd? | default "") == "lit and dim tabs" } | first)
let ud = ($"($e.use)\n--\n($e.source)" | hash sha256 | str substring 0..15)
let wd = ($"($e.use)\n--\n($e.why)" | hash sha256 | str substring 0..15)
print $"use-digest: ($ud)"
print $"why-digest: ($wd)"
```

Recipe validated 2026-08-23 against the `nine tabs` row: it recomputes that
row's recorded `e6c556069b82c868`, so a mismatch on the new row is the
entry's problem and not the recipe's. Both files are 1:1 with the corpus
today — 91 entries and 91 `use-review` rows, 58 `why`s and 58 `why-review`
rows — so a missing row is a gate failure, not an omission the gate
tolerates.

- `use-review.nuon`: one row `{id: "lit and dim tabs", file:
  "terminal.nuon", digest: <use-digest>, reviewer: …, author: …, date: …,
  note: …}`. The `note` records the reading: which lines of
  `home/dot_config/wezterm/wezterm.lua` produce each claim in the `use` —
  the dim state from `colors.tab_bar.inactive_tab`, the lit state from the
  `AnsiColor = "Silver"` return, "within five seconds" from
  `status_update_interval = 5000` and the four `learn_pane_programs`
  registrations, and "a focused tab looks the same" from the `tab.is_active`
  early return. State plainly that this was read against the **source tree**
  and not against a live GUI, and that the visible half is the T.6 rows in
  `gates/manual/wave4.md`.
- `why-review.nuon`: one row of the same shape carrying the why-digest, and
  a `note` that checks each of the four claims against its own source: OSC
  133 against [`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md)
  R5, the learned baseline against this node's R4, the missing pane events
  against the tab reconciler's own comment in `wezterm.lua`, and the
  two-channel split against this node's R3.
- `reviewer` must not equal `author` in either row — a review that vouches
  for its own writing is what that check exists to refuse. Use the
  `<name>` / `<name>-rN` shape the existing terminal rows use.

## Acceptance

- [x] `nu tests/help-content-model.nu` exits 0 with the new entry and both
      review rows in place. Ran: `ok`, rc 0, and the topic census now shows
      `terminal 13` (was 12). Corpus stays 1:1 — 92 entries and 92
      `use-review` rows, 59 `why`s and 59 `why-review` rows.
- [x] Removing the `why-review` row makes the same gate fail, and quoting
      that failure is the proof the digest is real rather than decorative.
      Ran twice. With the row deleted:
      `terminal.nuon [lit and dim tabs]: carries a `why` with no row in
      why-review.nuon — read it against its `use` for restatement, then
      record the pair`. And with the row present but its digest set to
      `0000000000000000`:
      `terminal.nuon [lit and dim tabs]: `use`/`why` changed since the
      recorded review — re-read the pair for restatement, then set digest
      to 3bbefb68ebf1f401`. The second is the stronger proof: the digest
      binds to the prose, not merely to the row's existence. Both were
      restored and the gate is green again.
- [x] `open home/dot_config/nushell/help/terminal.nuon | where {|r|
      ($r.cmd? | default "") == "lit and dim tabs" } | length` is `1`, and
      its `source` resolves to an existing file. Ran: `1`, and
      `test -f prds/02-terminal/05-tab-content-state/prd.md` → `source ok`.
      The two review rows are `1` each as well.
- [x] `bash gates/manual-coverage.sh` and
      `bash tests/wezterm-tab-content-state.sh` stay green. Ran: rc 0
      (`green`) and `ALL PASS`.

Digests, computed with the recipe above and never hand-written —
`use-digest: 5de7908e99fe928a`, `why-digest: 3bbefb68ebf1f401`. The recipe
was re-validated against the `nine tabs` row in the same run before either
was recorded: it recomputed `e6c556069b82c868` and `b3db4cf38ed1176a`, both
matching what that row already carries, so a mismatch on the new row would
have been the entry's problem and not the recipe's. `reviewer` is
`implementer-tab-content-state-r1` and `author` is
`implementer-tab-content-state` in both rows, so neither review vouches for
its own writing.

## Verify and Proof

```sh
nu tests/help-content-model.nu
nu -c 'open home/dot_config/nushell/help/terminal.nuon | where {|r| ($r.cmd? | default "") == "lit and dim tabs" } | length'
nu -c 'open home/dot_config/nushell/help/use-review.nuon | where id == "lit and dim tabs" | length'
nu -c 'open home/dot_config/nushell/help/why-review.nuon | where id == "lit and dim tabs" | length'
bash gates/manual-coverage.sh
bash tests/wezterm-tab-content-state.sh
```
