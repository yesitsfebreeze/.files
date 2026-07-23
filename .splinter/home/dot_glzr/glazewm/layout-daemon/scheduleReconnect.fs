// §head home/dot_glzr/glazewm/layout-daemon.js:106-109 scheduleReconnect
// §sig function scheduleReconnect()
  setTimeout(connect, reconnectMs);
  reconnectMs = Math.min(reconnectMs * 2, RECONNECT_MAX_MS);
// §foot home/dot_glzr/glazewm/layout-daemon.js scheduleReconnect