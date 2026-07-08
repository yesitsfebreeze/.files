#!/usr/bin/env node
// GlazeWM regrid — one-shot "gather every window on the focused workspace back into the
// equal grid". Bound to alt+g. GlazeWM has no native "tile everything" verb (keybindings
// only ever act on the focused window), so this connects to the IPC socket, finds the
// focused workspace, and forces every floating/fullscreen window in it to `set-tiling`.
// The layout daemon then equalizes the pane sizes as usual. Minimized windows are left
// hidden on purpose (use alt+m to restore one). Zero-dependency (Node >=21, global
// WebSocket); launched fire-and-forget by the keybinding and exits when done.

const PORT = 6123;
const pending = new Map();

function send(message) {
  return new Promise((resolve, reject) => {
    let key = message;
    while (pending.has(key)) key += ' ';
    const timer = setTimeout(() => {
      pending.delete(key);
      reject(new Error('timeout'));
    }, 4000);
    pending.set(key, { resolve, reject, timer });
    ws.send(key);
  });
}

// Focus can sit on a window deep in the tree or on the workspace itself; either way the
// workspace whose subtree contains the focus is the one we regrid.
function hasFocusDeep(node) {
  if (!node) return false;
  if (node.hasFocus) return true;
  return Array.isArray(node.children) && node.children.some(hasFocusDeep);
}

function collectWindows(node, out) {
  if (!node) return;
  if (node.type === 'window') out.push(node);
  if (Array.isArray(node.children)) node.children.forEach((c) => collectWindows(c, out));
}

const ws = new WebSocket(`ws://localhost:${PORT}`);

ws.addEventListener('error', () => process.exit(0));

ws.addEventListener('message', (ev) => {
  let msg;
  try {
    msg = JSON.parse(typeof ev.data === 'string' ? ev.data : ev.data.toString());
  } catch {
    return;
  }
  if (msg.messageType !== 'client_response') return;
  const entry = pending.get(msg.clientMessage);
  if (!entry) return;
  pending.delete(msg.clientMessage);
  clearTimeout(entry.timer);
  if (msg.success) entry.resolve(msg.data);
  else entry.reject(new Error(msg.error || 'command failed'));
});

ws.addEventListener('open', async () => {
  try {
    const data = await send('query workspaces');
    const workspaces = (data && data.workspaces) || [];
    const focused = workspaces.find(hasFocusDeep) || workspaces.find((w) => w.isDisplayed);
    if (!focused) return;

    const windows = [];
    collectWindows(focused, windows);
    for (const w of windows) {
      const st = w.state && w.state.type;
      if (st === 'floating' || st === 'fullscreen') {
        try {
          await send(`command --id ${w.id} set-tiling`);
        } catch {
          // best-effort; keep going with the rest
        }
      }
    }
  } finally {
    try {
      ws.close();
    } catch {}
    process.exit(0);
  }
});
