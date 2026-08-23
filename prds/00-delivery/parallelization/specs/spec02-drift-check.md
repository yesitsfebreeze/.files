---
est: 1.25h
footprint:
  - prds/00-delivery/parallelization/check-waves.py
---

# spec02 — `check-waves.py`, the proof that the body still matches the board

Write `prds/00-delivery/parallelization/check-waves.py`: a check that reads
[`prd.md`](../prd.md), `gates/waves.tsv`, `prds/settings.md` and every node's
frontmatter, and **exits non-zero** when the document's claims and the board
disagree. It is this node's `verify:`; a document whose only proof is a human
reading it is unproven.

Run [spec01](spec01-rules-not-a-table.md) first — this parses the tables that
spec defines. Write **nothing** under `gates/`: `gates/waves.tsv` is held by
the `02-keymaps` lane, and any `gates/*.sh` declaring `--selftest` is pulled
into the `gates/selftest.sh` contract, which this check cannot honour — it
reads the live board, the one class `selftest.sh` documents as unattributable
under concurrency.

Python 3, stdlib only. No dependency on `sync.py`'s internals except invoking
it as a subprocess.

## The frontmatter parser is the point

`sync.py`'s `parse_prd` handles block lists only, and that blindness is the
defect this node exists to expose. **This check must parse both forms** —
block `key:` + `  - item` and inline `key: [a, b]` — strip trailing
`# comments`, strip quotes, strip trailing `/`. Reusing `sync.py`'s parser
would inherit the bug and report green.

## Inputs

| input | read for |
|---|---|
| `gates/waves.tsv` | wave → task ids (skip `#` lines and the `wave` header; tab-separated, field 1 and 2) |
| every `prds/**/prd.md` | `task:`, `state:`, `footprint:`, `needs:`, `deps:` |
| every `prds/**/specs/*.md` | `footprint:` |
| `prds/settings.md` | `workers:` |
| `prd.md` | the shared-registry pattern list, the exception table, the adversarial-verify node paths |
| `sync.py plan` | the `workers=` value and each `wave N — M in parallel` line |

Task → node comes from `task:` frontmatter, the same resolution
`gates/wave-status.sh` uses. Never a second hand-kept list.

Footprint of a node = union of its own `footprint:` and every
`specs/*.md` `footprint:`. Overlap = `a == b or a.startswith(b + "/") or
b.startswith(a + "/")`, matching `sync.py`'s `overlap`.

## Assertions

Each is one line of output, `PASS` / `FAIL`, and each must be able to fail.

1. **Registry integrity is delegated, not duplicated.** Shell out to
   `bash gates/wave-status.sh --validate` and fail on non-zero. That is where
   "every task in exactly one wave" is already proven; re-implementing it
   would be the second copy this node keeps deleting.
2. **No live-vs-live overlap on an exclusive content path.** For each wave
   row, for each pair of tasks both in a state other than `done`: overlapping
   paths that match no shared-registry pattern must be covered by an
   `ordered` row in `prd.md`'s exception table naming both tasks. An uncovered
   pair is a FAIL naming the wave, both task ids, both node paths and every
   offending path. Measured 2026-08-23: **0 such pairs**, so this passes today
   and goes red the first time two lanes are pointed at one file.
3. **No stale exception row.** Every `ordered` row in `prd.md` must correspond
   to a real overlap between the tasks it names, on the path it names. A row
   describing an overlap that no longer exists is a FAIL — this is what caught
   the `plugins/editor.lua` row.
4. **Every shared-registry pattern has more than one writer.** A pattern with
   0 or 1 writers on the whole board is a FAIL: the exemption is granted for
   measured multi-writer files, and an unused exemption is a hole waiting for
   a genuine clash to fall through.
5. **The cap agrees.** `workers:` in `prds/settings.md` equals the `workers=`
   value `sync.py plan` prints. Measured: 3 and 3.
6. **The document copies no wave membership.** `prd.md` must contain no task
   id (`W0.\d\w*`, or `[PSETCHDG]\.\d+\w*`) outside the exception table and
   the adversarial-verify list. A recovered membership table is a FAIL.
