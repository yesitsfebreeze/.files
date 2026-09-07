---
kind: work
level: 1
status: done
description: retire the pearde board, its guard, and its skill — the 216 PRDs and 44 workflows move into memos/ as the record and the procedures
read_when: "asking what the pearde board was, and why it is gone"
---

# retire-the-pearde-board

## Do

- Retire the `pearde/` board tree (216 PRDs across 26 top-level nodes, plus
  `settings.md`, `vision.md`, `.state/`) and the `.pearde` symlink.
- Carry the 44 atomic procedures in `pearde/workflows/` into `memos/routine/`
  as `kind: routine` memos, preserving each `## Do` body verbatim.
- Delete `scripts/board-guard.py` and the two `board-guard*` recipes from
  `justfile`.
- Remove the `.claude/skills/pearde` symlink and the references to it in
  `AGENTS.md` (and the auto-memory notes that describe the layout).
- Record the work in this memo.

The 216 PRDs and 44 workflows are the work they specified, already on the
trunk. Every PRD path and its title, in the order it was filed, then every
workflow title:


- `00-delivery/corrections`: Corrections backlog
- `00-delivery/corrections/agents-md-chezmoi-source`: `AGENTS.md` sends every specifying agent to a two-month-stale chezmoi clone
- `00-delivery/corrections/agents-md-fzf-decision-record`: The fzf decision record `decisions/fzf` wrote into `AGENTS.md` is not there
- `00-delivery/corrections/analyst-brief-census-rule`: The census rule is not in the brief the analysts actually read
- `00-delivery/corrections/armed-count-tripwires`: Four more hardcoded counts, armed and green, waiting to fire
- `00-delivery/corrections/autolist-width-guard-reason`: `config.nu:381-385`'s hang claim is true under a condition it never states
- `00-delivery/corrections/baseline-commit-absorbs-live-claims`: baseline-commit-absorbs-live-claims
- `00-delivery/corrections/capsule-cli-absent-blocks-its-own-gui-gate`: `capsule` is not on PATH, so the gate that drives its picker cannot test anything
- `00-delivery/corrections/capsule-creds-doc-accuracy`: Three claims about capsule credentials that the code does not support
- `00-delivery/corrections/capsule-creds-refresh-wording`: `capsule.nuon`'s credentials entry says "on every mount"
- `00-delivery/corrections/capsule-r6-prefix-claim`: R6 names the prefix as the guard; the guard is label **and** prefix
- `00-delivery/corrections/capsule-rm-guard-attribution`: `capsule.nu` points an auditor of `docker rm` at a guard that does not cover it
- `00-delivery/corrections/capsule-rm-reworded-claim`: The `docker rm` universal claim survives, reworded by one verb
- `00-delivery/corrections/cdi-manual-source`: `cdi` manual entry cites the wrong source PRD
- `00-delivery/corrections/census-verdict-discipline`: A census verdict must not be able to say "exact"
- `00-delivery/corrections/config-nu-parse-claims`: Two `config.nu` reasons whose mechanism is wrong, both right in conclusion
- `00-delivery/corrections/d3-tick-breaks-unticked-rule`: D.3's from-the-record tick breaks the rule that no checklist box ships ticked
- `00-delivery/corrections/dirstack-append-order-gate`: The dirstack survives by append order, and nothing checks the order
- `00-delivery/corrections/done-node-proof-gate`: Gate the property the board actually cares about: a `done` node's proof runs
- `00-delivery/corrections/done-nodes-with-unticked-boxes`: `02-terminal` closed six children with 41 requirement boxes never ticked
- `00-delivery/corrections/done-nodes-with-unticked-boxes/box-audit-check`: derived: 07-multiplexer/01-session-and-windows
- `00-delivery/corrections/done-nodes-with-unticked-boxes/closing-guard-status`: derived: 07-multiplexer/01-session-and-windows
- `00-delivery/corrections/done-nodes-with-unticked-boxes/drain-the-backlog`: drain-the-backlog — Classify all 178 open boxes under the 41 `done` nodes as (a) proven elsewhere, (b) genuinely unmet, or (c) obsolete — by evidence, never by reading code, and never touching `state:`. A (b) is a finding and its own node, not an edit here. Sized by the four spot-checks: expect both shapes, and expect nodes with no proof at all.
- `00-delivery/corrections/done-nodes-without-proof`: Eighteen `done` nodes have no executable proof; five more have one that fails
- `00-delivery/corrections/esc-entry-verify-kind`: The manual's `<Esc>` entry verifies a map the rebuild doesn't carry
- `00-delivery/corrections/f5-context-claim`: The F5 painter's "different Lua context" reason is unmeasured, and its sibling just fell
- `00-delivery/corrections/g1-verify-still-red-on-just-gates`: `G.1` is `done` and `just gates` still exits 1 — five reds, none of them about link walking
- `00-delivery/corrections/gate-artifact-leakage`: Counterfactual runs are leaking artifacts into the repo root
- `00-delivery/corrections/gate-home-isolation`: Gate HOME isolation
- `00-delivery/corrections/gate-reconciliation`: Gate reconciliation
- `00-delivery/corrections/gates-frontmatter-port`: Gates port: root layout + frontmatter plan
- `00-delivery/corrections/gates-lib-anchored-lookup`: One helper in `gates/lib.sh` closes 22 of 55 exposed positions
- `00-delivery/corrections/git-diff-integrity-boxes`: `git diff` is not an integrity check on this board — 135 of 142 `prd.md` files are untracked
- `00-delivery/corrections/git-log-graph-field-one`: `git-log`'s decoder reads field 1, and `--graph` does not put the hash there
- `00-delivery/corrections/gui-dies-claim-carriers`: "The GUI launch dies" survives in five more places
- `00-delivery/corrections/help-corpus-path-resolution`: `help` finds its corpus only where `XDG_CONFIG_HOME` is exported at launch
- `00-delivery/corrections/help-nvim-lsp-descs`: Two `nvim.nuon` LSP entries carry `nvim-map` targets with no `desc`
- `00-delivery/corrections/i8-naming-wording`: Epic invariant I8 says "named for the plugin"; every landed file is named
- `00-delivery/corrections/launchd-path-phrase-guard`: The wording guard covers the config and not the PRD that specs it
- `00-delivery/corrections/listing-order-comment`: `shell-listing.sh:104` justifies a good assertion with a false reason
- `00-delivery/corrections/listing-order-lookup-regression`: `shell-listing.sh` is red: the correction that fixed one gate defused another
- `00-delivery/corrections/ls-icons-glyphs`: The live LS_ICONS glyphs are empty strings
- `00-delivery/corrections/lsp-gate-parser-seed`: `tests/nvim-lsp.sh` is red: 125 PASS → 60 PASS / 65 FAIL
- `00-delivery/corrections/lualine-auto-theme-claim`: The inventory says lualine's `auto` theme *errors* on base16; it paints the
- `00-delivery/corrections/managed-config-template-census`: managed-config's template census rejects the television theme template
- `00-delivery/corrections/mi-lowercase-verify-sections`: A lowercase `## verify` escaped a census that closed `done`
- `00-delivery/corrections/mi-rooted-verify-commands`: A class of `verify:` commands point at paths the mi retirement deleted
- `00-delivery/corrections/nushell-core-positional-lookups`: `tests/nushell-core.sh` is only half anchored
- `00-delivery/corrections/nushell-core-s430-stall`: `S4.30` went red once in a 6m40s run and never again — a flaky proof is not a proof
- `00-delivery/corrections/nvim-gate-seed-registry`: Nothing says which nvim gates are exposed to a load-time-fetching plugin
- `00-delivery/corrections/nvim-help-entry-gaps`: The editor's utility-buffer `q` has no manual entry
- `00-delivery/corrections/offline-launch-eats-first-save`: An offline launch discards the first save
- `00-delivery/corrections/ollama-host-missing-binary`: Every interactive shell start prints `Command 'ollama-host' not found`
- `00-delivery/corrections/pearde-shell-wiring`: (untitled)
- `00-delivery/corrections/phrase-sweep-selftest-inversion`: The phrase sweep is green and its own `--selftest` is red
- `00-delivery/corrections/pwd-closure-blast-radius`: `config.nu`'s PWD-closure comment over-states the blast radius
- `00-delivery/corrections/questions-check-red-only-on-history`: `pearde questions check` is red only on history
- `00-delivery/corrections/retired-phrase-sweep`: Nothing stops a retired claim coming back
- `00-delivery/corrections/retired-phrases-mention-vs-use`: `retired-phrases` cannot tell a mention from a use, so every record of its red adds one
- `00-delivery/corrections/root-inventory-blind-to-dirs`: The root inventory walks files and symlinks, so a stray *directory* is invisible
- `00-delivery/corrections/rustfmt-argv-probe-is-intermittent`: `J/R2: rustfmt's argv` passes and fails on the same tree
- `00-delivery/corrections/shell-down-spec-carriers`: "Takes the whole shell down" survives in four spec files
- `00-delivery/corrections/shell-y-entry-missing-review-row`: `shell.nuon [y]` has no review row, so the content-model gate is red
- `00-delivery/corrections/sibling-gates-copymode-staging`: Five shell gates are red: they source `copymode.nu` without staging it
- `00-delivery/corrections/staging-gate-vacuous-green`: `nushell-module-staging.sh`'s green counterfactual is a no-op, and its own guard passes anyway
- `00-delivery/corrections/stale-framework-links`: Stale framework links
- `00-delivery/corrections/stale-mi-keeplist-ruling`: A ruling freed the `note:` fields and never reached the clause beside them
- `00-delivery/corrections/stale-mi-paths`: Repo-wide `.mi/` path rot after the restructure
- `00-delivery/corrections/stale-pwd-latch-carriers`: Two more PRD carriers of the retired PWD session-latch claim
- `00-delivery/corrections/stale-s2-doc-refs`: Stale references left by the bb/ba `DO NOT PORT` decision
- `00-delivery/corrections/statusline-devicon-red`: `03-editor/13-statusline` is `done` with a verify that exits 1, and nobody owns it
- `00-delivery/corrections/tab-state-count-tripwires`: Three more key-dump counts, in the gate the census did not reach
- `00-delivery/corrections/television-help-staging`: `tests/shell-television.sh` still misses `help.nu`, so wave 0's drift gate
- `00-delivery/corrections/terminal-inventory-path-claim`: The terminal inventory says `nu` does not resolve in the F6 subshell
- `00-delivery/corrections/tree-links-selftest-stale-pin`: `tree-links.sh --selftest` pins a count that has drifted, so `G.1`'s own verify is red
- `00-delivery/corrections/tree-links-tier-b-paths`: 119 broken links sit in Tier B, permanently un-gated and permanently wrong
- `00-delivery/corrections/truncated-source-attributions`: Nine PRD headers cite a `source:` entry name that is cut off mid-string
- `00-delivery/corrections/unguarded-startup-externals`: Two more externals spawned with no existence guard, both worse than a message
- `00-delivery/corrections/verify-all-empty-eval`: The retirement introduced a regression into the script that reports it
- `00-delivery/corrections/w0-1-terminal-inventory`: Inventory the live WezTerm config
- `00-delivery/corrections/w0-2-terminal-respec`: Re-spec the terminal epic from the inventory
- `00-delivery/corrections/w0-3-platform-rewrite`: Finish the 05-platform provisioning rewrite
- `00-delivery/corrections/w0-4-s2-corrections`: Apply the S2/S3 corrections across the tree
- `00-delivery/corrections/w0-4-s2-corrections/backlog-closeout`: Backlog close-out
- `00-delivery/corrections/w0-4-s2-corrections/capsule`: 01-capsule corrections
- `00-delivery/corrections/w0-4-s2-corrections/delivery`: Delivery + readme corrections
- `00-delivery/corrections/w0-4-s2-corrections/docs-inventories`: Docs inventories
- `00-delivery/corrections/w0-4-s2-corrections/editor`: 03-editor corrections
- `00-delivery/corrections/w0-4-s2-corrections/help`: 06-help corrections
- `00-delivery/corrections/w0-4-s2-corrections/platform`: 05-platform corrections + burrito strip
- `00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate`: Provisioning inventory re-rate
- `00-delivery/corrections/w0-4-s2-corrections/shell`: 04-shell corrections
- `00-delivery/corrections/w0-5-capsule-rebase`: Re-base 01-capsule on build-once and free the colliding bindings
- `00-delivery/corrections/w0-6-live-bugs`: Record the live-config bugs so the rebuild fixes them
- `00-delivery/corrections/waves-registry-missing-s10`: `S.10`'s gate is committed and registered nowhere, so the registry's own validation is red
- `00-delivery/corrections/wezterm-context-pool-claim`: Seven carriers say a module-local "reads back nil about as often as not" — unmeasured
- `00-delivery/corrections/wezterm-gate-positional-lookups`: The highest-exposure file on the board is read positionally, with no guard
- `00-delivery/corrections/wezterm-probe-cannot-fail`: `02-terminal`'s config-field probe names a command but no predicate
- `00-delivery/corrections/wezterm-repairing-latch-claim`: The tab-healing latch claim was substantially right; the refutation on record is what fails
- `00-delivery/corrections/zi-cdi-picker-exception`: The manual names `zi` as the fzf exception and forgets `cdi`
- `00-delivery/corrections/zoxide-entry-count`: `shell-zoxide`'s entry count says six; the corpus now has seven
- `00-delivery/decisions`: Open decisions
- `00-delivery/decisions/fzf`: Decision: fzf accepted exception or replaced
- `00-delivery/decisions/fzf-model-picker`: Decision: fzf as the model picker for `cll`
- `00-delivery/decisions/odin-toolchain`: Decision: does the Odin-from-source / pi-oilrig toolchain survive into the image
- `00-delivery/decisions/shift-select-scope`: Decision: shift-to-select full port with tests, or the conscious downgrade
- `00-delivery/decisions/tinty`: Decision: does tinty stay as palette owner
- `00-delivery/decisions/wallpaper-opacity`: Decision: wallpaper cycling + opacity toggle, and the Ctrl+Shift+B collision
- `00-delivery/finish-line`: Finish line — the settled contract for closing this repo
- `00-delivery/finish-line/agent-overview-derived-tools`: The agent overview names its tools, without holding a second copy of them
- `00-delivery/finish-line/doctor-debt-live-nodes`: Doctor debt, repaired where it is still live
- `00-delivery/finish-line/drift-check-terminal-surface`: The deferred third surface — `help --check` against WezTerm
- `00-delivery/finish-line/epic-invariants-prose`: Epic invariants stop being checkboxes
- `00-delivery/parallelization`: Parallelization
- `00-delivery/quiet-board-sweep`: A green `just gates` needs one serial sweep on a quiet board
- `00-delivery/verification-gates`: Verification gates
- `00-delivery/wave-registry-keying`: `gates/waves.tsv` cannot register a gate for any node without a `task:` id
- `00-delivery/work-breakdown`: Work breakdown

