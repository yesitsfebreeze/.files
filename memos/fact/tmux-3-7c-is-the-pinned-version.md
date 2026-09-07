---
kind: fact
description: tmux 3.7c is the pinned version — the tmux.conf behaviour and key-table semantics depend on it
read_when: "upgrading tmux, or asking why a behaviour broke"
---

# tmux-3-7c-is-the-pinned-version

Every measurement in the tmux internals was taken on **tmux 3.7c**. The
constants — `escape-time 10` (the default for years; stated anyway so the
file is right on an older host that ships a real `tmux-256color` but an
older binary), `allow-passthrough` as a window option, the second-lookup
drop of a pushed table, the `pane-border-lines: spaces` semantics that prove
in tmux 3.7c against a three-pane layout — all hold on 3.7c. Re-measure any
constant that names a specific build before trusting it on another.

A tmux `3.5` and below needs the explicit `escape-time 10` because the
default is 500; 3.7c already defaults to 10. A 3.4 needs the
`padded`/`none` strings in `pane-border-lines` rejected — that version does
not know them. The five border tables are the whole set.