# copymode.nu — enter WezTerm copy mode from the shell.
# Sourced by config.nu at the MODULES anchor.
#
# Prints an OSC 1337 SetUserVar named `copymode` to stdout; WezTerm parses
# it off the pty and drops THIS pane into copy mode (wezterm.lua's
# user-var-changed handler). The handler ignores the value, but SetUserVar
# syntax requires one, base64-encoded. This is the only route from a shell
# command into a GUI-only mode — WezTerm's CLI has no action for it.
def copymode [] {
    print -n $"(char -u '1b')]1337;SetUserVar=copymode=('1' | encode base64)(char -u '7')"
}
