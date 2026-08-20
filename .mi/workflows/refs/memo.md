# memo — how new data is created

A memo is a design record: what was decided, what it beat, why. It keeps the
expensive knowledge — what the code refused to do — which evaporates when the
session that decided it moves on.

- **format and gate** — [`.mi/docs/memos/memo-format.md`](../../docs/memos/memo-format.md)
- **how the system is run** — [`.mi/docs/memos/discipline.md`](../../docs/memos/discipline.md)
- **the memos** — [`.mi/docs/memos/`](../../docs/memos/)

Those are the homes. Not restated here: an authored copy is a cache with no
invalidation, and this file used to be one.

## Laws applied

- **1** — one home per fact; superseded is shadowed, never rewritten; the memo
  lands in the same commit as the change it explains
- **2** — a decision names each real alternative and why it lost
- **4** — one document form, discriminated by a declared type
