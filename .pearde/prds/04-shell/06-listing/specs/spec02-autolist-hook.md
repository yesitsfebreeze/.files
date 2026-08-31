# spec02 — the auto-list append at the HOOKS anchor

Delivers R5: one closure appended to `$env.config.hooks.env_change.PWD` under
the `# ── HOOKS ──` anchor in `home/dot_config/nushell/config.nu`, so `la`
prints after every real directory change in an interactive shell (epic
invariant I2: the PWD hook is the single reaction point). Requires spec01 —
the closure names `la`, and nushell resolves a closure's command calls at
parse time, which is exactly why the LISTING anchor sits above HOOKS.

**Est:** 0.5h

**Footprint:** `home/dot_config/nushell/config.nu`

## The append

A SECOND `$env.config.hooks.env_change.PWD = (... | append {...})` block,
directly below 01-core-config's dirstack append, above the `# ── GENERATED ──`
anchor. Do not fuse it into 01's closure and do not touch 01's comment — the
anchor's own text says the appends stay separate, and appends to a list
cannot conflict the way edits to one fused body can. The closure:

```nu
{|before, after|
    if $before != null and $after != $before and $nu.is-interactive {
        ^stty sane e> /dev/null
        if ($env._NAV? | default "" | is-empty) { la }
    }
}
```

- **`$nu.is-interactive`, never `is-terminal --stdout`.** Measured on the
  pinned nushell 0.114.1 (see the PALETTE anchor's note): a parenthesised
  `is-terminal --stdout` captures stdout and is false unconditionally as an
  `if` condition. The live hook guards on it; this file's convention is
  `$nu.is-interactive` at every guard.
- **`$before != null`** skips the first fire at shell start; startup stays
  clean. **`$after != $before`** skips a non-move.
- **`^stty sane e> /dev/null` first.** A cd can arrive via a full-screen TUI
  that crashed mid-render and left the pty half-raw; with `onlcr` off the
  table's `\n` drops a row without returning to column 0 and the listing
  staircases. Sane mode is a no-op in the normal case.
- **`$env._NAV?` optional-read.** When the bare-word fallback
  ([`03-zoxide`](../../03-zoxide/prd.md)) is about to clear the screen it sets
  `$env._NAV`; an eager `la` would only be wiped. 03 is unbuilt and OWNS
  setting the variable — this closure only reads it, and the optional access
  degrades safely: unset → `""` → `la` runs. Do not define `_NAV` here.

## Acceptance

Interactive checks run under a real pty — the runner precedent is
`tests/nushell-core.sh:125` (`write_pty_runner`) and `:276` (`nu_pty`);
`script(1)` does not work, reedline's cursor-position query hangs it.

- [x] Pty: `cd` into a dir holding a known filename prints the listing once —
      the filename appears in the output exactly once. — shell-listing H7,
      canary count 1.
- [x] Pty: shell startup prints no listing of the start dir (the first hook
      fire is skipped). — shell-listing H7, startup canary absent.
- [x] `nu -c 'cd /tmp'` against the managed config prints nothing — the
      non-interactive half of the guard. — shell-listing H10, 0 bytes.
- [x] Pty: `$env._NAV = "x"` then `cd` prints no listing; unsetting it
      restores the listing. — shell-listing H9: one session sets _NAV, cds
      (nothing), hide-env, cds again (listing); canary count exactly 1.
- [x] Pty: after `stty -onlcr`, a `cd` still prints an aligned table — the
      captured raw output returns to column 0 (`\r\n`) in the listing region.
      — shell-listing H8: a marker printed while onlcr was off ends bare-\n,
      the listing line after the cd ends \r — sane ran first.
- [x] `config.nu` holds exactly two `$env.config.hooks.env_change.PWD = (`
      blocks, dirstack's first, and in the second `stty sane` precedes `la`.
      — grep count 2; shell-listing T3/T4 with counterfactuals.
- [x] `bash tests/nushell-core.sh` stays green — its pty flows now see
      auto-list output and must still pass. — EXIT=0, 2026-08-22.

Two measured deviations from the closure as drafted above, both forced by
the acceptance boxes and recorded in the block's own comment: the hook
runner discards a closure's return value, so the listing is
`try { la | print }`, and it sits behind `(term size).columns > 0`.

*Two of the three reasons were re-measured 2026-08-23 and corrected — see
the parent PRD's bullet for the evidence.* `la | print` does **not** hang on
a 0-column pty; it prints one `Couldn't fit table into 0 columns!` per fire
and the session carries on, so the guard suppresses noise rather than
preventing a hang. And an error in one PWD closure aborts the rest of that
closure and every closure appended **after** it, on every fire — not the
session, and not the dirstack, which survives as the first append. The `try`
is what bounds that abort, and it stays.

## Verify

```sh
cd /Users/feb/dev/dotfiles
/usr/bin/grep -c '^\$env\.config\.hooks\.env_change\.PWD = ($' home/dot_config/nushell/config.nu  # expect 2
/usr/bin/grep -n 'stty sane' home/dot_config/nushell/config.nu               # inside the second append
/usr/bin/grep -n '_NAV?' home/dot_config/nushell/config.nu                   # the optional read
# no is-terminal on any CODE line (the PALETTE comment names it, comments are fine):
! /usr/bin/grep -E '^[^#]*is-terminal' home/dot_config/nushell/config.nu
bash tests/nushell-core.sh
# The pty acceptance boxes run through spec03's gate:
#   bash tests/shell-listing.sh --hermetic
```
