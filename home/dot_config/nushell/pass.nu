# pass.nu — Nushell completion for `pass` (the unix password manager).
# Sourced by config.nu. `pass` ships bash/zsh/fish completions but none for
# Nushell, so this declares a known-external signature whose rest-arg completer
# offers both the subcommands and the live entry names from the store. Declaring
# `extern` only adds completion; undeclared flags (e.g. `pass generate -n -c`)
# still pass straight through to the real binary.

# Entry names = every *.gpg under the store, with the store prefix and the .gpg
# suffix stripped (so `email/personal.gpg` completes as `email/personal`). The
# subcommands let `pass <tab>` also surface the verbs. PASSWORD_STORE_DIR is set
# in env.nu; fall back to the documented default if it is somehow unset.
def "nu-complete pass" [] {
    let store = ($env.PASSWORD_STORE_DIR? | default ($nu.home-dir | path join ".password-store"))
    let entries = (if ($store | path exists) {
        glob ($store | path join "**" "*.gpg")
        | each {|p| $p | path relative-to $store | str replace --regex '\.gpg$' '' }
    } else { [] })
    let commands = [init ls find grep show insert edit generate rm mv cp git help version]
    $commands | append $entries
}

extern "pass" [
    ...args: string@"nu-complete pass"   # subcommand or entry name; flags pass through
]
