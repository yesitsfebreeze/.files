// §head home/dot_glzr/glazewm/layout-daemon.js:202-210 findWindow
// §sig function findWindow(node, id)
  if (!node) return null;
  if (node.type === 'window' && node.id === id) return node;
  for (const c of node.children || []) {
    const hit = findWindow(c, id);
    if (hit) return hit;
  }
  return null;
// §foot home/dot_glzr/glazewm/layout-daemon.js findWindow