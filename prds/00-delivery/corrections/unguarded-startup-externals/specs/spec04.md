---
est: 1h
footprint:
  - tests/shell-zoxide.sh
verify: "bash tests/shell-zoxide.sh"
covers: R2, R3, R4
needs: spec02
---

# spec04 — the gate drives `z`, `zi` and a typo with no `zoxide` on PATH

`tests/shell-zoxide.sh` gets two machines and twenty-two checks in
`stage_hermetic`, plus eleven text/prose checks in `stage_tree`. **The code
below was inserted into a copy of this gate and run** against a copy of
`zoxide.nu` carrying spec02's edits: green with the guards, red without, both
runs quoted at the foot. Paste it; do not redesign it.

## Undoing the fixture — twice over

This is the part that matters, and it is the reason the defect was invisible
to a gate that otherwise drives every `z` path:

1. **`mk_machine` installs a controllable `zoxide` stub** in `$M/bin` (line
   461). Every other check in this stage runs with the binary *present* — the
   stub is how "queried once" and "never queried" are countable. The
   absent-binary machine deletes it. (No poison `zoxide` here; the poison
   stubs are `cc bash tinty ollama-host starship tv brew`.
   `tests/nushell-core.sh` and four other gates *do* poison `zoxide`, which is
   why none of them can see this either.)
2. **Deleting it is not enough.** `env.nu`'s PATH repair `append`s
   `/opt/homebrew/bin` unconditionally, and a real `zoxide` 0.10.0 lives there
   on this machine (`ls /opt/homebrew/bin/zoxide`), so the effective PATH
   answers anyway. The absence is made **inside the session**, by prefixing
   `$env.PATH = ["/usr/bin"]; ` to the command (or typing it as the first REPL
   line): nushell resolves externals against the live `$env.PATH`.
3. **The generated init is emptied too**, because that is what
   `home/run_after_generate-shell-init.sh` writes when the tool is absent —
   `: > "$out"`, its truncate-on-failure branch. That is the honest state, and
   it is what makes ZX.3's literal-arm counterfactual bite: with the init
   empty, `__zoxide_z` is undefined and binds as an external.

One more trap, paid for once already: **the machine dir must not be called
`m-nozoxide`.** The pty prompt echoes the machine's path, and ZX.2 asserts the
word `zoxide` appears nowhere in that transcript — a machine named
`m-nozoxide` makes that check red for its own name. It is `m-nozx`.

## The hermetic block

Insert directly **after** the hook-appends check that closes `stage_hermetic`
(`chk_ok "hermetic: pre_execution and pre_prompt each gain exactly one entry
from this module …"` and its `test "$counts_with" = "1:1" …` line), and
before that stage's `guard_end`.

