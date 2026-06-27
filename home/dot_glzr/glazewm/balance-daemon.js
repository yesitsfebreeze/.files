#!/usr/bin/env node
// GlazeWM balance daemon — zero-dependency Node script (Node >=21, global WebSocket).
//
// Keeps the tiling grid sane, driven entirely over GlazeWM's IPC WebSocket
// (ws://localhost:6123). Goal: ZERO floating windows. Every window lives in the grid;
// transient windows tuck into a corner instead of reshuffling it.
//
//   classify  When a window is first managed (and it isn't the sole/main window), it's
//             sorted by its NATIVE height:
//               • small (height < SMALL_MAX_HEIGHT_RATIO of the monitor) → docked as a
//                 narrow right column (SMALL_COLUMN_RATIO wide) and pinned, so transient
//                 dialogs/pickers sit in the lower-right instead of splitting the grid.
//               • large → set-fullscreen in its own column (alt+f pops it back beside
//                 the main window). Nothing is ever floated.
//             GlazeWM window rules can only match process/class/title — there is no size
//             matcher — so this size-based decision has to live here, at the IPC layer.
//
//   equalize  Every tiling sibling in a split is driven toward 1/n of its parent (GlazeWM
//             exposes no absolute size setter, only relative `resize --width/--height
//             <delta>%`, so we read each sibling's tilingSize and issue the minimal
//             relative delta; nested splits recurse). Splits that contain a pinned small
//             window are SKIPPED so the narrow column stays narrow.
//
// GlazeWM already equal-splits on add/remove, so equalize is usually a no-op; it only
// corrects drift left by manual resize or odd layouts. Convergence is bounded by an
// epsilon and a self-induced-event guard to avoid resize feedback loops. There is no
// "snap native-maximized back to the grid" pass anymore: large windows are MEANT to be
// fullscreen, so a maximized window is left as-is.

const PORT = 6123;
const RECONNECT_MS = 2000;
const RECONNECT_MAX_MS = 30000;
const DEBOUNCE_MS = 80;
// A split is "equal enough" when every sibling is within this fraction of 1/n.
const EPSILON = 0.01;
// Ignore events for this long after we issue commands, so our own resize/set-fullscreen
// edits don't retrigger another balance pass.
const SELF_QUIET_MS = 250;
// A freshly managed secondary window is classified by its NATIVE height: under this
// fraction of the monitor's height it's "small/transient" (→ narrow right column); at or
// above it's "large" (→ fullscreen in its own column). Height, not area, because that's
// the axis the intent is phrased in. Tune freely.
const SMALL_MAX_HEIGHT_RATIO = 0.5;
// Width the docked small column takes (the main window keeps the rest). Held OUT of the
// equalizer so it stays narrow rather than snapping back to 1/n.
const SMALL_COLUMN_RATIO = 0.25;

const EVENTS = [
  'window_managed',
  'window_unmanaged',
  'focus_changed',
  'tiling_direction_changed',
  'workspace_activated',
  'workspace_updated',
];

// Single-instance guard: hold a localhost port as a mutex. Launched hidden, the
// daemon has no visible window for a title-based taskkill to target, so a relaunch
// could otherwise stack a second copy. If the port is already held, exit quietly.
// NOTE: must avoid the glzr.io port range — GlazeWM's IPC is 6123 and Zebar's asset
// server is 6124; squatting 6124 makes Zebar's asset server fail to bind (AddrInUse)
// and the bar renders blank. Use a port well clear of that range.
const net = require('net');
const lock = net.createServer();
lock.on('error', () => process.exit(0));
lock.listen(16124, '127.0.0.1');

let ws = null;
let reconnectMs = RECONNECT_MS;
let debounceTimer = null;
let suppressUntil = 0;
let balancing = false;

// Window ids we've already classified, so each window is judged exactly once at
// managed-time (not re-handled on every later event). Pruned when unmanaged.
const classified = new Set();
// Ids docked as the narrow small column → exempt from equalization so they stay narrow.
const pinnedSmall = new Set();

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
    const evt = msg.data;
    if (evt && evt.eventType === 'window_managed') {
      // classify runs off the managed event (not the debounced balance) because it
      // needs the window's NATIVE rect, which is only meaningful before/at the moment
      // it's slotted into the grid. Fire-and-forget; it self-suppresses on action.
      classifyWindow(evt.managedWindow).catch((err) =>
        log('classify error:', err.message),
      );
    } else if (evt && evt.eventType === 'window_unmanaged' && evt.unmanagedId) {
      classified.delete(evt.unmanagedId);
      pinnedSmall.delete(evt.unmanagedId);
    }
    if (Date.now() < suppressUntil) return;
    schedule();
  }
}

