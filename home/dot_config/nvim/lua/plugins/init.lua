-- The import anchor for `{ import = "plugins" }` — permanent and
-- load-bearing: lazy errors `No specs found for module "plugins"` at every
-- startup when lua/plugins/ is missing OR empty (measured 2026-08-22), and
-- git cannot track an empty directory. This file holds zero specs, forever.
-- Plugin nodes (E.5+) add sibling plugins/*.lua files, imported alongside
-- it; nobody writes specs into this file. It is the anchor, not the
-- catch-all spec file epic I8 forbids.
return {}