- `01-capsule/01-container-lifecycle`: Container lifecycle
- `01-capsule/02-dev-image`: Dev image
- `01-capsule/03-credential-propagation`: Credential propagation into containers
- `01-capsule/04-recent-workspaces`: Recent-workspace picker

- `02-terminal/01-appearance`: Terminal appearance — font, palette, baseline
- `02-terminal/02-startup-layout`: Startup layout — the self-healing nine-tab floor
- `02-terminal/03-f5-jump-mode`: F5 one-shot tab select
- `02-terminal/04-copy-mode`: Copy mode, paste, and the loose bindings
- `02-terminal/05-tab-content-state`: Tab content-state colouring
- `02-terminal/06-launchd-path`: launchd PATH seeding
- `02-terminal/07-grid-centering`: Dynamic grid centering

- `03-editor/01-options`: Options baseline
- `03-editor/02-keymaps`: Core keymaps
- `03-editor/03-autocmds`: Autocmds
- `03-editor/04-plugin-manager`: Plugin manager (lazy.nvim)
- `03-editor/05-completion`: Completion (blink.cmp)
- `03-editor/06-explorer`: File explorer (oil.nvim)
- `03-editor/07-formatting`: Format on save (conform.nvim)
- `03-editor/08-telescope`: Fuzzy finder (telescope)
- `03-editor/09-lsp`: LSP (mason + native 0.11)
- `03-editor/10-treesitter`: Treesitter
- `03-editor/11-colorscheme`: Colorscheme + mode-aware cursor
- `03-editor/12-small-plugins`: Git signs, discovery, autopairs
- `03-editor/13-statusline`: Statusline (lualine)
- `03-editor/14-shift-select`: Shift-to-select (SIMPLIFY)
- `03-editor/15-markdown-tables`: Markdown table mode

