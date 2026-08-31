---
est: 0.5h
footprint:
  - home/dot_config/nushell/config.nu
verify: "bash tests/nushell-core.sh --tree"
covers: R1
---

# spec01 — guard `^stty sane` on `which`, and record the measured blast radius

One line changes and one comment paragraph is added, both in
`home/dot_config/nushell/config.nu`. The auto-list closure keeps its body,
its order and its three guards; what changes is that the `^stty sane` spawn
is entered only when `stty` resolves.

Everything below was measured on the pinned nushell 0.114.1 on 2026-08-23,
under a real pty, against a scratch `HOME` built the way
`tests/nushell-core.sh`'s `mk_machine` builds one, with `$env.PATH` narrowed
to `/usr/bin` so `stty` does not resolve. The implementer copies the numbers;
it does not re-derive them.

## The edit

Replace line 395, the first statement in the auto-list closure:

```nu
            if (which stty | is-not-empty) { ^stty sane e> /dev/null }
```

**Keep `^stty sane` a literal on that one line, and keep the line above the
`la` line.** `tests/shell-listing.sh`'s `autolist_ok` (lines 132–144) greps
the closure block for the fixed string `^stty sane`, requires the block to
carry `$nu.is-interactive` and `$env._NAV?`, and asserts the `^stty sane`
line number is *below* the ` la ` line. That gate belongs to `04-shell/06`
and this node must not edit it. Checked: `bash tests/shell-listing.sh --tree`
is `EXIT=0` against exactly this spelling.

## The comment

Insert the paragraph below immediately above the auto-list append's
`$env.config.hooks.env_change.PWD = (` line — i.e. as the last paragraph of the comment
block that already explains why `^stty sane` runs first. Wrap at ~78 columns
to match the file. The wording may be tightened; every fact and every number
must survive, because spec03 gates the phrases marked below.

