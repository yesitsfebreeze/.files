# Wave 5 — interactive checklist

Automated half: `just gate 5`.

- [ ] **H.2** — `help` and its `--help` delegation. Adversarial verify: a
      delegation regression breaks `--help` shell-wide, so a second agent must
      try to break it against the PRD's acceptance criteria before the wave
      gate. Try `help`, `help <topic>`, `<our command> --help`, `ls --help`,
      `git --help`, and a command that does not exist.
      PASS: ours render ours; everything else reaches the tool that owns it,
      unchanged.
      FAIL: any third-party `--help` intercepted, reformatted or swallowed.
- [ ] **S.7** — the quicklist channel against **real** tv, which a stub
      cannot stand in for. Seed the log by jumping with `z`, opening a file
      via `Ctrl-Space`, and running a `text` search; then press `Ctrl-Q` at a
      live prompt.
      PASS: the rows render in the log's own order, newest first (the
      `no_sort = true` / `frecency = false` keys doing their job — tv
      re-ranks without them), each row reads as value, then `(channel)`, then
      the cwd it was picked in, and `Ctrl-Q` reaches the runner from the
      prompt rather than doing nothing.
      FAIL: any re-ordering, a display column in the wrong place or showing a
      raw TAB row, or a key that does not open the picker.
