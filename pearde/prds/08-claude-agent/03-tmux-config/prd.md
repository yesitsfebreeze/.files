---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 15        # higher first
complexity: 28      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 0.29h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
needs:
  - 07-multiplexer/01-session-and-windows
commit: 7afecbb
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

# 03-tmux-config — Claude Code inside tmux

The tmux.conf additions Claude Code needs when it runs inside the `main`
session. Claude Code's terminal-config docs require `set -s extended-keys
on` and `set -as terminal-features 'xterm*:extkeys'` for Shift+Enter and
notifications; `allow-passthrough on` is already present
(07-multiplexer/01-session-and-windows). This child decides the
extended-keys question with the repo's deliberate kitty-protocol-off pairing
attached, and appends its section to tmux.conf without editing earlier ones.

## Constraints

- **The extended-keys tension is real.** WezTerm's `enable_kitty_keyboard =
  false` pairs with nushell's `use_kitty_protocol = false` (04-shell/01).
  `set -s extended-keys on` changes what tmux SENDS to pane programs and can
  disturb that pairing. The decision must carry its reason; Ctrl+J works for
  newlines without it.
- **Append, don't edit.** tmux.conf's header contract: later nodes append
  their own sections and do not edit earlier ones.

## Non-goals

- No changes to the F4/F5/F6 key tables.
- No changes to palette delivery or copy mode.

## Pointers

- `home/dot_config/tmux/tmux.conf` — the file this appends to.
- `prds/07-multiplexer/01-session-and-windows/prd.md` — the base this sits on.
- Claude Code terminal-config docs — the "Configure tmux" section.

## Report

spec01: exit 0
PASS  precondition: home/dot_config/tmux/tmux.conf exists
── stage --options: the two lines load, the section was appended ──────
PASS  options: the conf loads
PASS  options: …and says nothing on stderr (got '')
PASS  options: extended-keys is on (got 'on')
PASS  options: terminal-features carries xterm*:extkeys
PASS  options: extkeys appears ONCE in the loaded feature list (got 1)
PASS  options: git diff removes NO earlier line of tmux.conf (got 0)
PASS  options: nushell still has use_kitty_protocol off
PASS  options: wezterm still has enable_kitty_keyboard off
PASS  options: the append names no key-table/status/palette/copy line
── ek=off extkeys=0 request=none client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=off extkeys=0 request=mok client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=off extkeys=0 request=kitty client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=off extkeys=1 request=none client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=off extkeys=1 request=mok client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=off extkeys=1 request=kitty client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=on extkeys=0 request=none client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=on extkeys=0 request=mok client-TERM=xterm-256color
    0000000   \r 033   [   2   7   ;   2   ;   1   3   ~ 033   [   2   7   ;
    0000020    2   ;   1   3   ~ 030 033   [   A                            
    0000031
── ek=on extkeys=0 request=kitty client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=on extkeys=1 request=none client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
── ek=on extkeys=1 request=mok client-TERM=xterm-256color
    0000000   \r 033   [   2   7   ;   2   ;   1   3   ~ 033   [   2   7   ;
    0000020    2   ;   1   3   ~ 030 033   [   A                            
    0000031
── ek=on extkeys=1 request=kitty client-TERM=xterm-256color
    0000000   \r  \r  \r 030 033   [   A                                    
    0000007
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in
modifyOtherKeys mode 2     -> pane got: 0000000  033   [   2   7   ;   2   ;   1   3   ~                        
0000012
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in
modifyOtherKeys mode 1 (again) -> pane got: 0000000  033   [   2   7   ;   2   ;   1   3   ~                        
0000012
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in
kitty push flags 1         -> pane got: 0000000   \r                                                            
0000001
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in
kitty push flags 15        -> pane got: 0000000   \r                                                            
0000001
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in
kitty set flags 15         -> pane got: 0000000   \r                                                            
0000001
no server running on /private/tmp/tmux-501/ek4_out
no server running on /private/tmp/tmux-501/ek4_in

spec02: exit 0
PASS  precondition: home/dot_config/tmux/tmux.conf exists
── stage --options: the two lines load, the section was appended ──────
PASS  options: the conf loads
PASS  options: …and says nothing on stderr (got '')
PASS  options: extended-keys is on (got 'on')
PASS  options: terminal-features carries xterm*:extkeys
PASS  options: extkeys appears ONCE in the loaded feature list (got 1)
PASS  options: git diff removes NO earlier line of tmux.conf (got 0)
PASS  options: nushell still has use_kitty_protocol off
PASS  options: wezterm still has enable_kitty_keyboard off
PASS  options: the append names no key-table/status/palette/copy line
── stage --bytes: what panes receive, by request and by option ────────
PASS  bytes A: no-request pane gets plain bytes under extended-keys on — the nushell pairing is undisturbed (got '0000000 \r \r \r 030 033 [ A 
0000007')
PASS  bytes A: …both Shift+Enter spellings folded, so no stray CSI reaches reedline
PASS  bytes B: off and on are BYTE-IDENTICAL to a pane that never asked (got '0000000 \r \r \r 030 033 [ A 
0000007' vs '0000000 \r \r \r 030 033 [ A 
0000007')
PASS  bytes C: a mode-1 pane gets Shift+Enter as CSI 27;2;13~ — the newline, distinguishable (got '0000000 033 [ 2 7 ; 2 ; 1 3 ~ 033 [ 2 7 ; 2
0000020 ; 1 3 ~ \r 030 033 [ A 
0000031')
PASS  bytes C: …arrow-up still legacy — unbound keys keep their well-known encoding (got '0000000 033 [ 2 7 ; 2 ; 1 3 ~ 033 [ 2 7 ; 2
0000020 ; 1 3 ~ \r 030 033 [ A 
0000031')
PASS  bytes C2: …and Ctrl+X in the same stream is the bare 018 — i_CTRL-X is untouched
PASS  bytes D: with extended-keys off a mode-1 request buys nothing — the docs' line is load-bearing
PASS  precondition: home/dot_config/tmux/tmux.conf exists
── stage --selftest: every stage proven by breaking it ────────────────
PASS  selftest M1: the mutation applied
PASS  selftest M1: the mutated conf really reads off, so the on-assertion can fire (got 'off')
PASS  selftest M2: the feature line was removed
PASS  selftest M2: the mutated conf carries no extkeys feature line
PASS  selftest M2: …and the loaded feature list has no extkeys — --options can fire
PASS  selftest M3: the escape-time mutation applied
PASS  selftest M3: a removed/edited earlier line is visible to a diff (got 1 changed lines)
PASS  selftest M3: the shipped conf still carries escape-time 10 (got 1)
PASS  selftest M4: tmux_lint convicts an unlabelled tmux call
PASS  selftest M4: status_lint convicts a substitution beside a bare $?
PASS  selftest M4: both lints stay green on this file
