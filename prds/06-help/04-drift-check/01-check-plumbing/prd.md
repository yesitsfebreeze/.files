---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 8        # higher first
complexity: 24      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: high
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 1.69h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
footprint:
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/help-check.nu
  - gates/nushell-module-staging.sh
  - tests/shell-help.sh
  - tests/help-agent.sh
  - tests/help-browser.sh
  - tests/nushell-aliases.sh
  - tests/nushell-core.sh
  - tests/shell-claude.sh
  - tests/shell-history.sh
  - tests/shell-listing.sh
  - tests/shell-quicklist.sh
  - tests/shell-television.sh
  - tests/shell-zoxide.sh
commit: 366bf77
---
<!-- Ordering reads three axes and no clock: dependency (needs + footprint),
     vision importance (priority), and complexity/blast-radius. Add your own
     keys freely, at any nesting. Nothing outside state, origin, from,
     priority, complexity, blast-radius, claim, repo, workflow, needs and
     footprint is read, and nothing you add is ever dropped.
       needs:     — PRD dir names this one depends on. A hard gate in `plan`
       footprint: — paths this PRD touches. The overlap check
       workflow:  — the route a worker is handed, expanded into its brief

     One sitting is the limit: specs summing `complexity` above `split-above`
     or counting above `specs-above` (both in prds/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# 01-check-plumbing — help --check` parses and runs: the flag on `def help`, `help-check.nu`, config.nu source order, and the eleven sibling `MODULES=` constants plus the `[a-z-]+` regex fix so no gate dies at parse

help --check` parses and runs: the flag on `def help`, `help-check.nu`, config.nu source order, and the eleven sibling `MODULES=` constants plus the `[a-z-]+` regex fix so no gate dies at parse

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->

## Report

spec01: exit 0
56:# 06-help/04-drift-check's `--check`, which runs on demand.
670:    --check                # diff the manual against the live configuration
713:    if $check { return (_help_check) }
608:alias core-help = help
609:source ~/.config/nushell/help-check.nu
610:source ~/.config/nushell/help.nu
── stage --tree: the managed files as text
      guard[tree] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[tree] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path in  = /Users/feb/dev/.files/home
PASS  tree: help.nu is a regular file in the managed tree
PASS  tree: the corpus dir ships beside it with topics.nuon and the four surface files
PASS  tree: history.nu < 'use std/help' < 'alias core-help = help' < help-check.nu < help.nu < PALETTE, each once (use at line 607, help-check.nu at line 609)
PASS  tree: counterfactual use-std-help-below-the-shadow FAILS the order check
PASS  tree: counterfactual help-check.nu-sourced-below-help.nu FAILS the order check
PASS  tree: help.nu is defs only — one 'def help [', no config-record write, no keybinding upsert
PASS  tree: counterfactual config-record-write-appended FAILS the purity check
PASS  tree: the RENDER path in help.nu spawns nothing — 0 hits for nvim, wezterm, git, tv or chezmoi in either spelling, and no $env.EDITOR, with _help_browse's body excised (R8)
PASS  tree: _help_browse is the ONLY def in help.nu that names a spawn target — got [_help_browse ]
PASS  tree: counterfactual git-spawn-inserted FAILS the re-scoped no-spawn check
PASS  tree: counterfactual git-spawn-inserted FAILS the only-spawner check
PASS  tree: the spawn-in-a-render-def counterfactual really differs from help.nu (a no-op sed would fake the two checks below)
PASS  tree: counterfactual tv-call-inside-a-render-def FAILS the re-scoped no-spawn check — the excision does not hide a spawn outside _help_browse
PASS  tree: counterfactual tv-call-inside-a-render-def FAILS the only-spawner check
PASS  tree: the corpus is addressed by $nu.home-dir joined with .config/nushell/help — neither launch-time candidate, no repo path, no developer home
PASS  tree: the pre-fix counterfactual really does differ from help.nu (a no-op sed would fake every check below it)
PASS  tree: counterfactual pre-fix-$nu.default-config-dir FAILS the corpus-path check
PASS  tree: counterfactual $nu.config-path-dirname FAILS the corpus-path check
PASS  tree: counterfactual hardcoded-repo-path FAILS the corpus-path check
PASS  tree: the mirror holds — config.nu sources ~/.config/nushell/help.nu (checked above, once) and help.nu names the same .config/nushell segments
PASS  tree: counterfactual .conf-instead-of-.config FAILS the mirror check
PASS  tree: tests/nushell-core.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/nushell-aliases.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-listing.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-zoxide.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-history.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-claude.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: counterfactual staging-line-dropped FAILS the staging check
PASS  tree: shell.nuon carries the 'help' entry naming this PRD as its source
PASS  tree: the settled-collision rule replaced the 'not settled' caveat (spec02)
PASS  tree: …and the new why names the three disambiguators
PASS  tree: this gate left shell.nuon byte-identical
      guard[tree] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path out = /Users/feb/dev/.files/home
PASS  tree: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  tree: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --hermetic: a real nushell, an isolated HOME, the corpus staged
      guard[hermetic] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[hermetic] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path in  = /Users/feb/dev/.files/home
PASS  hermetic: precondition: nu is on PATH
PASS  hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)
PASS  hermetic: precondition: python3 is on PATH (the JSON probe parses, never eyeballs)
      corpus: 9 topics, 97 entries
PASS  hermetic: the staged corpus is readable and non-empty (9 topics, 97 entries)
PASS  hermetic: 'help' exits 0 with nothing on stderr (rc=0)
PASS  hermetic: the overview lists all 9 topic ids with a summary
PASS  hermetic: the per-topic counts sum to the corpus entry count (97 = 97)
PASS  hermetic: the overview names the four first keys with their titles
PASS  hermetic: the overview carries the delegation sentence
PASS  hermetic: the overview names the ways to go deeper
PASS  hermetic: nu -c 'help' | complete carries no ESC byte (R7 — got index -1)
PASS  hermetic: 'help navigate' lists the zoxide suite with the bare-word fallback and all three listing entries
PASS  hermetic: 'help find | to json' parses as JSON and carries a 'key' column
PASS  hermetic: "help find | where key =~ 'Ctrl'" composes and finds rows (R2's own example)
PASS  hermetic: 'help selection' returns the shift-select entries, with a 'topic' column
PASS  hermetic: 'help select' delegates to std/help, because 'select' is a nushell builtin (clause 8)
PASS  hermetic: 'help ls' shows the manual's entry
PASS  hermetic: …and ends with std/help's own output for ls (Usage: and '> ls' in the tail, 43 lines total)
PASS  hermetic: 'help --entry ls' and 'ls --help' are byte-identical (R10 — indistinguishable at the call site)
PASS  hermetic: 'help ctrl-r' explains the directory scope and points at Alt-R
PASS  hermetic: 'help find' reaches OUR topic, not the builtin (a corpus-only entry id is present)
PASS  hermetic: 'help history' reaches OUR topic, not the builtin
PASS  hermetic: 'help config' reaches OUR topic, not the builtin
PASS  hermetic: 'help --delegate find' reaches the builtin's own help instead
PASS  hermetic: 'help commands | length' is over 400 — longest-match parsing keeps std's subcommand (got 625)
PASS  hermetic: 'fakecmd --help' prints the external stub's OWN usage (got: FAKECMD-OWN-USAGE: fakecmd [--flag])
PASS  hermetic: 'help --all --mode nvim' returns rows and every mode starts with nvim (got: nvim:normal,nvim:visual,nvim:insert)
PASS  hermetic: 'help --all --mode tmux' exits non-zero — the surface list is closed (rc=1)
PASS  hermetic: 'help "F5 <digit>"' renders the entry and marks it host-only
PASS  hermetic: 'timeit { help }' is under 100 ms inside the configured shell (got: fast, single sample: 5ms 293µs 209ns)
PASS  hermetic: 'help qqqxyzzy' exits 0 — clause 10 hands an unknown word to std's own search (rc=0)
PASS  hermetic: the poison 'tv' on PATH was never invoked across every probe above (got 0 invocations)
      guard[hermetic] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path out = /Users/feb/dev/.files/home
PASS  hermetic: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  hermetic: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --noxdg: the same nushell with NO XDG_CONFIG_HOME exported
      guard[noxdg] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[noxdg] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[noxdg] source-path in  = /Users/feb/dev/.files/home
PASS  noxdg: precondition: nu is on PATH
      the launch-time constant under this launch = /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.A1aXw3/m-noxdg/home/Library/Application Support/nushell
      the machine's own config dir               = /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.A1aXw3/m-noxdg/home/.config/nushell
PASS  noxdg: the launch-time constant is NOT the machine's .config/nushell — the defect's signature, recorded rather than assumed
PASS  noxdg: 'help' exits 0 with nothing on stderr under a launch that exports no XDG_CONFIG_HOME (rc=0)
PASS  noxdg: the export-absent overview is byte-identical to the export-present one (1462 bytes)
PASS  noxdg: 'help --all | length' equals the staged corpus's own entry count (97 = 97)
PASS  noxdg: 'help "F5 <digit>"' still marks the terminal entry host-only (R9's marking half)
PASS  noxdg: the poison 'tv' on PATH was never invoked (got 0 invocations)
PASS  noxdg: the counterfactual machine really carries the pre-fix resolution (a no-op sed would fake the check below)
PASS  noxdg: counterfactual pre-fix-resolution FAILS 'help' under this launch (rc=1)
PASS  noxdg: the alt tree's own corpus really carries the marker (staging check)
PASS  noxdg: 'nu --config <tree outside .config>/config.nu' renders the MACHINE's corpus, not that tree's (rc=0, 0 marker hits)
PASS  noxdg: the dirname counterfactual machine really carries that resolution
PASS  noxdg: counterfactual $nu.config-path-dirname renders the ALT tree's marker — renderer and corpus from different trees (1 hits)
PASS  noxdg: corpus directory renamed away — 'help' raises with an empty stdout and a message naming the path, chezmoi apply and --delegate (rc=1)
      Error: nu::shell::error
      
        x help: the manual's corpus directory /private/var/folders/_p/
        | tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.A1aXw3/m-noxdg-loud/home/.config/
        | nushell/help is missing — run `chezmoi apply`; `help --delegate <name>`
        | still reaches nushell's own help
PASS  noxdg: …and the escape hatch is real: 'help --delegate ls' still exits 0 in that state (rc=0)
PASS  noxdg: topics.nuon replaced by [] — 'help' raises instead of rendering 'Topics:' with nothing under it (rc=1)
PASS  noxdg: a ZERO-BYTE topics.nuon raises with OUR message, not nushell's incompatible_path_access (rc=1)
PASS  noxdg: the four surface files replaced by [] — 'help' raises rather than rendering every topic as zero entries (rc=1)
PASS  noxdg: the no-guard counterfactual machine really differs from help.nu
PASS  noxdg: counterfactual help.nu-without-the-spine-length-guard renders the EMPTY manual instead — rc 0, empty stderr, 'Topics:' with nothing under it (rc=0)
      guard[noxdg] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[noxdg] source-path out = /Users/feb/dev/.files/home
PASS  noxdg: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  noxdg: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── epilogue: the live machine is untouched
PASS  config.nu, env.nu, help.nu and shell.nuon are byte-identical
PASS  the whole corpus directory is byte-identical, file by file
PASS  ~/.cache/nushell does not exist (a real one appearing means an isolation leak)
PASS  ~/Library/Application Support/nushell does not exist (where an export-absent nu writes when a runner forgets HOME)
CHECKS: 94 run, 94 passed, 0 failed
EXIT=0
shell-help rc=0
cf rc=1 (expect non-zero: the swapped source order must break the gate)
FAIL  tree: history.nu < 'use std/help' < 'alias core-help = help' < help-check.nu < help.nu < PALETTE, each once
unknown_flag occurrences: 0 (expect 0)

spec02: exit 0
      dirstack.nu pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help-check.nu help.nu theme.nu
PASS  modules: help-check.nu exists in the managed tree
      drop help-check.nu  rc=1 at=config.nu:609
PASS  parse: dropping help-check.nu is fatal at config.nu:609 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:609)
                                dirstack  pass      claude    litellm   recents   zoxide    history   capsule   finder    quicklist copymode  help-checkhelp      theme     
PASS  grid: every in-scope gate stages every module config.nu sources (misses: 0)
nushell module staging drift — /Users/feb/dev/dotfiles
      guard[module-staging] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[module-staging] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[module-staging] source-path in  = /Users/feb/dev/.files/home
PASS  config.nu is where this gate expects it
PASS  env.nu is where this gate expects it
PASS  nu is on PATH (/opt/homebrew/bin/nu)
── modules derived from config.nu ───────────────────────────────────
      dirstack.nu pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help-check.nu help.nu theme.nu
PASS  modules: config.nu names at least eight modules (got 14)
PASS  modules: dirstack.nu exists in the managed tree
PASS  modules: pass.nu exists in the managed tree
PASS  modules: claude.nu exists in the managed tree
PASS  modules: litellm.nu exists in the managed tree
PASS  modules: recents.nu exists in the managed tree
PASS  modules: zoxide.nu exists in the managed tree
PASS  modules: history.nu exists in the managed tree
PASS  modules: capsule.nu exists in the managed tree
PASS  modules: finder.nu exists in the managed tree
PASS  modules: quicklist.nu exists in the managed tree
PASS  modules: copymode.nu exists in the managed tree
PASS  modules: help-check.nu exists in the managed tree
PASS  modules: help.nu exists in the managed tree
PASS  modules: theme.nu exists in the managed tree
── parse proof ──────────────────────────────────────────────────────
      ALL STAGED rc=0 bytes=0
PASS  parse: the fully staged machine parses and exits 0 (rc=0)
PASS  parse: and it says nothing on stdout or stderr (0 bytes)
      drop dirstack.nu    rc=1 at=config.nu:336
PASS  parse: dropping dirstack.nu is fatal at config.nu:336 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:336)
      drop pass.nu        rc=1 at=config.nu:586
PASS  parse: dropping pass.nu is fatal at config.nu:586 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:586)
      drop claude.nu      rc=1 at=config.nu:587
PASS  parse: dropping claude.nu is fatal at config.nu:587 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:587)
      drop litellm.nu     rc=1 at=config.nu:588
PASS  parse: dropping litellm.nu is fatal at config.nu:588 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:588)
      drop recents.nu     rc=1 at=config.nu:589
PASS  parse: dropping recents.nu is fatal at config.nu:589 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:589)
      drop zoxide.nu      rc=1 at=config.nu:590
PASS  parse: dropping zoxide.nu is fatal at config.nu:590 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:590)
      drop history.nu     rc=1 at=config.nu:591
PASS  parse: dropping history.nu is fatal at config.nu:591 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:591)
      drop capsule.nu     rc=1 at=config.nu:592
PASS  parse: dropping capsule.nu is fatal at config.nu:592 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:592)
      drop finder.nu      rc=1 at=config.nu:593
PASS  parse: dropping finder.nu is fatal at config.nu:593 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:593)
      drop quicklist.nu   rc=1 at=config.nu:594
PASS  parse: dropping quicklist.nu is fatal at config.nu:594 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:594)
      drop copymode.nu    rc=1 at=config.nu:595
PASS  parse: dropping copymode.nu is fatal at config.nu:595 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:595)
      drop help-check.nu  rc=1 at=config.nu:609
PASS  parse: dropping help-check.nu is fatal at config.nu:609 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:609)
      drop help.nu        rc=1 at=config.nu:610
PASS  parse: dropping help.nu is fatal at config.nu:610 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:610)
      drop theme.nu       rc=1 at=config.nu:670
PASS  parse: dropping theme.nu is fatal at config.nu:670 with nu::parser::sourced_file_not_found (rc=1 at=config.nu:670)
── gates derived from tests/ ────────────────────────────────────────
      tests/help-browser.sh
      tests/nushell-aliases.sh
      tests/nushell-core.sh
      tests/shell-claude.sh
      tests/shell-help.sh
      tests/shell-history.sh
      tests/shell-listing.sh
      tests/shell-quicklist.sh
      tests/shell-television.sh
      tests/shell-zoxide.sh
PASS  gates: at least eight scripts stage a nushell machine (got 10)
PASS  gates: tests/nushell-aliases.sh is still selected by the staging predicate
PASS  gates: tests/nushell-core.sh is still selected by the staging predicate
PASS  gates: tests/shell-claude.sh is still selected by the staging predicate
PASS  gates: tests/shell-help.sh is still selected by the staging predicate
PASS  gates: tests/shell-history.sh is still selected by the staging predicate
PASS  gates: tests/shell-listing.sh is still selected by the staging predicate
PASS  gates: tests/shell-television.sh is still selected by the staging predicate
PASS  gates: tests/shell-zoxide.sh is still selected by the staging predicate
── grid: gate x module (. staged, X missing) ────────────────────────
                                dirstack  pass      claude    litellm   recents   zoxide    history   capsule   finder    quicklist copymode  help-checkhelp      theme     
      help-browser.sh           .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      nushell-aliases.sh        .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      nushell-core.sh           .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-claude.sh           .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-help.sh             .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-history.sh          .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-listing.sh          .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-quicklist.sh        .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-television.sh       .         .         .         .         .         .         .         .         .         .         .         .         .         .         
      shell-zoxide.sh           .         .         .         .         .         .         .         .         .         .         .         .         .         .         
PASS  grid: every in-scope gate stages every module config.nu sources (misses: 0)
PASS  isolation: the real $HOME/.cache/nushell is untouched (was absent, now absent)
PASS  isolation: $HOME/.cache/nushell and the managed nushell tree are byte-identical
      guard[module-staging] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[module-staging] source-path out = /Users/feb/dev/.files/home
PASS  module-staging: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  module-staging: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
gate rc=0
── gates/nushell-module-staging.sh --selftest ───────────────────────
      MUTATION HOST: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.nAaxTr/module-staging-selftest (scratch_tree copies; the real tree is read only)
      MUTATION: added `source ~/.config/nushell/newmod.nu` and the module file to /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.nAaxTr/module-staging-selftest/red, staged in no gate
PASS  selftest RED: the mutation really landed — a claimed mutation is not a made one
PASS  selftest RED: a module no gate stages makes this gate red
PASS  selftest RED: and the FAIL names the gate and the module
PASS  selftest GREEN: the mutation changed the copy — help dropped from shell-television's staging list (sha 1b6368dc3a65 -> 4efe6425538b)
      MUTATION: removed help from the `for m in` staging list in /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.nAaxTr/module-staging-selftest/green/tests/shell-television.sh
PASS  selftest GREEN: the copy is red before repair
PASS  selftest GREEN: and the FAIL names the gate and the module
PASS  selftest GREEN: the repair changed the copy back (sha 4efe6425538b -> 1b6368dc3a65)
      MUTATION: repaired the copy by restoring help to the staging list
PASS  selftest GREEN: the repaired copy is byte-identical to the managed file — the repair is the exact inverse
PASS  selftest GREEN: with the repair landed, the gate is green
PASS  selftest: the managed nushell tree is untouched by both halves
── selftest rc=0 ──────────────────────────────────────────────────
selftest rc=0
help-agent rc=0
help-browser rc=0
nushell-aliases rc=0
nushell-core rc=0
shell-claude rc=0
shell-help rc=0
shell-history rc=0
shell-listing rc=0
shell-quicklist rc=0
shell-television rc=0
shell-zoxide rc=0
