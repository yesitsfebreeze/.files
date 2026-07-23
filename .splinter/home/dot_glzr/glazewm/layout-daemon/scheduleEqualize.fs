// §head home/dot_glzr/glazewm/layout-daemon.js:277-283 scheduleEqualize
// §sig function scheduleEqualize()
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debounceTimer = null;
    equalizeAll().catch((err) => log('equalize error:', err.message));
  }, DEBOUNCE_MS);
// §foot home/dot_glzr/glazewm/layout-daemon.js scheduleEqualize