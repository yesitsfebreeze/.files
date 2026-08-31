---
complexity: 25
footprint:
  - gates/done-node-verify-paths.sh
---
<!-- Add your own keys freely; nothing outside complexity and footprint is read. -->

# spec02 — R4's advisory path-existence check, kept advisory by construction

New script `gates/done-node-verify-paths.sh`. For every node's `verify:`
(any state, not only `done` — this is the wider sweep
`mi-rooted-verify-commands` R5 already measured at "all 62 carriers plus the
2 mode-126 cases … all 147, 0 misses"), it flags a `verify:` that names a
path which does not exist. It never gates: no `rc` it produces is wired into
`gates/waves.tsv`, ever — not deferred like spec01's registration, refused on
principle, because existence is not truth (see the five reasons below).

## Acceptance

- [ ] **Population and extraction.** The same frontmatter-scoped reader as
      spec01 (share the reader function between the two scripts rather than
      forking it — copy-paste drift between two scripts reading the same
      eleven-line awk is exactly the class of defect this PRD's family
      exists to catch) collects every node's `verify:`, regardless of
      `state:`. From each non-empty value, extract the first token
      containing a `/` — the path-shaped part of a `bash tests/foo.sh`,
      `nu tests/foo.nu --tree`, or `bash prds/.../verify.sh all` command.
- [ ] **The check.** A verify with a `/`-token that does not resolve to an
      existing file (relative to the repo root) is reported `MISS <node>:
      <verify> — <token> does not exist`. A verify with **no** `/` token at
      all (`just gate-selftest`, `help --check exits 0`, prose like `quicklist
      round-trips a pick (wave-5 gate)`) is reported separately as `NO-PATH
      <node>: <verify>` — not a miss, and not silently dropped either: this
      is the one shape R1 catches that this check structurally cannot, and
      the report says so per node rather than only in the header prose.
- [ ] **Always advisory — the five reasons, verbatim in the header.** The top
      of the file carries, as a comment, the five reasons from
      [`mi-rooted-verify-commands`](../../mi-rooted-verify-commands/prd.md)
      R5 that this check must never gate: (1) a verify may legitimately name
      a command, not a file; (2) forward-looking paths are correct and
      indistinguishable from a rot without reading `footprint`; (3) it
      cannot see one level down, into the script the verify invokes; (4) it
      cannot see the fenced `## Verify` / `## verify` form, only the
      frontmatter key; (5) existence is not truth — after every path exists
      the check goes green on a board where most proofs are still spent,
      which is the overclaimed guard this whole family corrects. Cite
      `done-node-proof-gate`'s own R1 as the check that actually gates,
      by name, so a reader who wants a real answer is pointed at the right
      script.
- [ ] **Report shape.** Ends with a plain count
      (`done-node-verify-paths: N nodes, M misses, K no-path`), always exits
      0 regardless of `M` — non-zero exit is reserved for the script's own
      internal errors (e.g. `prds/` missing), never for a miss it found.
- [ ] **`--selftest`.** Against a scratch board copy only:
      - a synthetic node whose verify names a path that exists → no MISS.
      - a synthetic node whose verify names `tests/does-not-exist.sh` → one
        MISS, naming the node and the missing path.
      - a synthetic node whose verify is `just some-recipe` (no `/`) → one
        NO-PATH, not a MISS.
      - the script's own exit code is 0 in all three cases above — proving
        "always advisory" is a property of the exit code, not merely a
        comment nobody enforces.
      - `assert_unchanged` over the real board: untouched by the run.

## Verify and Proof

```sh
bash gates/done-node-verify-paths.sh
bash gates/done-node-verify-paths.sh --selftest
```