Reference the neighbouring claim **by content, not by line number** ("the
`try` paragraph above"): this edit shifts every line number below it, and a
comment that cites `config.nu:389-390` is wrong the moment anyone inserts a
line.

```
# AND ON `which`, BECAUSE THE REDIRECT IS NOT A GUARD. `e> /dev/null` does
# not suppress a not-found error: there is no child process whose stderr
# could be redirected, so nushell raises nu::shell::external_command before
# any spawn happens. Measured 2026-08-23 on the pinned 0.114.1 under a real
# pty with $env.PATH narrowed so `stty` does not resolve: ONE FULL ERROR BOX
# PER CD, quoting this very line — one cd one box, two cds two, three cds
# three.
#
# THE BLAST RADIUS IS WHY THIS OUTRANKS ITS LIKELIHOOD, and the measurement
# refines the `try` paragraph above. An error inside a PWD closure aborts
# THAT closure at the failing statement — so the `la` below never runs
# again — and every PWD closure appended AFTER it never runs either, while
# the closures appended BEFORE it keep firing on every move. It is not a
# session-wide latch: the failing closure re-fires and re-errors at each cd.
# Driven with a three-closure config, once with `error make` and once with a
# missing external, the two are indistinguishable: the closure before the
# failure logged all three moves, the closure after it logged none. So the
# damage today is bounded only by ORDER — S.1's dirstack push is the FIRST
# append and survives (measured: dirs.txt still recorded both moves with
# stty absent), the auto-list in this closure does not, and anything a later
# node appends after it would not either.
#
# /bin/stty is macOS base, so this is latent rather than live: it fires on a
# machine with a mangled PATH, which is exactly when the shell has to keep
# working. `try { ^stty sane e> /dev/null }` would contain the error too and
# is deliberately NOT the fix: it would equally swallow a REAL stty failure,
# where `which` says what it means and is the tree's settled idiom (env.nu's
# ollama-host probe, `tinty init` at the PALETTE anchor below, finder.nu's
# `tv` bail). COST of the lookup, same shell, same day: 100 lookups of an
# ABSENT name take 410 µs (~4 µs each), 100 of a present one 929 µs (~9 µs
# each) — three orders of magnitude under the spawn it gates, so R9's
# zero-work startup is untouched.
```

## What must not change

- The `try` paragraph above it stays **byte-identical**. Its sentence "an
  error inside ONE PWD closure stops EVERY PWD closure firing for the rest of
  the session" is `04-shell/06`'s record and is over-stated by the
  measurement above; the new paragraph refines it additively rather than
  rewriting another node's argument. The imprecision is reported upward, not
  fixed here.
- The closure body: the three guards, the `$env._NAV?` read, the
  `(term size).columns > 0` width guard and `try { la | print }`.
- The dirstack append above it, and the count of PWD appends (two — three
  gates assert it).

## Acceptance

- [x] `config.nu`'s auto-list closure spawns `^stty sane` only inside
      `if (which stty | is-not-empty) { … }`, on one line, above the `la`
      line.
- [x] The `try` paragraph that precedes the append is byte-identical to
      before (`git diff` shows insertions plus the one changed line, nothing
      else).
- [x] The new paragraph carries all five facts: the redirect cannot suppress
      a not-found error and why; one error box per cd; the abort reaches
      every closure appended after the failing one and no further back; it is
      not a session-wide latch; the measured cost of the lookup.
- [x] `bash tests/shell-listing.sh --tree` is `EXIT=0` — the sibling gate's
      `^stty sane`-before-`la` contract still holds. Quote the T3 lines.
- [x] `bash tests/nushell-core.sh --tree` is `EXIT=0`.
- [x] By hand, quoted in the report: with `$env.PATH` narrowed so `stty` does
      not resolve, a `cd` prints **no** error box and the auto-list still
      renders, where the unguarded file prints one box per cd and no listing.
      The listing half needs a pty runner that sets a winsize — this gate's
      runner does not (see spec03) — so use the one in
      `tests/shell-zoxide.sh`:

```sh
S=$(mktemp -d); cd "$(git rev-parse --show-toplevel)"
awk '/^  cat > "\$PTY" <<.PYEOF.$/{f=1;next} /^PYEOF$/{f=0} f' \
    tests/shell-zoxide.sh > "$S/nupty.py"        # the winsize-setting variant
mkdir -p "$S/home/.config/nushell" "$S/home/.cache/nushell/init" \
         "$S/bin" "$S/home/a"
for f in dirstack pass theme claude zoxide history capsule finder copymode \
         help; do cp home/dot_config/nushell/$f.nu "$S/home/.config/nushell/"
done
for p in starship zoxide television; do
  printf '# stub\n' > "$S/home/.cache/nushell/init/$p.nu"; done
touch "$S/home/a/CANARY.md"
P='@WAIT=\x1b[?2004h'
python3 "$S/nupty.py" 40 \
  "$P" '@SEND=$env.PATH = ["/usr/bin"]\r' \
  "$P" '@SEND=cd ~/a\r' "$P" '@SEND=exit\r' \
  HOME="$S/home" PATH="$S/bin:/usr/bin:/bin" TERM=xterm-256color \
  -- "$(command -v nu)" --no-history \
  --config "$PWD/home/dot_config/nushell/config.nu" \
  --env-config "$PWD/home/dot_config/nushell/env.nu" | tr -d '\r' > "$S/out"
grep -ac 'Command `stty` not found' "$S/out"; grep -ac CANARY "$S/out"
```

      Run this exact shape on 2026-08-23: unguarded → `1` and `0` (one error
      box, and the closure aborts before the listing); guarded → `0` and `1`;
      and with `["/usr/bin" "/bin"]` in the first send, so `stty` resolves,
      → `0` and `1` either way. Delete `$S/home/.local` between runs — the
      dirstack persists across them.

## Verify and Proof

```sh
bash tests/shell-listing.sh --tree
bash tests/nushell-core.sh --tree
```

The machine-checked half of R1 lands in spec03; run the full
`bash tests/nushell-core.sh` **alone** once that is in.
