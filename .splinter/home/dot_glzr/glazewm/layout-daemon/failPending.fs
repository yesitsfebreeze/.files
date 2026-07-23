// §head home/dot_glzr/glazewm/layout-daemon.js:111-117 failPending
// §sig function failPending(err)
  for (const { reject, timer } of pending.values()) {
    clearTimeout(timer);
    reject(err);
  }
  pending.clear();
// §foot home/dot_glzr/glazewm/layout-daemon.js failPending