- `04-shell/01-core-config`: Core config
- `04-shell/02-aliases-utilities`: Aliases and small utilities
- `04-shell/03-zoxide`: Zoxide navigation
- `04-shell/04-television`: Television finder
- `04-shell/05-history`: Directory-scoped history
- `04-shell/06-listing`: Decorated ls + auto-list
- `04-shell/07-quicklist`: Quicklist — cross-channel recents
- `04-shell/08-claude-launchers`: Claude launchers (SIMPLIFY)
- `04-shell/09-theme-switcher`: Theme switcher
- `04-shell/10-litellm-launcher`: LiteLLM model launcher

- `05-platform/01-deploy-mechanism`: Deploy mechanism
- `05-platform/01-deploy-mechanism/managed-config`: Managed config surface + dot_gitconfig.tmpl
- `05-platform/01-deploy-mechanism/repo-skeleton`: Repo skeleton: chezmoi source layout, home/, justfile
- `05-platform/02-package-provisioning`: Package provisioning
- `05-platform/02-package-provisioning/homebrew-bootstrap`: Homebrew bootstrap
- `05-platform/02-package-provisioning/packages-installer`: Tool installer (install.sh)
- `05-platform/02-package-provisioning/tmux-not-installed-on-the-host`: tmux is a host dependency of `07-multiplexer` and is in no host package list
- `05-platform/03-shell-init-generation`: Shell-init generation

