// §head home/dot_glzr/glazewm/layout-daemon.js:228-246 place
// §sig async function place(id)
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
// §foot home/dot_glzr/glazewm/layout-daemon.js place