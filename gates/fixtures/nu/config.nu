# gates/fixtures/nu/config.nu — the self-test fixture for `nu_probe`.
#
# One keybinding, named `gate_probe`. It exists to prove the probe is not
# vacuous: a BARE `nu -c` loads no config at all, so a gate that runs one and
# finds no keybindings has proved nothing. Measured on this machine:
#   nu -c '$env.config.keybindings | length'                       -> 0
#   the same expression with --config/--env-config on the live config -> 13
$env.config.keybindings = ($env.config.keybindings | append {
    name: gate_probe
    modifier: control
    keycode: char_g
    mode: [emacs vi_insert vi_normal]
    event: { edit: insertstring, value: "gate probe" }
})
