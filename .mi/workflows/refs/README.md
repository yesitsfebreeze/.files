# refs — the protocol these workflows read

Reference material, not a skill. The five `mi-*` workflows point their agents
at these files by path (`.mi/workflows/refs/<file>`, overridable with
`args.refs`); nothing here is registered as a slash command, and no repo has to
install it. The refs live beside the scripts so a repo that symlinks
`.mi/workflows` gets them for free.

`laws.md` and `worker.md` are the two the workflows name directly — the four
laws, and the board protocol every phase is written against. The rest are read
on demand.

## process — the genome we run on ourselves

The same artifact the harness composes for a spawned runner: dna, kickoff,
procedures. What we ship to a daughter and what we follow here are one thing,
or one of them is wrong.

| Question | Answer | File |
|---|---|---|
| What must hold? | the four laws | [laws.md](laws.md) |
| How do we **work towards** it? | the board brief — one node, four moves, closed honestly | [worker.md](worker.md) |
| How do we **create** new data? | the memo — a design record that argues a decision | [memo.md](memo.md) |
| How do we **use what we have**? | the capabilities — find them, use each where it fits | [how.md](how.md) |
| How do we **run** it — one session, or N at once? | the session, and why concurrent ones do not collide | [run.md](run.md) |

Read in that order. The laws are the spine; every other file is them applied
and says which ones.

Nothing here restates a law or a format that lives elsewhere. Every file in
this directory used to.