7. **The adversarial-verify nodes resolve.** Every node path the document
   names in that list must exist as `prds/<path>/prd.md`, and there must be
   exactly three. Measured: `03-editor/14-shift-select`,
   `04-shell/03-zoxide`, `06-help/02-help-command`.
8. **Readable-input ratchet.** Three counts, each failing only when it
   **rises** above the baseline written into the script as a constant with its
   measurement date:

   | count | baseline 2026-08-23 |
   |---|---|
   | undone nodes with a non-empty `deps:` (a key `sync.py` never reads) | 40 |
   | `prd.md`/spec files using an inline `[...]` `needs:` or `footprint:` | 25 |
   | registry tasks with no readable footprint | 53 |

   A ratchet, not a gate: the violations predate this node and fixing them
   means editing other nodes' frontmatter, which is not in this footprint. It
   cannot rot silently and it cannot grow. When a count falls, the script
   prints the new lower number and instructs lowering the constant — it does
   not lower it itself, because a self-adjusting baseline is not a baseline.

## Modes

- default — run every assertion, print one line each, exit 1 on any FAIL.
- `--census` — print the derived data and exit 0: writer count per path
  (descending), tasks with no footprint, the `deps:`/inline-list census, and
  `plan`'s per-wave `min(members, workers)`. This is the report a human reads
  before changing the wave layout.
- `--selftest` — the counterfactuals, below.

## Counterfactuals

Every mutation happens in a scratch copy of `prds/` and `gates/waves.tsv`
under `tempfile.mkdtemp()`, pointed at by `--board` / `--registry` overrides.
Print one `MUTATION:` line per case and a `MUTATION HOST:` line, and assert
the scratch root's hash **changed** — a selftest that prints a mutation it
never made is the failure class this board catalogues.

- [ ] Baseline: the real board and registry pass. Green counterfactual.
- [ ] Plant two scratch nodes, both live, both in one wave row, both with a
      block `footprint:` naming `home/dot_config/nvim/lua/config/keymaps.lua`,
      declared nowhere → assertion 2 red.
- [ ] Same pair with an `ordered` row added to the scratch `prd.md` → green.
- [ ] Give one of the pair the **inline** form `footprint: [home/...]` → still
      red. This is the proof the parser fix is real; with `sync.py`'s parser
      it would be green.
- [ ] Add an `ordered` row for a path neither task lists → assertion 3 red.
- [ ] Change the scratch `settings.md` to `workers: 9` → assertion 5 red.
- [ ] Append a wave-membership row of three task ids to the scratch `prd.md`
      → assertion 6 red.
- [ ] Remove one adversarial node path from the scratch `prd.md` →
      assertion 7 red.
- [ ] Add one scratch node carrying a non-empty `deps:` → assertion 8 red on
      the `deps:` count, and the message names the baseline and the new value.
- [ ] The real `prds/` and the real `gates/waves.tsv` are byte-identical
      before and after `--selftest`, asserted by hash.

## Acceptance

- [ ] `python3 prds/00-delivery/parallelization/check-waves.py` exits 0
      against the board as it stands, printing one line per assertion.
- [ ] Every assertion 1–8 is present, individually failable, and its failure
      message names the wave, the tasks, the node paths and the paths at fault.
- [ ] The frontmatter parser handles inline and block lists; proved by the
      inline-form counterfactual staying red.
- [ ] `--census` exits 0 and prints the writer-count table, the
      no-footprint list, the `deps:`/inline census and per-wave
      `min(members, workers)`.
- [ ] `--selftest` exits 0, runs every counterfactual above, prints a
      `MUTATION:` line per case, and asserts the scratch root changed.
- [ ] `--selftest` leaves `prds/` and `gates/waves.tsv` byte-identical.
- [ ] No file under `gates/` is written, and the script declares no
      `--selftest` handler inside `gates/`.
- [ ] The three ratchet baselines are constants carrying their measurement
      date, and the script never rewrites them.

## Verify and Proof

```sh
python3 prds/00-delivery/parallelization/check-waves.py; echo "rc=$?"
python3 prds/00-delivery/parallelization/check-waves.py --census
python3 prds/00-delivery/parallelization/check-waves.py --selftest; echo "selftest rc=$?"

# the selftest wrote nothing real
git status --porcelain prds gates/waves.tsv

# the delegated half still holds
bash gates/wave-status.sh --validate
```
