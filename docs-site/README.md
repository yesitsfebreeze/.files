# docs-site

The searchable manual for this environment.

```sh
npm install
npm run dev      # regenerates, then serves (:3000, or the next free port)
npm run build
```

Three sections, maintained differently:

- **`content/docs/guide/`** — **generated**, do not edit. Task-ordered: one page
  per thing you are trying to do. Comes from `tasks.nuon` plus the `task`/`step`
  fields on each entry.
- **`content/docs/reference/`** — **generated**, do not edit. Subject-ordered:
  one table per topic, from `topics.nuon` plus each entry's `topic`.
- **`content/docs/internals/`** — **hand-written**. The constraints the config
  files used to carry as comments, and what each was measured on.

Both generated halves read the four `.nuon` surface files under
`../home/dot_config/nushell/help/` — the same files `help` reads in the shell —
so the site and the shell manual cannot disagree. Change an entry there, then
`npm run generate`.

Two entries that are two **routes** to one capability (a key and a command)
share a `does` id and render as a single block on the guide. That is what stops
`Ctrl+Shift+D` and `capsule [dir]` being listed as two separate features.

Generation shells out to `nu` to convert `.nuon` to JSON, so nushell must be on
PATH. It exits non-zero if any entry carries a `task` that `tasks.nuon` does not
declare.
