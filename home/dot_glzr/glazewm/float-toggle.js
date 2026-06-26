// Ctrl+Space scratchpad toggle. Invoked from wezterm's Ctrl+Space keybind (Windows
// only) via node, the same node-on-Windows pattern as balance-daemon.js. Manages ONE
// floating "scratchpad" wezterm window over GlazeWM's IPC:
//
//   missing  -> spawn it (a wezterm window with class "scratchpad", running nu with
//               SCRATCH_FLOAT=1 so config.nu opens the finder once, then an interactive
//               prompt for quick work).
//   focused  -> hide it (set-minimized). The shell keeps running, state preserved.
//   hidden   -> restore + focus it.
//
// The "scratchpad" class is how GlazeWM's window_rule floats+insets it and how we find
// it here; normal wezterm windows keep the default class (org.wezfurlong.wezterm).

const { execFileSync, spawn } = require("child_process");

const GLAZEWM = "C:\\Program Files\\glzr.io\\GlazeWM\\cli\\glazewm.exe";
const WEZTERM = "C:\\Program Files\\WezTerm\\wezterm-gui.exe";
const CLASS = "scratchpad";
const DISTRO = "Ubuntu";

function glaze(...args) {
    return execFileSync(GLAZEWM, args, { encoding: "utf8" });
}

function findFloat() {
    const wins = JSON.parse(glaze("query", "windows")).data.windows;
    return wins.find((w) => w.className === CLASS) || null;
}

function spawnFloat() {
    // Mirrors wezterm's default_prog (WSL -> nu) but adds SCRATCH_FLOAT=1. Detached so
    // this short-lived toggle process can exit without taking the window with it.
    const prog =
        "SCRATCH_FLOAT=1 exec nu --config ~/.config/nushell/config.nu" +
        " --env-config ~/.config/nushell/env.nu || exec bash";
    // --always-new-process: a separate, independent wezterm process so the window
    // reliably gets the "scratchpad" class (not delegated to the running instance) and
    // its own lifecycle, which is what makes the float persist across toggles.
    const args = ["start", "--always-new-process", "--class", CLASS, "--",
        "wsl.exe", "-d", DISTRO, "--cd", "~", "-e", "bash", "-lc", prog];
    spawn(WEZTERM, args, { detached: true, stdio: "ignore" }).unref();
}

const f = findFloat();
if (!f) {
    spawnFloat();
} else if (f.hasFocus) {
    glaze("command", "--id", f.id, "set-minimized");
} else {
    if (f.state && f.state.type === "minimized") glaze("command", "--id", f.id, "toggle-minimized");
    glaze("command", "--id", f.id, "focus");
}
