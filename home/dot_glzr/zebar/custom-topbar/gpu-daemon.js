// Zebar has no GPU provider. Poll nvidia-smi and drop gpu.json next to index.html
// so the bar can fetch it same-origin off zebar's asset server.
const { execFile } = require('child_process');
const { writeFileSync } = require('fs');
const { join } = require('path');

const OUT = join(__dirname, 'gpu.json');

const poll = () =>
  execFile(
    'nvidia-smi',
    ['--query-gpu=utilization.gpu,memory.used,memory.total', '--format=csv,noheader,nounits'],
    (err, stdout) => {
      if (err) return;
      const [usage, used, total] = stdout.trim().split('\n')[0].split(',').map(s => +s.trim());
      writeFileSync(OUT, JSON.stringify({ usage, used, total }));
    },
  );

poll();
setInterval(poll, 2000);