```sh
  # ── ZX.1 – ZX.3 — the three guards with the zoxide BINARY ABSENT.
  # 00-delivery/corrections/unguarded-startup-externals R2/R3/R4.
  #
  # THE FIXTURE HAS TO BE UNDONE TWICE OVER, and both halves are why this
  # defect stayed hidden here:
  #   * mk_machine installs a CONTROLLABLE `zoxide` stub in $M/bin, so every
  #     other check in this stage runs with the binary present. Deleted here.
  #   * deleting it is NOT enough. env.nu's PATH repair APPENDS
  #     /opt/homebrew/bin unconditionally and a real zoxide lives there on
  #     this machine, so the effective PATH answers anyway. The absence is
  #     made INSIDE the session, by narrowing $env.PATH before the command:
  #     nushell resolves externals against the live $env.PATH.
  # The generated init is EMPTIED too, because that is what
  # home/run_after_generate-shell-init.sh writes when the tool is absent
  # (truncate-on-failure). With it empty `__zoxide_z` is undefined and binds
  # as an EXTERNAL — which is why the _z_jump guard sits above the literal
  # arms rather than at the query, and ZX.3 executes that difference.
  # The machine dir is NOT called m-nozoxide: its path shows up in the pty
  # prompt, and ZX.2 asserts the WORD zoxide appears nowhere in that
  # transcript.
  local MZ="$SCRATCH/m-nozx"; mk_machine "$MZ"
  rm -f "$MZ/bin/zoxide"
  : > "$MZ/home/.cache/nushell/init/zoxide.nu"
  local NOZOX='$env.PATH = ["/usr/bin"]; '
  local MSG='zoxide not installed'
  local c

  # ZX.1 — every USER-INVOKED entry point answers with the message, leaves
  # PWD alone and exits 0: a missing tool is not a failed pipeline, and it is
  # the same answer a no-match already gives.
  for c in 'z projquery' 'zi' 'zl someq' "z $MZ/home/fix"; do
    out="$(cd "$MZ/elsewhere" && nu_c "$MZ" "${NOZOX}$c; print \$\"PWD:(\$env.PWD)\"" 2>&1)"
    chk_ok "hermetic: ZX.1 no zoxide, '$c' prints the message (got: $(printf '%s' "$out" | head -1))" \
           test -n "$(printf '%s' "$out" | $GREP -oF "$MSG")"
    chk_fail "hermetic: ZX.1 …'$c' raises no nu::shell::external_command" \
             test -n "$(printf '%s' "$out" | $GREP -oF 'nu::shell::external_command')"
    chk_ok "hermetic: ZX.1 …'$c' leaves PWD in the start dir" \
           test -n "$(printf '%s' "$out" | $GREP -oF "PWD:$MZ/elsewhere")"
  done

  # ZX.2 — the fallback is SILENT (R2): under a pty, two typos get the
  # shell's OWN unknown-command error and the transcript never says zoxide.
  nu_pty "$MZ" "$PROMPT" '@SEND=$env.PATH = ["/usr/bin"]\r' \
               "$PROMPT" '@SEND=blahzzz9typo\r' \
               "$PROMPT" '@SEND=another9typo\r' \
               "$PROMPT" '@SEND=exit\r' | tr -d '\r' > "$MZ/typo.raw"
  echo "      typo transcript: error boxes=$($GREP -acF 'nu::shell::external_command' "$MZ/typo.raw") zoxide-hits=$($GREP -acF 'zoxide' "$MZ/typo.raw")"
  chk_fail "hermetic: ZX.2 with no zoxide a two-typo transcript never contains the string zoxide" \
           $GREP -qF 'zoxide' "$MZ/typo.raw"
  chk_fail "hermetic: ZX.2 …and in particular never reports a missing zoxide" \
           $GREP -qF 'Command `zoxide` not found' "$MZ/typo.raw"
  chk_ok "hermetic: ZX.2 …the first typo got the shell's own unknown-command error" \
         $GREP -qF 'Command `blahzzz9typo` not found' "$MZ/typo.raw"
  chk_ok "hermetic: ZX.2 …so did the second (the hook keeps firing, it is not disabled)" \
         $GREP -qF 'Command `another9typo` not found' "$MZ/typo.raw"
  chk_ok "hermetic: ZX.2 …and exactly two error boxes, one per typo" \
         test "$($GREP -acF 'nu::shell::external_command' "$MZ/typo.raw")" -eq 2

  # ZX.3 — the counterfactual: the same machine with the three guard lines
  # stripped from the module copy config.nu sources. Every ZX.1/ZX.2 claim
  # inverts.
  local MZR="$SCRATCH/m-nozx-rev"; mk_machine "$MZR"
  rm -f "$MZR/bin/zoxide"
  : > "$MZR/home/.cache/nushell/init/zoxide.nu"
  local RGUARD='^ *if \(which zoxide \| is-empty\) \{'
  $GREP -vE "$RGUARD" "$ZOXIDE_NU" > "$MZR/home/.config/nushell/zoxide.nu"
  chk_ok "hermetic: ZX.3 the reverted copy really did lose all three guards" \
         test "$($GREP -cE "$RGUARD" "$MZR/home/.config/nushell/zoxide.nu")" -eq 0
  chk_ok "hermetic: ZX.3 …and differs from the managed file by exactly those three lines" \
         test "$(( $(wc -l < "$ZOXIDE_NU") - $(wc -l < "$MZR/home/.config/nushell/zoxide.nu") ))" -eq 3
  out="$(cd "$MZR/elsewhere" && nu_c "$MZR" "${NOZOX}z projquery" 2>&1)"
  chk_ok "hermetic: ZX.3 counterfactual: unguarded 'z <query>' raises nu::shell::external_command" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'nu::shell::external_command')"
  out="$(cd "$MZR/elsewhere" && nu_c "$MZR" "${NOZOX}z $MZR/home/fix" 2>&1)"
  chk_ok "hermetic: ZX.3 …and the LITERAL-dir arm dies on the generated init's jump function, which is why the guard sits above it" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'not found')"
  nu_pty "$MZR" "$PROMPT" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT" '@SEND=blahzzz9typo\r' \
                "$PROMPT" '@SEND=exit\r' | tr -d '\r' > "$MZR/typo.raw"
  chk_ok "hermetic: ZX.3 …and ONE typo already blames the config: Command \`zoxide\` not found" \
         $GREP -qF 'Command `zoxide` not found' "$MZR/typo.raw"
```

