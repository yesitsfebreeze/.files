// §head home/dot_glzr/glazewm/layout-daemon.js:178-180 command
// §sig function command(cmd, subjectId)
  return send(subjectId ? `command --id ${subjectId} ${cmd}` : `command ${cmd}`);
// §foot home/dot_glzr/glazewm/layout-daemon.js command