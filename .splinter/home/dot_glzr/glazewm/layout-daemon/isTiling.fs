// §head home/dot_glzr/glazewm/layout-daemon.js:191-194 isTiling
// §sig function isTiling(node)
  const st = node.state && node.state.type;
  return st === 'tiling' || (st == null && node.tilingSize != null);
// §foot home/dot_glzr/glazewm/layout-daemon.js isTiling