- `06-help/01-content-model`: Content model
- `06-help/01-content-model/coverage`: Coverage
- `06-help/02-help-command`: The `help` command
- `06-help/03-browser`: Fuzzy browser
- `06-help/04-drift-check`: Drift check
- `06-help/04-drift-check/01-check-plumbing`: (untitled)
- `06-help/04-drift-check/02-shell-resolver`: (untitled)
- `06-help/04-drift-check/03-nvim-resolver`: (untitled)
- `06-help/04-drift-check/04-nvim-buffer-maps`: (untitled)
- `06-help/04-drift-check/05-allowlist`: (untitled)
- `06-help/04-drift-check/06-report-and-gate`: (untitled)
- `06-help/04-drift-check/07-tmux-key-resolver`: (untitled)
- `06-help/05-agent-interface`: Agent interface
- `06-help/06-manual-markdown`: The manual as markdown, and `?`

- `07-multiplexer/01-session-and-windows`: (untitled)
- `07-multiplexer/02-key-tables`: (untitled)
- `07-multiplexer/03-status-bar`: (untitled)
- `07-multiplexer/04-palette-delivery`: (untitled)
- `07-multiplexer/05-copy-and-clipboard`: (untitled)
- `07-multiplexer/06-nvim-session`: (untitled)
- `07-multiplexer/07-persistence`: (untitled)
- `07-multiplexer/08-wezterm-reduction`: (untitled)
- `07-multiplexer/09-manual-entries`: (untitled)

