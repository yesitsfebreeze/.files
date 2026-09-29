# pass.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

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
