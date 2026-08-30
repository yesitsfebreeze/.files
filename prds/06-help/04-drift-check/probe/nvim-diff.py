#!/usr/bin/env python3
"""probe — how many nvim-map targets resolve, with and without normalization."""
import json, re, subprocess, sys, collections
maps = json.load(open("/tmp/dc-nvim/maps.json"))
live = collections.defaultdict(list)
for m in maps:
    live[m["mode"]].append(m)

# corpus targets, via nu
out = subprocess.run(["nu","-n","-c",
  'let d = "/Users/feb/dev/dotfiles/home/dot_config/nushell/help"; '
  '["shell" "nvim" "terminal" "capsule"] | each {|f| open ($d | path join $"($f).nuon")} | flatten '
  '| each {|e| $e.verify | each {|t| {id: ($e.key? | default ($e.cmd? | default "")), title: $e.title, kind: $t.kind, '
  'mode: ($t.mode? | default ""), lhs: ($t.lhs? | default ""), '
  'hasdesc: ("desc" in ($t | columns)), desc: ($t.desc? | default null), scope: ($t.scope? | default "global")} } } '
  '| flatten | to json'], capture_output=True, text=True)
if out.returncode: print(out.stderr[:800]); sys.exit(1)
targets = [t for t in json.loads(out.stdout) if t["kind"] == "nvim-map"]
print(f"nvim-map targets: {len(targets)}")

LEADER = " "
def norm(lhs):
    s = lhs.replace("<leader>", LEADER).replace("<Leader>", LEADER)
    s = re.sub(r"<A-([^>]+)>", r"<M-\1>", s)
    s = re.sub(r"<C-([a-zA-Z])>", lambda m: "<C-%s>" % m.group(1).upper(), s)
    s = re.sub(r"<S-([a-zA-Z])>", lambda m: m.group(1).upper(), s)
    s = s.replace("<", "<lt>") if s == "<" else s
    return s

for label, fn in (("raw", lambda x: x), ("normalized", norm)):
    miss = []
    for t in targets:
        want = fn(t["lhs"])
        if not any(m["lhs"] == want for m in live[t["mode"]]):
            miss.append((t["mode"], t["lhs"], want, t["scope"]))
    print(f"  {label}: {len(targets)-len(miss)} resolve, {len(miss)} miss")
    if label == "normalized":
        buf = [m for m in miss if m[3] == "buffer"]
        glo = [m for m in miss if m[3] != "buffer"]
        print(f"    of the misses: {len(buf)} are scope:buffer, {len(glo)} are global")
        for m in glo: print(f"      GLOBAL MISS mode={m[0]} lhs={m[1]!r} -> {m[2]!r}")
        for m in buf: print(f"      buffer     mode={m[0]} lhs={m[1]!r}")

# desc three-state
absent = [t for t in targets if not t["hasdesc"]]
null_  = [t for t in targets if t["hasdesc"] and t["desc"] is None]
expl   = [t for t in targets if t["hasdesc"] and t["desc"] is not None]
print(f"desc: absent={len(absent)} null={len(null_)} explicit={len(expl)}")

# mismatch check for the absent class (compare live desc against title)
mm = 0; nodesc = 0
for t in absent:
    want = norm(t["lhs"])
    hit = next((m for m in live[t["mode"]] if m["lhs"] == want), None)
    if hit is None: continue
    if not hit.get("desc"): nodesc += 1; print(f"      ABSENT-BUT-LIVE-HAS-NO-DESC mode={t['mode']} lhs={t['lhs']!r} title={t['title']!r}")
    elif hit["desc"] != t["title"]: mm += 1; print(f"      MISMATCH mode={t['mode']} lhs={t['lhs']!r} live={hit['desc']!r} title={t['title']!r}")
print(f"absent-desc class: {mm} title/desc mismatches, {nodesc} live maps with no desc at all")
