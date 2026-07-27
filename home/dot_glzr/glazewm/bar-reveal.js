#!/usr/bin/env node
// Bar slide-reveal toggle — GlazeWM has no runtime gap command, so the only
// way to move the tiled grid is rewriting the deployed config's tagged
// outer_gap top line and reloading. Invoked by the Zebar widget over GlazeWM's
// own IPC (shell-exec expands %USERPROFILE% through the Windows shell):
//   shell-exec --hide-window node %USERPROFILE%/.glzr/glazewm/bar-reveal.js show|hide
// Always reloads (even when the file already matches) so a chezmoi mirror
// rewriting the config underneath us can't strand the live gap out of sync.
const fs = require("fs");
const path = require("path");
const os = require("os");

const SHOWN = "42px"; // bar window height; its bottom padding is the window gap
const HIDDEN = "8px"; // hidden bar reserves nothing: match the other outer gaps

const want = process.argv[2] === "show" ? SHOWN : HIDDEN;
const file = path.join(os.homedir(), ".glzr", "glazewm", "config.yaml");
const text = fs.readFileSync(file, "utf8");
const next = text.replace(
	/^(\s*top: ')[^']*(' # bar-reveal:top)$/m,
	`$1${want}$2`,
);
if (!/ # bar-reveal:top$/m.test(text)) process.exit(1); // tag missing: leave config alone
if (next !== text) fs.writeFileSync(file, next);

// Reload over IPC (global WebSocket, Node >= 21 — same as layout-daemon.js).
const sock = new WebSocket("ws://localhost:6123");
const bail = setTimeout(() => process.exit(1), 4000);
sock.onopen = () => sock.send("command wm-reload-config");
sock.onmessage = () => {
	clearTimeout(bail);
	process.exit(0);
};
sock.onerror = () => process.exit(1);
