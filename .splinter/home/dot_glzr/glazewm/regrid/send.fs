// §head home/dot_glzr/glazewm/regrid.js:13-24 send
// §sig function send(message)
  return new Promise((resolve, reject) => {
    let key = message;
    while (pending.has(key)) key += ' ';
    const timer = setTimeout(() => {
      pending.delete(key);
      reject(new Error('timeout'));
    }, 4000);
    pending.set(key, { resolve, reject, timer });
    ws.send(key);
  });
// §foot home/dot_glzr/glazewm/regrid.js send