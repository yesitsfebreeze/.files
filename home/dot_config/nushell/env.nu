# env.nu — nushell's env-config. Nushell evaluates this file BEFORE config.nu,
# and WezTerm launches nu with an explicit `--env-config` pointing here, so this
# is the first of the two managed files to run in every shell.
#
# It does three things and nothing else: repair PATH for a login shell macOS
# never ran `path_helper` for (R1), set the handful of variables the rest of
# the epic reads (R2), and open an interactive shell where the user last
# navigated while leaving `nu -c` in its caller's directory (R7).
#
# It sources nothing. The generated shell integrations (starship, zoxide,
# television) are produced at chezmoi-apply time by
# `run_after_generate-shell-init.sh` and merely `source`d by config.nu (R9);
# nothing here does startup work beyond the one guarded probe at the bottom.
# See prds/04-shell/01-core-config/specs/spec01.md.

# ── PATH <-> list conversions ───────────────────────────────────────────────
# Required in principle because this file overrides nushell's stock env.nu,
# which is where the string<->list conversion normally comes from.
#
# MEASURED 2026-08-21 on the pinned nushell 0.114.1, with an empty env-config
# and no ENV_CONVERSIONS anywhere: `$env.PATH | describe` is ALREADY
# `list<string>` and it ALREADY round-trips to a colon-joined string for child
# processes. So on this version the PATH repair below does not depend on this
# block. It is kept because the requirement makes it a box and because it is
# cheap insurance if a future nushell drops that built-in special case — but
# do not repeat the older claim that without it `$env.PATH` is a plain string.
# It is not, here.
#
# The closures are a PLAIN round trip. The live block ran each side through
# nushell's path-expansion command; that is deliberately dropped, and the
# command's name is kept out of this file so a grep for it is proof it is
# gone. Measured, both directions: expansion had no observable effect on a
# `~/...` entry (it is already expanded on the way in), and its ONE real
# effect was to make a RELATIVE PATH entry absolute against the CURRENT
# WORKING DIRECTORY — which would make the exported PATH change as you `cd`.
# That is a surprise, not a feature.
#
# The "Path" key is the Windows spelling and is INERT on this host — the scope
# decisions declare macOS only. It costs one record entry, so it is kept to
# match the requirement's wording; it is not evidence of Windows support.
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: {|s| $s | split row (char esep) }
        to_string: {|v| $v | str join (char esep) }
    }
    "Path": {
        from_string: {|s| $s | split row (char esep) }
        to_string: {|v| $v | str join (char esep) }
    }
}

# ── PATH repair (R1) ────────────────────────────────────────────────────────
# macOS seeds Homebrew and the system dirs into a login shell's PATH via
# `path_helper` (which reads /etc/paths and /etc/paths.d/*), but path_helper is
# only ever invoked from /etc/zprofile and /etc/profile — i.e. from bash and
# zsh. NUSHELL NEVER RUNS IT. So when nu is the login shell (`chsh`) and
# WezTerm is launched from the GUI rather than from another terminal,
# /opt/homebrew/bin and the system dirs are simply absent, and bat, rg,
# starship, tv and lazygit all go missing. This block is not cargo-culting:
# delete it and a GUI-launched terminal loses Homebrew.
#
# The user dirs are `prepend`ed (they win) and the system dirs are `append`ed
# (they lose), and `uniq` makes the whole thing a no-op whenever the parent
# process already provided them — so running nu inside nu changes nothing.
$env.PATH = (
    $env.PATH
    | prepend ($nu.home-dir | path join ".local" "bin")
    | prepend ($nu.home-dir | path join ".cargo" "bin")
    | append [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
    ]
    | uniq
)

# ── Environment (R2) ────────────────────────────────────────────────────────
$env.XDG_CONFIG_HOME = ($nu.home-dir | path join ".config")

# RIPGREP_CONFIG_PATH is what makes `rg` share the ignore rules `fd` reads
# natively from ~/.config/fd/ignore (node_modules, target, build, …). Without
# this pointer the two finders disagree about what is worth searching, and the
# same query gives different answers depending on which tool you reached for.
$env.RIPGREP_CONFIG_PATH = ($nu.home-dir | path join ".config" "ripgrep" "config")

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# STARSHIP_SHELL names the prompt. starship is the prompt for this shell,
# sourced from the generated init that config.nu picks up (R9), and it is
# specifically starship's TWO-LINE prompt that forces config.nu's OSC 133/633
# disable — reedline repaints re-emit the prompt-start mark and the terminal
# renders it as a phantom blank line. The file that names the prompt and the
# file that works around it have to be readable together, so this is that name.
$env.STARSHIP_SHELL = "nu"

# SHELL advertises nu to anything that spawns "the user's shell" by $SHELL.
# This is a FALLBACK, not the primary path — nothing in this configuration
# relies on it — but anything that does fall back to $SHELL should land on nu.
$env.SHELL = $nu.current-exe