## The tree block

Insert directly **above** `  chk_ok "tree: exactly six entries name this PRD
as their source" \` at the end of `stage_tree`. `norm` comes from
`gates/lib.sh`; `line_of` is the gate's own.

```sh
  # ── ZX.4 / ZX.5 — 00-delivery/corrections/unguarded-startup-externals
  # R2/R3 as TEXT: three guards, the asymmetry between them, and the reason.
  local ZX_GUARD='^ *if \(which zoxide \| is-empty\) \{'
  chk_ok "tree: ZX.4 all three zoxide sites bail on (which zoxide | is-empty)" \
         test "$($GREP -cE "$ZX_GUARD" "$ZOXIDE_NU")" -eq 3
  chk_ok "tree: ZX.4 _z_no_zoxide is defined exactly once, ABOVE _z_jump (parse-time binding)" \
         test "$($GREP -cF 'def _z_no_zoxide [] {' "$ZOXIDE_NU")" -eq 1 \
              -a "$(line_of "$ZOXIDE_NU" 'def _z_no_zoxide [] {')" -lt "$(line_of "$ZOXIDE_NU" 'def --env _z_jump [')"
  chk_ok "tree: ZX.4 the message names the tool AND the apply that regenerates the init" \
         $GREP -qF 'zoxide not installed — z/zi cannot jump. Install it, then run: chezmoi apply' "$ZOXIDE_NU"
  chk_ok "tree: ZX.4 exactly two sites call it — z and zi, not the fallback" \
         test "$($GREP -cF '{ _z_no_zoxide; return' "$ZOXIDE_NU")" -eq 2
  local FB_BODY
  FB_BODY="$(awk '/^def --env _z_fallback \[/{on=1} on{print} on && /^}/{exit}' "$ZOXIDE_NU")"
  chk_ok "tree: ZX.4 the fallback's own guard is the SILENT one (guard present, message absent)" \
         test -n "$(printf '%s' "$FB_BODY" | $GREP -oF 'which zoxide | is-empty')" \
              -a -z "$(printf '%s' "$FB_BODY" | $GREP -oF '_z_no_zoxide')"
  # line_of returns 0 for an absent line, so both line numbers are required
  # to be > 0: without that the counterfactual passes this check by absence.
  local ZXJ ZXA
  ZXJ="$(line_of "$ZOXIDE_NU" 'if (which zoxide | is-empty) { _z_no_zoxide; return false }')"
  ZXA="$(line_of "$ZOXIDE_NU" '__zoxide_z ...$rest')"
  chk_ok "tree: ZX.4 _z_jump's guard precedes its literal arms (guard=$ZXJ arms=$ZXA)" \
         test "$ZXJ" -gt 0 -a "$ZXA" -gt 0 -a "$ZXJ" -lt "$ZXA"
  local ZX_TXT
  ZX_TXT="$(sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' "$ZOXIDE_NU" | norm)"
  hasz() { test -n "$(printf '%s' "$ZX_TXT" | $GREP -oF "$1")"; }
  chk_ok "why: ZX.5 the file records that the fallback fires on every unresolvable bare word" \
         hasz 'fires on EVERY unresolvable bare word'
  chk_ok "why: ZX.5 …and what the guard buys there, measured" \
         hasz 'the string `zoxide` appears NOT ONCE'
  chk_ok "why: ZX.5 …that an absent zoxide means an EMPTY generated init" \
         hasz 'an ABSENT zoxide means an EMPTY generated init'
  chk_ok "why: ZX.5 …and that a helper defined below its callers would bind as an external" \
         hasz 'a helper defined below them would bind as an EXTERNAL'
