// §head home/dot_glzr/glazewm/regrid.js:34-38 collectWindows
// §sig function collectWindows(node, out)
  if (!node) return;
  if (node.type === 'window') out.push(node);
  if (Array.isArray(node.children)) node.children.forEach((c) => collectWindows(c, out));
// §foot home/dot_glzr/glazewm/regrid.js collectWindows