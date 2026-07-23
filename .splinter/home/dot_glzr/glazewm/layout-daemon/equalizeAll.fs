// §head home/dot_glzr/glazewm/layout-daemon.js:285-294 equalizeAll
// §sig async function equalizeAll()
  if (working) return;
  working = true;
  try {
    const workspaces = await queryWorkspaces();
    for (const w of workspaces) await equalizeNode(w);
  } finally {
    working = false;
  }
// §foot home/dot_glzr/glazewm/layout-daemon.js equalizeAll