// §head home/dot_glzr/glazewm/layout-daemon.js:119-151 onMessage
// §sig function onMessage(raw)
  let msg;
  try {
    msg = JSON.parse(typeof raw === 'string' ? raw : raw.toString());
  } catch {
    return;
  }

  if (msg.messageType === 'client_response') {
    const entry = pending.get(msg.clientMessage);
    if (entry) {
      pending.delete(msg.clientMessage);
      clearTimeout(entry.timer);
      if (msg.success) entry.resolve(msg.data);
      else entry.reject(new Error(msg.error || 'command failed'));
    }
    return;
  }

  if (msg.messageType !== 'event_subscription') return;
  const data = msg.data || {};

  if (data.eventType === 'window_managed') {
    const win = data.managedWindow || data.window;
    if (win && win.id) {
      onManaged(win.id);
      return;
    }
  }

  if (Date.now() < suppressUntil) return;
  scheduleEqualize();
// §foot home/dot_glzr/glazewm/layout-daemon.js onMessage