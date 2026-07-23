// §source home/dot_glzr/glazewm/layout-daemon.js
#!/usr/bin/env node
// GlazeWM layout daemon — zero-dependency Node script (Node >=21, global WebSocket).
// Drives GlazeWM over its IPC WebSocket (ws://localhost:6123) toward one simple,
// predictable layout:
//
//   place     Every new window is appended at the END of its workspace's top-level
//             split (rightmost column in a horizontal workspace, bottom row in a
//             vertical one) — never wedged in next to whatever happened to have
//             focus. GlazeWM has no insertion-point config, so this is done post-hoc
//             with `move --direction` until the window is the last top-level child.
//
//   settle    Slow-launching apps (Firefox etc.) reposition or re-maximize
//             themselves AFTER GlazeWM has already tiled them, ending up on top of
//             the grid instead of inside their pane. Two delayed passes after each
//             manage force the window back: a self-maximized window is returned to
//             tiling, then `wm-redraw` snaps every window back onto its computed
//             tile.
//
//   equalize  Every tiling sibling in a split is driven toward 1/n of its parent
//             (GlazeWM only exposes relative `resize --width/--height <delta>%`,
//             so each off-target sibling gets one minimal relative delta).
//
// The WM guarantees membership: with `initial_state: tiling` every window is in the
// grid and only leaves it via alt+f (fullscreen) or alt+shift+space (float).

const PORT = 6123;
const RECONNECT_MS = 2000;
const RECONNECT_MAX_MS = 30000;
const DEBOUNCE_MS = 100;
// A split is "equal enough" when every sibling is within this fraction of 1/n.
const EPSILON = 0.01;
// Ignore events for this long after we issue commands, so our own edits don't
// retrigger another pass.
const SELF_QUIET_MS = 250;
// Delays after window_managed for the settle passes. Long enough for Firefox's
// session-restore resize, short enough that a deliberate alt+f afterwards sticks.
const SETTLE_MS = [400, 1600];
// Upper bound on `move` steps when appending a window to the end of the top row.
const MOVE_LIMIT = 8;

const EVENTS = ['window_managed', 'window_unmanaged', 'workspace_updated'];

// Single-instance guard: hold a localhost port as a mutex. Launched hidden, the
// daemon has no visible window for a title-based taskkill to target, so a relaunch
// would otherwise stack a second copy. If the port is already held, exit quietly.
// A peer that connects and sends "quit" makes the holder exit — that's how a chezmoi
// apply swaps in a new daemon build without restarting GlazeWM.
// NOTE: must avoid the glzr.io port range — GlazeWM's IPC is 6123 and Zebar's asset
// server is 6124; squatting 6124 makes Zebar's asset server fail to bind.
const net = require('net');
const lock = net.createServer((sock) => {
  sock.on('data', (d) => {
    if (String(d).includes('quit')) process.exit(0);
  });
  sock.on('error', () => {});
});
lock.on('error', () => process.exit(0));
lock.listen(16124, '127.0.0.1');

let ws = null;
let reconnectMs = RECONNECT_MS;
let debounceTimer = null;
let suppressUntil = 0;
let working = false;

// Pending command replies keyed by the exact message text we sent (GlazeWM echoes
// `clientMessage` on `client_response`).
const pending = new Map();

function log(...args) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/log.fs
}

function connect() {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/connect.fs
}

function scheduleReconnect() {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/scheduleReconnect.fs
}

function failPending(err) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/failPending.fs
}

function onMessage(raw) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/onMessage.fs
}

// Send a plain-text IPC message and resolve with its `data` payload.
function send(message) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/send.fs
}

function command(cmd, subjectId) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/command.fs
}

function quiet() {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/quiet.fs
}

async function queryWorkspaces() {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/queryWorkspaces.fs
}

function isTiling(node) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/isTiling.fs
}

function tilingChildren(node) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/tilingChildren.fs
}

function findWindow(node, id) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/findWindow.fs
}

// ---------------------------------------------------------------------------
// place — append the new window at the end of its workspace's top-level split.
// ---------------------------------------------------------------------------

async function onManaged(id) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/onManaged.fs
}

async function place(id) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/place.fs
}

// ---------------------------------------------------------------------------
// settle — undo an app's post-launch self-repositioning.
// ---------------------------------------------------------------------------

async function settle(id) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/settle.fs
}

// ---------------------------------------------------------------------------
// equalize — drive every split's siblings toward 1/n.
// ---------------------------------------------------------------------------

function scheduleEqualize() {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/scheduleEqualize.fs
}

async function equalizeAll() {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/equalizeAll.fs
}

async function equalizeNode(node) {
// §.splinter/home/dot_glzr/glazewm/layout-daemon/equalizeNode.fs
}

connect();
