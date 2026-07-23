// §head home/dot_glzr/glazewm/layout-daemon.js:74-104 connect
// §sig function connect()
  log('connecting to', `ws://localhost:${PORT}`);
  let socket;
  try {
    socket = new WebSocket(`ws://localhost:${PORT}`);
  } catch {
    scheduleReconnect();
    return;
  }
  ws = socket;

  socket.addEventListener('open', () => {
    log('connected');
    reconnectMs = RECONNECT_MS;
    send(`sub --events ${EVENTS.join(' ')}`).catch(() => {});
    scheduleEqualize();
  });

  socket.addEventListener('message', (ev) => onMessage(ev.data));

  socket.addEventListener('close', () => {
    log('disconnected');
    failPending(new Error('socket closed'));
    if (ws === socket) ws = null;
    scheduleReconnect();
  });

  socket.addEventListener('error', () => {
    // `close` follows and handles reconnect.
  });
// §foot home/dot_glzr/glazewm/layout-daemon.js connect