// Classify a freshly managed window. The sole/main window is left to fill the workspace;
// every secondary window is either docked as a narrow right column (small height) or
// fullscreened in its own column (large). Nothing is floated. `floatingPlacement` is
// GlazeWM's preserved native rect (it survives tiling, which is the whole point of the
// field), so it reflects the window's intended size even though it may already be tiled
// to its grid slot by the time this fires. Comparisons are RATIOS, so they're
// DPI-independent as long as both rects share a coordinate space — they do, both being
// Win32 physical screen coords.
async function classifyWindow(win) {
  if (!win || win.type !== 'window' || !win.id) return;
  if (classified.has(win.id)) return;
  classified.add(win.id);

  // Only reconsider windows that actually landed in tiling; anything the user/app
  // already put in floating/fullscreen/minimized is left alone.
  const st = win.state && win.state.type;
  if (st && st !== 'tiling') return;

  const fp = win.floatingPlacement;
  if (!fp) return;
  const w = fp.right - fp.left;
  const h = fp.bottom - fp.top;
  if (!(w > 0) || !(h > 0)) return;

  let wsData, monData;
  try {
    [wsData, monData] = await Promise.all([
      send('query workspaces'),
      send('query monitors'),
    ]);
  } catch (err) {
    log('classify query failed:', err.message);
    return;
  }

  // Resolve the window's place in the tree: its workspace + parent split, and how many
  // tiling windows already share the workspace.
  const found = locate((wsData && wsData.workspaces) || [], win.id);
  if (!found) return;
  // The first/sole window is the "main"; let it fill the workspace untouched. Only
  // secondary windows get docked or fullscreened. (At managed-time the new window is
  // already counted, so the main-alone case reads as 1.)
  if (countTiling(found.workspace) <= 1) return;

  // The monitor the window opened on (center-point test), for the height ratio.
  const cx = fp.left + w / 2;
  const cy = fp.top + h / 2;
  const monitors = (monData && monData.monitors) || [];
  const mon =
    monitors.find(
      (m) => cx >= m.x && cx < m.x + m.width && cy >= m.y && cy < m.y + m.height,
    ) || monitors[0];
  if (!mon || !(mon.height > 0)) return;

  const heightRatio = h / mon.height;
  const label = win.title || win.processName || win.id;

  if (heightRatio < SMALL_MAX_HEIGHT_RATIO) {
    // Small/transient → narrow right column, exempt from equalization.
    pinnedSmall.add(win.id);
    await dockSmall(found);
    suppressUntil = Date.now() + SELF_QUIET_MS;
    log(
      `docked small window "${label}"`,
      `(height ${(heightRatio * 100).toFixed(0)}% < ${(SMALL_MAX_HEIGHT_RATIO * 100).toFixed(0)}%)`,
    );
  } else {
    // Large → its own column, fullscreened (alt+f pops it back beside the main window).
    try {
      await command('set-fullscreen', win.id);
      suppressUntil = Date.now() + SELF_QUIET_MS;
      log(`fullscreened large window "${label}" (height ${(heightRatio * 100).toFixed(0)}%)`);
    } catch (err) {
      log('set-fullscreen failed:', err.message);
    }
  }
}

// Shrink a docked small window to SMALL_COLUMN_RATIO along its parent's split axis, via
// the same minimal relative-delta trick equalizeSplit uses (GlazeWM has no absolute
// setter). In the common main+transient case the parent is the horizontal workspace, so
// this narrows the window to a right column and the main window absorbs the rest.
async function dockSmall(found) {
  const { node, parent } = found;
  if (!parent) return;
  const horizontal = parent.tilingDirection === 'horizontal';
  const axis = horizontal ? '--width' : '--height';
  const size = typeof node.tilingSize === 'number' ? node.tilingSize : 0.5;
  const delta = SMALL_COLUMN_RATIO - size;
  if (Math.abs(delta) <= EPSILON) return;
  const pct = (delta * 100).toFixed(2);
  const arg = `${delta >= 0 ? '+' : ''}${pct}%`;
  try {
    await command(`resize ${axis} ${arg}`, node.id);
  } catch (err) {
    log('dock resize failed:', err.message);
  }
}

// Locate a window id in the workspace forest, returning { node, parent, workspace }.
// A top-level window's parent is its workspace node (whose tilingDirection drives the
// dock axis), matching what equalizeSplit reads.
function locate(workspaces, id) {
  const walk = (node, workspace, parent) => {
    if (!node) return null;
    if (node.type === 'window' && node.id === id) {
      return { node, parent, workspace };
    }
    if (Array.isArray(node.children)) {
      for (const child of node.children) {
        const hit = walk(child, workspace, node);
        if (hit) return hit;
      }
    }
    return null;
  };
  for (const ws of workspaces) {
    const hit = walk(ws, ws, null);
    if (hit) return hit;
  }
  return null;
}

// Count tiling windows anywhere under a workspace.
function countTiling(workspace) {
  let n = 0;
  const visit = (node) => {
    if (!node) return;
    if (node.type === 'window' && isTiling(node)) n++;
    if (Array.isArray(node.children)) node.children.forEach(visit);
  };
  visit(workspace);
  return n;
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
    const issued = await equalizeAll(workspaces);
    if (issued) suppressUntil = Date.now() + SELF_QUIET_MS;
  } finally {
    balancing = false;
  }
}

// Walk every split/workspace container and equalize its tiling children — EXCEPT splits
// that hold a pinned small window, whose deliberate narrow size must survive.
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

    const hasPinned = tiling.some(
      (c) => c.type === 'window' && pinnedSmall.has(c.id),
    );

    if (tiling.length > 1 && !hasPinned) {
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
