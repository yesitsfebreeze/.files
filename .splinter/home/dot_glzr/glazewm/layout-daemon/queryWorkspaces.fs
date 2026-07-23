// §head home/dot_glzr/glazewm/layout-daemon.js:186-189 queryWorkspaces
// §sig async function queryWorkspaces()
  const data = await send('query workspaces');
  return (data && data.workspaces) || [];
// §foot home/dot_glzr/glazewm/layout-daemon.js queryWorkspaces