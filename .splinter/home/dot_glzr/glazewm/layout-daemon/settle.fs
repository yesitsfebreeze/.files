// §head home/dot_glzr/glazewm/layout-daemon.js:252-271 settle
// §sig async function settle(id)
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
// §foot home/dot_glzr/glazewm/layout-daemon.js settle