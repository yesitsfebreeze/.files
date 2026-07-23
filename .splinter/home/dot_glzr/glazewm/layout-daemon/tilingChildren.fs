// §head home/dot_glzr/glazewm/layout-daemon.js:196-200 tilingChildren
// §sig function tilingChildren(node)
  return (node.children || []).filter(
    (c) => c.type === 'split' || (c.type === 'window' && isTiling(c)),
  );
// §foot home/dot_glzr/glazewm/layout-daemon.js tilingChildren