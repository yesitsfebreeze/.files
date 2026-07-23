// §head home/dot_glzr/glazewm/regrid.js:28-32 hasFocusDeep
// §sig function hasFocusDeep(node)
  if (!node) return false;
  if (node.hasFocus) return true;
  return Array.isArray(node.children) && node.children.some(hasFocusDeep);
// §foot home/dot_glzr/glazewm/regrid.js hasFocusDeep