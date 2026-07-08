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
  console.log(new Date().toISOString(), ...args);
}

function connect() {
  log('connecting to', `ws://localhost:${PORT}`);
  let socket;
  try {
    socket = new WebSocket(`ws://localhost:${PORT}`);
  } catch {
    scheduleReconnect();
    return;
  }
  ws = socket;

  socket.addEventListener('open', () => {
    log('connected');
    reconnectMs = RECONNECT_MS;
    send(`sub --events ${EVENTS.join(' ')}`).catch(() => {});
    scheduleEqualize();
  });

  socket.addEventListener('message', (ev) => onMessage(ev.data));

  socket.addEventListener('close', () => {
    log('disconnected');
    failPending(new Error('socket closed'));
    if (ws === socket) ws = null;
    scheduleReconnect();
  });

  socket.addEventListener('error', () => {
    // `close` follows and handles reconnect.
  });
}

function scheduleReconnect() {
  setTimeout(connect, reconnectMs);
  reconnectMs = Math.min(reconnectMs * 2, RECONNECT_MAX_MS);
}

function failPending(err) {
  for (const { reject, timer } of pending.values()) {
    clearTimeout(timer);
    reject(err);
  }
  pending.clear();
}

function onMessage(raw) {
  let msg;
  try {
    msg = JSON.parse(typeof raw === 'string' ? raw : raw.toString());
  } catch {
    return;
  }

  if (msg.messageType === 'client_response') {
    const entry = pending.get(msg.clientMessage);
    if (entry) {
      pending.delete(msg.clientMessage);
      clearTimeout(entry.timer);
      if (msg.success) entry.resolve(msg.data);
      else entry.reject(new Error(msg.error || 'command failed'));
    }
    return;
  }

  if (msg.messageType !== 'event_subscription') return;
  const data = msg.data || {};

  if (data.eventType === 'window_managed') {
    const win = data.managedWindow || data.window;
    if (win && win.id) {
      onManaged(win.id);
      return;
    }
  }

  if (Date.now() < suppressUntil) return;
  scheduleEqualize();
}

// Send a plain-text IPC message and resolve with its `data` payload.
function send(message) {
  return new Promise((resolve, reject) => {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
      reject(new Error('socket not open'));
      return;
    }
    // Re-key on collision so a duplicate in-flight message can't clobber.
    let key = message;
    while (pending.has(key)) key += ' ';
    const timer = setTimeout(() => {
      pending.delete(key);
      reject(new Error('command timeout'));
    }, 5000);
    pending.set(key, { resolve, reject, timer });
    try {
      ws.send(key);
    } catch (err) {
      pending.delete(key);
      clearTimeout(timer);
      reject(err);
    }
  });
}

function command(cmd, subjectId) {
  return send(subjectId ? `command --id ${subjectId} ${cmd}` : `command ${cmd}`);
}

function quiet() {
  suppressUntil = Date.now() + SELF_QUIET_MS;
}

async function queryWorkspaces() {
  const data = await send('query workspaces');
  return (data && data.workspaces) || [];
}

function isTiling(node) {
  const st = node.state && node.state.type;
  return st === 'tiling' || (st == null && node.tilingSize != null);
}

function tilingChildren(node) {
  return (node.children || []).filter(
    (c) => c.type === 'split' || (c.type === 'window' && isTiling(c)),
  );
}

function findWindow(node, id) {
  if (!node) return null;
  if (node.type === 'window' && node.id === id) return node;
  for (const c of node.children || []) {
    const hit = findWindow(c, id);
    if (hit) return hit;
  }
  return null;
}

// ---------------------------------------------------------------------------
// place — append the new window at the end of its workspace's top-level split.
// ---------------------------------------------------------------------------

async function onManaged(id) {
  try {
    await place(id);
    await equalizeAll();
  } catch (err) {
    log('place error:', err.message);
  }
  for (const ms of SETTLE_MS) {
    setTimeout(() => settle(id).catch((e) => log('settle error:', e.message)), ms);
  }
}

async function place(id) {
  for (let i = 0; i < MOVE_LIMIT; i++) {
    const workspaces = await queryWorkspaces();
    const workspace = workspaces.find((w) => findWindow(w, id));
    if (!workspace) return;
    const win = findWindow(workspace, id);
    if (!isTiling(win)) return;

    const top = tilingChildren(workspace);
    const last = top[top.length - 1];
    // Done when the window IS the last top-level child (not merely inside it —
    // a window buried in a trailing split still gets moved out to its own pane).
    if (last && last.type === 'window' && last.id === id) return;

    const dir = workspace.tilingDirection === 'vertical' ? 'down' : 'right';
    quiet();
    await command(`move --direction ${dir}`, id);
  }
}

// ---------------------------------------------------------------------------
// settle — undo an app's post-launch self-repositioning.
// ---------------------------------------------------------------------------

async function settle(id) {
  const workspaces = await queryWorkspaces();
  let win = null;
  for (const w of workspaces) {
    win = findWindow(w, id);
    if (win) break;
  }
  if (!win) return;

  // A window that is fullscreen this soon after being managed maximized ITSELF
  // (session restore) — the user's alt+f can't have raced it. Put it back.
  if (win.state && win.state.type === 'fullscreen') {
    quiet();
    await command('set-tiling', id);
  }
  await equalizeAll();
  // Snap every window back onto its computed tile; a no-op when nothing moved.
  quiet();
  await command('wm-redraw');
}

// ---------------------------------------------------------------------------
// equalize — drive every split's siblings toward 1/n.
// ---------------------------------------------------------------------------

function scheduleEqualize() {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debounceTimer = null;
    equalizeAll().catch((err) => log('equalize error:', err.message));
  }, DEBOUNCE_MS);
}

async function equalizeAll() {
  if (working) return;
  working = true;
  try {
    const workspaces = await queryWorkspaces();
    for (const w of workspaces) await equalizeNode(w);
  } finally {
    working = false;
  }
}

async function equalizeNode(node) {
  if (!node || !Array.isArray(node.children) || node.children.length === 0) return;

  const tiling = tilingChildren(node);
  if (tiling.length > 1) {
    const target = 1 / tiling.length;
    const axis = node.tilingDirection === 'horizontal' ? '--width' : '--height';
    // Skip the last sibling: resizing the first n-1 toward target lets GlazeWM
    // absorb the remainder into it, which keeps the split summing to 1.
    for (let i = 0; i < tiling.length - 1; i++) {
      const size =
        typeof tiling[i].tilingSize === 'number' ? tiling[i].tilingSize : target;
      const delta = target - size;
      if (Math.abs(delta) <= EPSILON) continue;
      const pct = (delta * 100).toFixed(2);
      quiet();
      try {
        await command(`resize ${axis} ${delta >= 0 ? '+' : ''}${pct}%`, tiling[i].id);
      } catch (err) {
        log('resize failed:', err.message);
      }
    }
  }

  for (const child of node.children || []) await equalizeNode(child);
}

connect();
