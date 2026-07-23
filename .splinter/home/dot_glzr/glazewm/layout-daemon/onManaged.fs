// §head home/dot_glzr/glazewm/layout-daemon.js:216-226 onManaged
// §sig async function onManaged(id)
  try {
    await place(id);
    await equalizeAll();
  } catch (err) {
    log('place error:', err.message);
  }
  for (const ms of SETTLE_MS) {
    setTimeout(() => settle(id).catch((e) => log('settle error:', e.message)), ms);
  }
// §foot home/dot_glzr/glazewm/layout-daemon.js onManaged