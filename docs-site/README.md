# docs-site

The searchable manual for this environment.

```sh
npm install
npm run dev      # regenerates the manual, then serves on :3000
npm run build
```

Two halves, and they are maintained differently:

- **`content/docs/manual/`** is **generated** — do not edit it. `npm run generate`
  reads the four `.nuon` surface files under
  `../home/dot_config/nushell/help/` (the same files `help` reads in the shell)
  and writes one page per topic. Change an entry there, not here.
- **`content/docs/internals/`** is **hand-written**. It holds the constraints the
  config files used to carry as comments: what each non-obvious line is
  defending against, and what it was measured on.

Generation shells out to `nu` to convert `.nuon` to JSON, so nushell must be on
PATH.