# ── Start dir (R7) ──────────────────────────────────────────────────────────
# Open every interactive shell in the last directory navigated into by any
# means (real `cd`, zoxide, picker jump) — `mkcd`, the single funnel, records
# it in startdir.txt on every move — falling back to ~/dev on a fresh machine.
#
# The startdir.txt path is computed HERE and again in dirstack.nu's
# `_startdir_file`. That is a deliberate MIRROR, not duplication by accident:
# env.nu runs before config.nu sources dirstack.nu, so this file cannot call
# that helper. The two must agree on the XDG_STATE_HOME default, the `nushell`
# segment and the filename; the gate greps both files and fails if they
# diverge.
#
# THE GUARD IS `$nu.is-interactive`, AND IT IS NOT THE ONE THE LIVE CONFIG
# USES. Measured on nushell 0.114.1, 2026-08-21, in this very file, under a
# real pty allocated by python's `pty.spawn` (so the child genuinely has a
# terminal — a `/bin/sh -c '[ -t 1 ]'` spawned from inside nu answers yes):
#
#     if (is-terminal --stdout) { ... }   ->  SKIPPED interactively
#                                             SKIPPED under `nu -c`
#     if $nu.is-interactive     { ... }   ->  FIRED   interactively
#                                             SKIPPED under `nu -c`
#
# `is-terminal --stdout` reports the redirection state of the CURRENT
# pipeline, and a parenthesised sub-expression captures stdout — so in an
# `if (...)` condition it is false unconditionally, on a terminal or off one.
# (A bare top-level `is-terminal --stdout` statement in a REPL does print
# `true`; the moment it is wrapped in parentheses to be used as a condition it
# is false.) The live config guards on it, which is why the start dir it
# describes has never actually fired. `$nu.is-interactive` is exactly the
# distinction R7 asks for and is what is used here and in config.nu.
#
# ~/dev is `mkdir`-ed first so the fallback `cd` cannot fail on a fresh machine.
if $nu.is-interactive {
    let dev_dir = ($nu.home-dir | path join "dev")
    mkdir $dev_dir
    let state = ($env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state"))
    let startdir_file = ($state | path join "nushell" "startdir.txt")
    let start = (if ($startdir_file | path exists) {
        let d = (open --raw $startdir_file | str trim)
        if (($d | is-not-empty) and ($d | path exists)) { $d } else { null }
    } else { null })
    cd (if ($start == null) { $dev_dir } else { $start })
}

# ── The Ollama endpoint probe (R2) ──────────────────────────────────────────
# Resolves the Ollama endpoint by running `ollama-host` and taking its stdout,
# and ONLY when it exits 0 — a missing or failing probe leaves OLLAMA_HOST
# unset rather than setting it to noise.
#
# COST, measured on this machine 2026-08-21 (~/.local/bin/ollama-host is a sh
# script running one `curl -fs --max-time 0.4`): ~11 ms per call with Ollama
# listening on 127.0.0.1:11434, ~10 ms with nothing listening (a refused
# connection returns immediately), and a worst case bounded by curl's own
# --max-time at 400 ms, reachable only against a host that DROPS rather than
# refuses. Recorded here rather than described as "cheap", because it is one
# external spawn on every interactive start and R9's promise is a zero-work
# startup. For scale: config.nu's palette re-assert costs ~5 ms.
#
# Guarded on the same `$nu.is-interactive` as the start dir (see the
# measurement there), so a scripted `nu -c ...` caller pays nothing and spawns
# nothing.
#
# AND ON `which`, BECAUSE `complete` DOES NOT CATCH A MISSING EXTERNAL.
# This repo deploys no `ollama-host` — `git ls-files home` carries nothing
# under `.local/bin` and no package list names it — so on a fresh provision
# the binary is absent. Measured 2026-08-23 on 0.114.1 under a real pty with
# it absent, the unguarded `do { ^ollama-host } | complete` printed
# `nu::shell::external_command` / "Command `ollama-host` not found" at EVERY
# interactive start AND ABORTED THE REST OF THIS FILE: a `$env.X = ...`
# appended below this block never ran. The block being LAST is the only
# reason the visible damage is the message alone — anything appended below it
# would silently not run.
#
# `complete` is not a presence check, and no redirect makes it one:
# `^missing e> /dev/null` raises the identical error, because there is no
# child whose stderr could be redirected. `do --ignore-errors { ^missing } |
# complete` is worse still — it fails with "Complete only works with external
# commands". `try { ... }` DOES catch it, which is what makes config.nu's
# `^bash <artifact>` safe at the PALETTE anchor, but wrapping this probe in
# `try` would throw away the exit code the next line reads. So the guard is
# `which`, the same idiom that gates `tinty init` one branch below that
# artifact.
#
# COST of the guard, measured the same day in the same shell: 100 lookups of
# an ABSENT name take 0.49 ms (~5 µs each), 100 of a present one 0.94 ms
# (~9 µs each). Three orders of magnitude under the ~11 ms spawn it now
# gates, so it does not dent R9's zero-work startup.
if $nu.is-interactive and (which ollama-host | is-not-empty) {
    let _ollama = (do { ^ollama-host } | complete)
    if $_ollama.exit_code == 0 {
        $env.OLLAMA_HOST = ($_ollama.stdout | str trim)
    }
}