- `08-claude-agent/01-tmux-mcp`: (untitled)
- `08-claude-agent/02-nvim-plugin`: (untitled)
- `08-claude-agent/03-tmux-config`: (untitled)
- `08-claude-agent/04-help-entries`: (untitled)

- `09-simplify/01-hygiene`: `install` and `home/dot_config/litellm/create_config.yaml` stood here and
- `09-simplify/02-board`: 02-board — the PRDs are the record; everything around them goes
- `09-simplify/03-help-system`: Corrected by the orchestrator 2026-09-02, before dispatching the implementer.
- `09-simplify/04-nushell`: 04-nushell — built-ins, one append, no tombstones
- `09-simplify/05-terminal`: 05-terminal — tmux.conf to ~250 lines, one palette path
- `09-simplify/06-neovim-television`: 06-neovim-television — built-ins over wrappers, five channels not twenty-one
- `09-simplify/07-provisioning`: 07-provisioning — a Brewfile and sixty lines
- `09-simplify/08-litellm-out`: 08-litellm-out — the one thing here that is not a dotfile
- `09-simplify/propagate-a-tinty-apply-into-a-running-nvim`: propagate a tinty apply into a running nvim
- `09-simplify/retire-the-two-unmanaged-television-preview-scripts`: retire the two unmanaged television preview scripts
- `09-simplify/retire-the-unmanaged-television-channels`: retire the unmanaged television channels
- `09-simplify/silence-the-chezmoi-config-template-drift-warning`: silence the chezmoi config-template drift warning

