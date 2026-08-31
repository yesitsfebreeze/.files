# spec01 — config.nu ALIASES anchor: tool aliases, quit aliases, `rr`, `cf`

Fills the `# ── ALIASES ──` anchor that
[`04-shell/01`](../../01-core-config/prd.md) spec03 reserved for this node.
Covers **R1**, **R2**, **R3** and **R5** of [`../prd.md`](../prd.md). The
manual entries already exist — `shell.nuon` carries `cat`, `grep`, `nv / vi`,
`nn`, `g`, `lg`, `cf <file>`, `q / :q / /exit` and `rr`, each with
`source: .mi/prds/04-shell/02-aliases-utilities/prd.md` — so this spec adds
code only and asserts the entries stay true.

**Est:** 1h

**Footprint:** `home/dot_config/nushell/config.nu` (the ALIASES anchor only)

## Exact edit

Replace the two reservation lines under `# ── ALIASES ──` ("Reserved for
04-shell/02 …" / "Empty as this node lands.") with the content below. The
anchor line itself stays byte-identical: `tests/nushell-core.sh` S4.10 greps
`^# ── ALIASES ──$` and fails on a changed spelling.

```nu
alias cat = bat --paging=never
alias grep = rg
alias g = git
alias lg = lazygit
alias nv = nvim
alias vi = nvim
alias nn = nvim ~/notes.md

alias q = exit
alias ":q" = exit
alias "/exit" = exit

alias rr = chezmoi update --force

def cf [file: path] { … }
```

`cf` is the live definition from `~/.config/nushell/config.nu:368-384`,
ported with its header comment: expand the arg, `error make` on a missing
file, `open --raw`, then pick the clipboard tool — `pbcopy` when `which`
finds it, else `wl-copy` only when `$env.WAYLAND_DISPLAY?` is non-empty,
else `xclip -selection clipboard` only when `$env.DISPLAY?` is non-empty,
else `error make`. Keep the live error texts verbatim
(`cf: no such file: …`, `cf: no clipboard tool found (need wl-copy, xclip,
or pbcopy)`) — spec03's gate matches on them. End with the
`copied … to clipboard` print.

## Decisions

**D1 — the display-var guards are the hard-won why; carry them as a
comment.** `wl-copy` and `xclip` block forever waiting for a compositor or X
server when none is attached, so a `which` hit alone must never select them.
The guard on `$env.WAYLAND_DISPLAY?` / `$env.DISPLAY?` is what makes `cf`
safe headless, and the comment must say so.

**D2 — the arg stays `path`-typed.** That one annotation is the whole of
R5's "free tab completion": nushell completes files, dirs, `~` and quoting on
`<Tab>` for a `path` parameter. No completer code is written.

**D3 — three names are absent on purpose, and the gate greps for their
absence.** `cdi` belongs to [`03-zoxide`](../../03-zoxide/prd.md) R2. `bb`
and `ba` are `DO NOT PORT` (the PRD's Out of scope), and they invoke `brr` —
so the strings `alias bb`, `alias ba` and `burrito` must not appear anywhere
in `config.nu`.

**D4 — everything lands inside the anchor.** Aliases and defs resolve at
parse time but nothing here is order-sensitive against the funnel: `cd` is
not among these names, and `cf` calls only builtins and externals. Staying
between `# ── ALIASES ──` and `# ── LISTING ──` keeps S4.10's ten-anchor
ordering green.

## Acceptance

- [x] In a scratch machine (the `mk_machine` shape of
      `tests/nushell-core.sh`), `nu -c 'scope aliases | get name | to json -r'`
      lists `cat`, `grep`, `g`, `lg`, `nv`, `vi`, `nn`, `q`, `:q`, `/exit`
      and `rr`, and `scope aliases | where name == cat | get 0.expansion`
      is `bat --paging=never`.
- [x] `cf /no/such/file` exits non-zero and the error contains
      `cf: no such file`.
- [x] With a stub `pbcopy` first in `PATH` that records stdin to a file,
      `cf <real file>` exits 0, prints `copied`, and the recorded bytes equal
      the file's bytes exactly.
- [x] With `$env.PATH` narrowed inside the session so `which pbcopy` is
      empty, a stub `wl-copy` present, and `WAYLAND_DISPLAY` /` DISPLAY`
      hidden: `cf <real file>` errors `no clipboard tool found` without
      invoking the stub — the headless-hang guard, observed, not assumed.
- [x] `/usr/bin/grep -cE 'alias (bb|ba) |burrito' home/dot_config/nushell/config.nu`
      returns 0, and `cdi` does not appear in the ALIASES anchor.
- [x] `bash tests/nushell-core.sh` still exits 0 after the edit.

## Verify

```sh
bash tests/nushell-aliases.sh    # spec03's gate; covers every box above
bash tests/nushell-core.sh
```
