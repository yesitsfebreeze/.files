#!/usr/bin/env node
// GlazeWM balance daemon — zero-dependency Node script (Node >=21, global WebSocket).
//
// Keeps the tiling grid sane on two axes, driven entirely over GlazeWM's IPC
// WebSocket (ws://localhost:6123):
//   Pass A  retile: any window in fullscreen/maximized state is sent `set-tiling`
//           so native-maximized windows snap back into the grid.
//   Pass B  equalize: every tiling sibling in a split is driven toward 1/n of its
//           parent. GlazeWM exposes no absolute size setter, only relative
//           `resize --width/--height <delta>%`, so we read each sibling's
//           `tilingSize` and issue the minimal relative delta. Nested splits recurse.
//
// GlazeWM already equal-splits on add/remove, so Pass B is usually a no-op; it only
// corrects drift left by manual resize or odd layouts. Convergence is bounded by an
// epsilon and a self-induced-event guard to avoid resize feedback loops.

const PORT = 6123;
const RECONNECT_MS = 2000;
const RECONNECT_MAX_MS = 30000;
const DEBOUNCE_MS = 80;
// A split is "equal enough" when every sibling is within this fraction of 1/n.
const EPSILON = 0.01;
// Ignore events for this long after we issue commands, so our own resize/set-tiling
// edits don't retrigger another balance pass.
const SELF_QUIET_MS = 250;

const EVENTS = [
  'window_managed',
  'window_unmanaged',
  'focus_changed',
  'tiling_direction_changed',
  'workspace_activated',
  'workspace_updated',
];

let ws = null;
let reconnectMs = RECONNECT_MS;
let debounceTimer = null;
let suppressUntil = 0;
let balancing = false;

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
  } catch (err) {
    scheduleReconnect();
    return;
  }
  ws = socket;

  socket.addEventListener('open', () => {
    log('connected');
    reconnectMs = RECONNECT_MS;
    send(`sub --events ${EVENTS.join(' ')}`).catch(() => {});
    schedule();
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

  if (msg.messageType === 'event_subscription') {
    if (Date.now() < suppressUntil) return;
    schedule();
  }
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

function schedule() {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debounceTimer = null;
    balance().catch((err) => log('balance error:', err.message));
  }, DEBOUNCE_MS);
}

async function balance() {
  if (balancing) return;
  balancing = true;
  try {
    const data = await send('query workspaces');
    const workspaces = (data && data.workspaces) || [];

    let issued = false;
    issued = (await retileMaximized(workspaces)) || issued;
    issued = (await equalizeAll(workspaces)) || issued;

    if (issued) suppressUntil = Date.now() + SELF_QUIET_MS;
  } finally {
    balancing = false;
  }
}

// Pass A — collect every fullscreen/maximized window and tile it.
async function retileMaximized(workspaces) {
  const targets = [];
  const visit = (node) => {
    if (!node) return;
    if (node.type === 'window') {
      const st = node.state && node.state.type;
      if (st === 'fullscreen') targets.push(node.id);
    }
    if (Array.isArray(node.children)) node.children.forEach(visit);
  };
  workspaces.forEach(visit);

  let issued = false;
  for (const id of targets) {
    try {
      await command('set-tiling', id);
      issued = true;
    } catch (err) {
      log('set-tiling failed:', err.message);
    }
  }
  return issued;
}

// Pass B — walk every split/workspace container and equalize its tiling children.
async function equalizeAll(workspaces) {
  let issued = false;
  const visit = async (node) => {
    if (!node || !Array.isArray(node.children) || node.children.length === 0)
      return;

    // Only tiling children count toward an equal split; floating/minimized/
    // fullscreen windows are not part of the tiling flow.
    const tiling = node.children.filter(
      (c) => c.type === 'split' || (c.type === 'window' && isTiling(c)),
    );

    if (tiling.length > 1) {
      issued = (await equalizeSplit(node, tiling)) || issued;
    }

    // Recurse regardless so nested splits get balanced too.
    for (const child of node.children) await visit(child);
  };

  for (const ws of workspaces) await visit(ws);
  return issued;
}

function isTiling(window) {
  // A tiling window has no non-tiling state and carries a tilingSize.
  const st = window.state && window.state.type;
  return st === 'tiling' || (st == null && window.tilingSize != null);
}

// Drive each sibling's tilingSize toward 1/n via one relative resize per off-target
// sibling. The axis depends on the parent's tilingDirection.
async function equalizeSplit(parent, tiling) {
  const n = tiling.length;
  const target = 1 / n;
  const horizontal = parent.tilingDirection === 'horizontal';
  const axis = horizontal ? '--width' : '--height';

  let issued = false;
  // Skip the last sibling: resizing the first n-1 toward target lets GlazeWM
  // absorb the remainder into it, which keeps the split summing to 1 and avoids
  // fighting the WM over the final pane.
  for (let i = 0; i < n - 1; i++) {
    const node = tiling[i];
    const size = typeof node.tilingSize === 'number' ? node.tilingSize : target;
    const delta = target - size;
    if (Math.abs(delta) <= EPSILON) continue;
    const pct = (delta * 100).toFixed(2);
    const arg = `${delta >= 0 ? '+' : ''}${pct}%`;
    try {
      await command(`resize ${axis} ${arg}`, node.id);
      issued = true;
    } catch (err) {
      log('resize failed:', err.message);
    }
  }
  return issued;
}

connect();
