// §head home/dot_glzr/glazewm/layout-daemon.js:296-321 equalizeNode
// §sig async function equalizeNode(node)
  if (!node || !Array.isArray(node.children) || node.children.length === 0) return;

  const tiling = tilingChildren(node);
  if (tiling.length > 1) {
    const target = 1 / tiling.length;
    const axis = node.tilingDirection === 'horizontal' ? '--width' : '--height';
    // Skip the last sibling: resizing the first n-1 toward target lets GlazeWM
    // absorb the remainder into it, which keeps the split summing to 1.
    for (let i = 0; i < tiling.length - 1; i++) {
      const size =
        typeof tiling[i].tilingSize === 'number' ? tiling[i].tilingSize : target;
      const delta = target - size;
      if (Math.abs(delta) <= EPSILON) continue;
      const pct = (delta * 100).toFixed(2);
      quiet();
      try {
        await command(`resize ${axis} ${delta >= 0 ? '+' : ''}${pct}%`, tiling[i].id);
      } catch (err) {
        log('resize failed:', err.message);
      }
    }
  }

  for (const child of node.children || []) await equalizeNode(child);
// §foot home/dot_glzr/glazewm/layout-daemon.js equalizeNode