- `.`: Dotfiles rebuild
- `00-delivery`: Epic: Delivery — the workload plan
- `01-capsule`: Epic: Capsule — one consolidated dev-container tool
- `02-terminal`: Epic: Terminal (WezTerm)
- `03-editor`: Epic: Neovim
- `04-shell`: Epic: Nushell daily driver
- `05-platform`: Epic: Provisioning — how the config reaches a machine
- `06-help`: Epic: `help` — the environment manual
- `07-multiplexer`: (untitled)
- `08-claude-agent`: (untitled)
- `09-simplify`: Epic: Simplify — smaller and more straightforward, everywhere
- `every-derived-node-names-the-prd-whose-work-surfaced-it`: every derived node names the prd whose work surfaced it
- `every-workflow-atomic-carries-its-tags`: every workflow atomic carries its tags
- `the-pearde-guard-hook-is-wired-into-the-harness`: the pearde guard hook is wired into the harness
- `the-superseded-litellm-out-lane-is-gone`: the superseded litellm-out lane is gone

- `apply-scoped-not-bare`: the working tree held unrelated pending changes; a bare `chezmoi apply` would have deployed them alongside
- `ask-whether-the-tool-already-refuses`: a two-claim fixture showed `collect` already refuses cross-claim staging, which halved the spec and moved it to the real hole
- `assert-the-post-state-twice`: a verify that passes once is a build script; three runs is what separates the two
- `bisect-which-command-expands-the-format`: -e` arrived literal and `-d` did not, which is the whole defect; testing the same popup as a key binding, inside a template, and through `run-shell` is what separated the expander from the expandee
- `carry-the-why-across-the-rewrite`: the file shrank 404 → 198 lines and its constraint comments were the expensive part; re-lodging them beside the code that still needs them is what stops a rewrite from spending a day of somebody's past work
- `census-the-class-not-the-instance`: the one bad block was 8 lines in 5 files, and the commit it caused had run five times, not once
- `check-what-apply-left-behind`: "`chezmoi apply` left all four deleted files deployed, so the deletion was true of the repo and false of the machine, and one of them kept a picker channel pointing at a function that was gone"
- `clear-a-doctors-problem-with-its-own-fixer`: every workflow atomic carries its tags
- `cut-a-feature-its-readers-still-name`: 09-simplify/03-help-system
- `delete-the-shadow-the-replacement-leaves`: "`~/.local/bin` is ahead of the brew prefix, so the old binary would have won forever and the Brewfile entry would have been decorative"
- `delete-what-nothing-reads`: 09-simplify/01-hygiene
- `document-the-new-surface`: this shell's drift check fails on any alias with no manual entry, so the entry is part of the change, not a follow-up
- `drive-the-surface-on-a-real-client`: new-session -d` refuses a `display-popup`, so the binding read as broken on the convenient harness; a pty client turned "unknown command" into a real dispatch
- `hand-fix-what-the-fixer-left`: a fixer is scoped to one field; a problem outside that scope (here, a counter it never writes) is real work, not a retry
- `land-an-answered-fork`: 08-claude-agent/02-nvim-plugin
- `locate-the-check-that-flagged-it`: the purpose line was already stale (106/4 vs the live 312/6); reading the doctor script's own condition rather than the prose is what kept the fix aimed at the real check
- `measure-the-premise-not-the-prd`: two of six requirements rested on facts that were false on the day; acting on either would have destroyed live state
- `name-the-surfacing-prd-from-its-own-record`: every derived node names the prd whose work surfaced it
- `prove-a-key-binding-on-a-real-client`: 05-terminal — tmux.conf to ~250 lines, one palette path
- `prove-a-recorded-defect-from-its-artifacts`: 00-delivery/corrections/baseline-commit-absorbs-live-claims
- `prove-in-a-shell-that-loaded-the-config`: "`nu -c` loads no config and reports a correct change as absent — this is the step that catches the false negative"
- `prove-nothing-reads-it`: `cmp` and a whole-tree grep turned "byte-identical duplicate" and "nothing references it" from a claim into a result
- `prove-the-orphan-can-be-owned-by-its-replacement`: "the contract asked for six `.chezmoiremove` entries; five of them named paths the replacement installs to, and the entry fires on every apply, so they would have uninstalled it forever"
- `prove-the-replacement-is-a-drop-in`: brew's tinty was installed beside the release copy and asked for the same scheme, the same 538 entries and the same hook write BEFORE anything was deleted
- `read-the-merged-config-not-the-source`: the source file said nothing about which side the panel opens; only the plugin's own merged table and the real pane geometry could say, and they disagreed with the manual
- `read-the-provenance-from-the-nodes-own-text`: all four nodes carry their own "Established ... by ... on `<prd>`" sentence; reading it, and confirming the named directory exists, is what the contract requires instead of a guess
- `recount-both-sides-with-one-counter`: the two figures on the record were taken with two different counters; one counter closed a reconciliation the board had failed three times
- `recover-the-contract`: the PRD body was an unfilled template; two independent sources named the two lines, which is what made building possible without asking
- `regenerate-every-derived-surface`: half the manual is generated from the files being edited, so a source fix that skips the generator ships a page that still says the old thing
- `replace-a-hand-rolled-mechanism`: 09-simplify/07-provisioning
- `replay-the-incident-from-the-commit`: archiving the board tree out of the offending commit reproduced both independent reports, and found two paths neither reader had
- `rerun-the-drift-check`: "`just manual` plus a shasum pair is what says the configuration and its manual still agree"
- `rerun-the-flagged-check`: re-ran `pearde doctor` and watched the no-from: count fall by exactly four on the canonical tree, which is what separated "fixed" from "counted elsewhere"
- `respell-the-proven-fix-in-the-config-file`: the fix passed as argv and then silently never fired written as a backslash-continued line in the file; only the `{}` block survived the nesting
- `run-the-boards-declared-fixer`: doctor's own `fix:` line names the exact command that already knows how to close most of the count
- `run-the-surface-that-consumed-it`: `just --list`, `chezmoi apply --dry-run`, `git check-ignore` and `workflows.py list` each name the deleted thing's consumer, so a wrong deletion shows as a broken surface, not as silence
- `run-the-verify-twice`: the first block passed on a violated assertion, because `! cmd` is exempt from `set -e`; a second run is also what catches a check that asserted the act instead of the post-state
- `simplify-a-nushell-surface-and-deploy-it`: 04-nushell — built-ins, one append, no tombstones
- `stage-the-extraction-in-a-throwaway-project`: "the five scripts read as one bash set and two of them are python3; staging them from `git show` in a temp directory turned a relocatable set into a measured one, and surfaced the call back into the shell config they were leaving"
- `take-the-answers-not-the-stale-report`: the report on disk carried a `Verdict:` line that read as current and described a contract two answers had already replaced
- `wire-a-tool-into-the-shell`: pearde-shell-wiring
- `write-a-proof-not-a-build-script`: run twice, exit 0 twice, nothing staged — the form the last run got wrong and that blocked a collect
- `write-into-the-chezmoi-source`: put both lines in `home/`, never in the deployed tree, so the change survives the next apply
- `write-the-traced-value-into-frontmatter`: added `from: <prd>` under `origin: derived` in each of the four files

## Check

- `just memos-check` is green: 121 memos, 48 of them `kind: routine`.
- `ls pearde/ .pearde .claude/skills/pearde scripts/board-guard.py` all
  return "No such file or directory".
- `just --list` shows `push`, `manual`, `memos-check` and nothing else.
- `grep -in 'pearde\|board-guard' AGENTS.md` returns nothing.

This memo is `done` on 2026-09-07: the commits `memos: workflows retire from
pearde/workflows to memos/routine` (353a2e4), `retire pearde/ board tree`
(da2d712), `delete board-guard script + justfile targets` (3c52368), and the
symlinks, docs and memory commits that follow.