```

Two details are load-bearing:

- The prose is matched through `norm`, which joins the whole file's comment
  text into one line. This repo wraps at ~78 columns, so a per-line grep on
  wrapped prose is the false-negative machine `tests/nushell-core.sh` warns
  about at its own `why:` block.
- The reverted copy is staged **over the machine's own
  `~/.config/nushell/zoxide.nu`**, which is the file `config.nu` sources. No
  config swap and no `MACHINE_*` plumbing is needed here, unlike the stty
  gate.

## A pre-existing FAIL that is not yours

`bash tests/shell-zoxide.sh --tree` already fails one line in the tree as it
stands, before any change from this node:

```
FAIL  tree: exactly six entries name this PRD as their source
```

`home/dot_config/nushell/help/shell.nuon` now carries **seven** entries whose
`source:` is `prds/04-shell/03-zoxide/prd.md`: the in-flight `06-help/01`
rewrite migrated every `source:` from `.mi/prd/...` to `prds/...` and, in the
same pass, re-sourced the `cdi` entry from `04-shell/02-aliases-utilities` to
`04-shell/03-zoxide`. Reproduced on an unmodified copy of the tree, so it is
not caused by anything here.

**Do not "fix" it by changing six to seven.** Whoever re-sourced that entry
owes the sibling-gate update; adopting it here would be this node silently
ratifying another node's contract change. Report it, and read the PRD's
acceptance box accordingly: every `ZX.*` line PASS, and this one line the only
FAIL in the run (or `EXIT=0` outright if it has been resolved by then).

## Acceptance

- [x] `bash tests/shell-zoxide.sh` run **alone**: all twenty-two `ZX.1`–`ZX.3`
      hermetic lines and all eleven `ZX.4`/`ZX.5` tree lines PASS. Quote them,
      including the `typo transcript: error boxes=2 zoxide-hits=0` line.
- [x] The only FAIL in that run is the pre-existing `exactly six entries`
      line above — quoted, with a note that it is untouched — or the run is
      `EXIT=0`.
- [x] The counterfactual: with spec02's three guard lines stripped and
      nothing else changed, the hermetic stage exits 1 with sixteen FAILs
      (every `ZX.1` message and PWD line, both `ZX.2` absence lines, the
      two-boxes line, and the three-line diff line) and the tree stage with
      four. Quote the FAIL list, restore, show green again.
- [x] Existing checks are byte-unchanged: `git diff --stat
      tests/shell-zoxide.sh` shows insertions only, and the stage's own
      counterfactuals (the reversed-MODULES `cc` poison, the negative
      triggers, the clear counts) are still PASS.

## Verify and Proof

Run it **alone.** Parallel gate runs empty the pty output and produce false
reds; if a `ZX.2` or fallback line goes red once, re-run solo before believing
it.

```sh
bash tests/shell-zoxide.sh
```

Measured on 2026-08-23 in a scratch copy of the tree carrying spec02's edits,
this exact block inserted:

```
--hermetic → EXIT=0, all 22 ZX lines PASS, including
             "typo transcript: error boxes=2 zoxide-hits=0"
             and ZX.1's quoted message for all four commands
--tree     → all 11 ZX lines PASS; EXIT=1 from the pre-existing
             shell.nuon count only
```

and with the three guard lines stripped, nothing else changed:

```
--hermetic → EXIT=1, 16 FAILs, e.g.
  FAIL hermetic: ZX.1 no zoxide, 'z projquery' prints the message (got: Error: nu::shell::external_command)
  FAIL hermetic: ZX.2 with no zoxide a two-typo transcript never contains the string zoxide
--tree     → EXIT=1, 4 FAILs, e.g.
  FAIL tree: ZX.4 all three zoxide sites bail on (which zoxide | is-empty)
  FAIL tree: ZX.4 _z_jump's guard precedes its literal arms (guard=0 arms=64)
```
