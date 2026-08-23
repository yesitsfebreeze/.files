# spec01 — M-13: the `--help` collision, measured and reconciled

est: 0.6h

## Goal

`02-help-command` contradicts itself about who wins when a name is both one of
our documented topics/entries and a resolvable nushell command. Resolve the
contradiction in favour of the side the PRD's own design section already
takes, and replace the three factual claims the audit's M-13 rested on — all
three are wrong, and two are wrong in a way that makes the collision *bigger*
than M-13 assumed.

## Files touched

- `.mi/prds/06-help/02-help-command/prd.md` (only this file)

## What was measured (run these again if you doubt any of it)

All four measured 2026-08-21 against nushell as installed.

1. **Externals never route here.** With `def help [...rest] {...}` defined,
   `ls --help` arrives as `help` with `rest = ["ls"]` — but `git --help`
   prints git's own usage and never reaches the custom command, because `git`
   is an external and its flags are passed through untouched. The PRD's
   "Every `ls --help`, `git --help`, and `mycommand --help` in the shell
   reaches our command" is false for two of its three examples. Only
   nu-resolvable names (builtins, aliases, `def`s) route.

   ```
   nu -n -c 'def help [...rest] { print $"CUSTOM ($rest | to nuon)" }; ls --help; git --help'
   ```

2. **Three of the nine topic names are nushell builtins.** `find`, `history`
   and `config` all resolve `built-in`, and all three route: `[] | find
   --help`, `config --help`, `history --help` each arrive as `help` with
   `rest = ["<name>"]`. `git` is a topic *and* a name, but it is external, so
   it does **not** collide. M-13 only noticed the `ls` entry; the topic spine
   collides too, and `find` is the manual's second topic.

3. **Nearly every documented shell command is one of our own `def`s or
   aliases**, so under a "the command wins" rule the manual would be
   unreachable by name almost everywhere. Live in `~/.config/nushell/*.nu`:
   `ls` (`config.nu:124`), `l`/`ll`/`la` (`:140-142`), `alias grep = rg`
   (`:144`), plus `cat` `g` `lg` `nv` `vi` `nn` `cdi` `cc` `cr` `bb` `ba` `q`
   `rr` `cd` `cf` `z` `zi` `zz` and the `def --env` navigation funnel. These
   are the manual's own subject matter.

4. **There is no `listing` topic and no `listing` entry.** `topics.nuon`
   holds exactly `navigate find history edit git containers terminal agents
   config`; the three listing entries (`ls`, `ls -D`, `l / ll / la`) sit under
   `navigate`. The acceptance line "while `help listing` reaches ours" names
   something that does not exist.

## The reconciliation, and why it is not a new decision

The PRD already contains the answer twice and the counter-claim once:

- the numbered **resolution order** puts our manual at step 2 and delegation
  at step 3, and states "Ours wins on collision, but only for names we
  actually document";
- the acceptance box **`help find | to json` produces valid JSON (it's a real
  nu table)** requires `help find` to return *our* topic table, since
  `std help find` prints prose;
- only the box **"`help ls` reaches nushell's builtin help for `ls`, not our
  listing entry"** says otherwise.

Finding 3 is what makes this evidence rather than taste: "the command wins"
would delegate `help z`, `help zi`, `help mkcd`, `help finder`, `help capsule`
and the rest to `std/help`, which guts the command this epic exists to build.
So the outlier box is the defect. This is a correction, not a scope fork.

What the losing side was protecting — that `ls --help` still tells you the
flags — is kept without a bare pointer line: a `command`-kind entry's detail
render ends with that command's own `std/help` output, so no `--help`
invocation loses information.

## Edits

1. **Delegation contract, point 1.** Replace the false routing claim with the
   measured one: nu-resolvable names route (builtins, aliases, `def`s);
   external commands never route here, so `git --help` is unaffected by
   construction and is not the test that matters. Keep the "it gets a test"
   sentence — `ls --help` is the real one.
2. **Delegation contract, point 2 (resolution order).** Keep steps 1–4 as
   they stand, and add the collision paragraph below them: name the two
   collision classes measured above (three topic names that are nu builtins;
   our own defs and aliases, which is most of the shell surface), state that
   ours wins for a documented name, and state the no-information-loss rule.
3. **New requirement R10 — `--entry` / `--topic` disambiguators.** `help
   --entry ls` and `help --topic find` address the manual explicitly, and
   `help --delegate <name>` (or an equivalent named in the requirement)
   reaches `std/help` for a name we document. The overview (R1) states that
   `help <command>` still reaches nushell's own help for anything we do not
   document.
4. **Requirement R4** gains the trailing clause: for a `command`-kind entry
   the detail view ends with that command's `std/help` output.
5. **Acceptance.** Delete "`help ls` reaches nushell's builtin help for `ls`,
   not our listing entry — while `help listing` reaches ours." Replace with
   boxes that are true and checkable:
   - `help ls` shows the manual's `ls` entry, and its output ends with the
     `std/help` signature for `ls`;
   - `help --entry ls` and `ls --help` produce identical output (they are
     indistinguishable at the call site, so they must be);
   - `help navigate` lists all three listing entries (`ls`, `ls -D`,
     `l / ll / la`);
   - `help find`, `help history` and `help config` reach our topics, not the
     builtins, and `help --delegate find` reaches the builtin;
   - `git --help` is untouched, because externals never route here.
6. Keep the existing "`ls --help` and `git --help` behave exactly as before"
   box only if it is rewritten to the no-information-loss form; as written it
   is the claim this spec disproves.

## Acceptance

- [ ] The false routing claim is gone: the file no longer contains
      "and `mycommand --help` in the shell reaches our command".
- [ ] The file states that external commands never route here, in those
      words, so the claim cannot be re-derived from a paraphrase.
- [ ] The non-existent `listing` topic is gone: the file no longer contains
      "while `help listing` reaches ours".
- [ ] The file records the topic-name collision by name — `find`, `history`
      and `config` are nushell builtins — and says which side wins.
- [ ] `help --entry ls` appears as the documented disambiguator.
- [ ] No frontmatter field is changed.

## verify

Proved RED against the current tree before being written here (exit 1, all
four clauses failing). Whitespace is normalised first because this tree wraps
at 78 columns and both forbidden phrases straddle a line break — a naive grep
returns a false pass on them.

```
nu -n -c 'let t = (open --raw prds/06-help/02-help-command/prd.md | str replace -ar "\\s+" " "); let checks = [[want, phrase]; [false, "and `mycommand --help` in the shell reaches our command"], [false, "while `help listing` reaches ours"], [true, "help --entry ls"], [true, "external commands never route here"]]; let bad = ($checks | where {|r| ($t | str contains $r.phrase) != $r.want}); if ($bad | is-empty) { print "ok" } else { print ($bad | to text); exit 1 }'
```
