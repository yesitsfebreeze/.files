#!/usr/bin/env python3
import sys, os, json, time, fcntl, socket, signal, threading, subprocess

USAGE = (
    "usage: bus.py register <id> [branch] [ttl] | post <from> <to> <body...> | "
    "ask <from> <to> <body...> | reply <from> <to> <token> <body...> | "
    "claim <holder> <key...> | release <holder> [key...] | claims [prefix] | "
    "inbox <id> | read <id> | watch <id> [match] [timeout] | "
    "roster | count | signals [id] | peek [id] | board | gc | daemon | mcp\n"
    "addresses: explicit id, '*' broadcast, or logical 'vision' / 'up' / 'my-organizer'"
)
DEFAULT_TTL = 1800


def _root():
  try:
    c = subprocess.check_output(["git", "rev-parse", "--git-common-dir"],
                                text=True, stderr=subprocess.DEVNULL).strip()
  except Exception:
    return os.getcwd()
  if not os.path.isabs(c):
    c = os.path.join(os.getcwd(), c)
  return os.path.dirname(os.path.abspath(c))


BASE = os.environ.get("VOIT_BUS_DIR") or _root()
SOCK = os.path.join(BASE, ".voitbus.sock")
PIDF = os.path.join(BASE, ".voitbus.pid")
SNAP = os.path.join(BASE, ".voitbus.json")
IDLE = float(os.environ.get("VOIT_BUS_IDLE") or 900)


def _unread(d, aid):
  cur = d["cursors"].get(aid, 0)
  return [m for m in d["messages"] if m["id"] > cur and m["to"] in (aid, "*")]


def _hit(body, match):
  if not match:
    return True
  return any(tok == match or (tok.startswith(match) and not match[-1].isalnum())
             for tok in body.split())


def _fmt(m):
  return "#%d %s: %s" % (m["id"], m["from"], m["body"])


def _live(d, holder):
  a = d["agents"].get(holder)
  return bool(a) and time.time() - a["ts"] <= a["ttl"]


def _read_by(d, m):
  if m["to"] == "*":
    curs = d["cursors"]
    return bool(curs) and all(c >= m["id"] for c in curs.values())
  return d["cursors"].get(m["to"], 0) >= m["id"]


def _resolve(d, frm, to):
  if to in ("up", "my-organizer"):
    b = (d["agents"].get(frm) or {}).get("branch", "")
    if b.startswith("implement-"):
      for k, v in d["agents"].items():
        ob = v.get("branch", "")
        if ob.startswith("organize-") and \
                b.startswith("implement-" + ob[len("organize-"):] + "-"):
          return k
    return "vision"
  return to


class Daemon:
  def __init__(self):
    self.cond = threading.Condition()
    self.state = self._load()
    self.last = time.time()
    self.conns = 0

  def _load(self):
    try:
      d = json.load(open(SNAP))
    except Exception:
      d = {}
    d.setdefault("agents", {}); d.setdefault("messages", [])
    d.setdefault("cursors", {}); d.setdefault("seq", 0)
    d.setdefault("claims", {})
    return d

  def _snapshot(self):
    tmp = SNAP + ".tmp"
    with open(tmp, "w") as f:
      json.dump(self.state, f)
    os.replace(tmp, SNAP)

  def _post(self, frm, to, body):
    d = self.state; d["seq"] += 1; n = d["seq"]
    d["messages"].append({"id": n, "from": frm, "to": _resolve(d, frm, to),
                          "body": body, "ts": time.time()})
    self._snapshot(); self.cond.notify_all()
    return n

  def op(self, name, args):
    d = self.state
    if name == "register":
      aid = args[0]; branch = args[1] if len(args) > 1 else ""
      ttl = int(args[2]) if len(args) > 2 else DEFAULT_TTL
      d["agents"][aid] = {"branch": branch or "", "ts": time.time(), "ttl": ttl}
      d["cursors"].setdefault(aid, 0); self._snapshot()
      return aid
    if name == "post":
      return self._post(args[0], args[1], args[2])
    if name == "ask":
      tok = str(d["seq"] + 1)
      return [self._post(args[0], args[1], "ask:%s %s" % (tok, args[2])), tok]
    if name == "reply":
      return self._post(args[0], args[1], "reply:%s %s" % (args[2], args[3]))
    if name == "claim":
      holder = args[0]; keys = args[1:]; cl = d["claims"]
      conflicts = {k: cl[k]["holder"] for k in keys
                   if k in cl and cl[k]["holder"] != holder and _live(d, cl[k]["holder"])}
      if not conflicts:
        now = time.time()
        for k in keys:
          cl[k] = {"holder": holder, "ts": now}
        self._snapshot()
      return {"ok": not conflicts, "conflicts": conflicts}
    if name == "release":
      holder = args[0]; keys = args[1:]; cl = d["claims"]
      drop = [k for k, v in cl.items()
              if v["holder"] == holder and (not keys or k in keys)]
      for k in drop:
        del cl[k]
      self._snapshot()
      return drop
    if name == "claims":
      prefix = args[0] if args else ""
      return [[k, v["holder"]] for k, v in d["claims"].items() if k.startswith(prefix)]
    if name == "inbox":
      return _unread(d, args[0])
    if name == "read":
      msgs = _unread(d, args[0])
      if d["messages"]:
        d["cursors"][args[0]] = d["messages"][-1]["id"]
      self._snapshot()
      return msgs
    if name == "roster":
      now = time.time()
      return [(k, v["branch"]) for k, v in d["agents"].items()
              if now - v["ts"] <= v["ttl"]]
    if name == "gc":
      now = time.time()
      d["agents"] = {k: v for k, v in d["agents"].items() if now - v["ts"] <= v["ttl"]}
      d["messages"] = [m for m in d["messages"] if not _read_by(d, m)]
      d["cursors"] = {k: c for k, c in d["cursors"].items() if k in d["agents"]}
      d["claims"] = {k: v for k, v in d.get("claims", {}).items() if _live(d, v["holder"])}
      self._snapshot()
      return None
    raise ValueError("unknown op: %s" % name)

  def watch(self, aid, match, timeout):
    end = time.time() + timeout if timeout > 0 else None
    with self.cond:
      while True:
        hits = [m for m in _unread(self.state, aid) if _hit(m["body"], match)]
        if hits:
          return hits
        if end is not None:
          remaining = end - time.time()
          if remaining <= 0:
            return None
          self.cond.wait(remaining)
        else:
          self.cond.wait()

  def serve(self, conn):
    with self.cond:
      self.conns += 1
    try:
      f = conn.makefile("rwb")
      line = f.readline()
      if not line:
        return
      req = json.loads(line.decode())
      name = req.get("op"); args = req.get("args") or []
      if name == "watch":
        hits = self.watch(args[0], args[1] if len(args) > 1 else "",
                          float(args[2]) if len(args) > 2 else 0.0)
        resp = {"ok": True, "result": hits}
      else:
        with self.cond:
          self.last = time.time()
          try:
            resp = {"ok": True, "result": self.op(name, args)}
          except Exception as e:
            resp = {"ok": False, "error": str(e)}
      f.write((json.dumps(resp) + "\n").encode()); f.flush()
    except Exception:
      pass
    finally:
      with self.cond:
        self.conns -= 1
      try:
        conn.close()
      except Exception:
        pass


def daemon(a):
  lock = open(PIDF, "a+")
  try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
  except OSError:
    return
  lock.seek(0); lock.truncate(); lock.write(str(os.getpid())); lock.flush()
  try:
    os.unlink(SOCK)
  except OSError:
    pass
  srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
  srv.bind(SOCK); srv.listen(64); srv.settimeout(60.0)
  d = Daemon()

  def shutdown(*_):
    with d.cond:
      try:
        d._snapshot()
      except Exception:
        pass
    try:
      os.unlink(SOCK)
    except OSError:
      pass
    os._exit(0)

  signal.signal(signal.SIGTERM, shutdown)
  signal.signal(signal.SIGINT, shutdown)
  while True:
    try:
      conn, _ = srv.accept()
    except socket.timeout:
      with d.cond:
        idle = time.time() - d.last
        active = d.conns
      if active == 0 and idle > IDLE:
        shutdown()
      continue
    except OSError:
      continue
    threading.Thread(target=d.serve, args=(conn,), daemon=True).start()


def _connect():
  s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
  s.connect(SOCK)
  return s


def _ensure():
  try:
    _connect().close(); return
  except OSError:
    pass
  subprocess.Popen([sys.executable, os.path.abspath(__file__), "daemon"],
                   stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL, start_new_session=True)
  for _ in range(100):
    time.sleep(0.05)
    try:
      _connect().close(); return
    except OSError:
      pass
  raise RuntimeError("voit bus daemon did not start at %s" % SOCK)


def _txn(op, args):
  s = _connect()
  try:
    s.sendall((json.dumps({"op": op, "args": args}) + "\n").encode())
    line = s.makefile("rb").readline()
  finally:
    try:
      s.close()
    except Exception:
      pass
  if not line:
    raise OSError("empty response")
  resp = json.loads(line.decode())
  if not resp.get("ok"):
    raise RuntimeError(resp.get("error") or "bus error")
  return resp.get("result")


def _call(op, args):
  try:
    return _txn(op, args)
  except OSError:
    _ensure()
    return _txn(op, args)


def _call_if_up(op, args):
  if not os.path.exists(SOCK):
    return None
  try:
    return _txn(op, args)
  except Exception:
    return None


def _busid_from_cwd():
  cl = os.path.join(os.getcwd(), ".claude")
  try:
    bid = open(os.path.join(cl, "busid")).read().strip()
    if bid:
      return bid
  except Exception:
    pass
  try:
    role = open(os.path.join(cl, "role")).read().strip()
  except Exception:
    role = ""
  if role and role != "vision":
    try:
      return subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"],
                                     text=True, stderr=subprocess.DEVNULL).strip() or "vision"
    except Exception:
      return "vision"
  return "vision"


def register(a):
  print("registered " + _call("register",
        [a[0], a[1] if len(a) > 1 else "", a[2] if len(a) > 2 else DEFAULT_TTL]))


def post(a):
  print("posted #%d -> %s" % (_call("post", [a[0], a[1], " ".join(a[2:])]), a[1]))


def ask(a):
  n, tok = _call("ask", [a[0], a[1], " ".join(a[2:])])
  print("posted #%d ask:%s -> %s | wait: bus.py watch %s reply:%s" % (n, tok, a[1], a[0], tok))


def reply(a):
  print("posted #%d -> %s" % (_call("reply", [a[0], a[1], a[2], " ".join(a[3:])]), a[1]))


def claim(a):
  r = _call("claim", a)
  if r["ok"]:
    print("claimed " + " ".join(a[1:]))
  else:
    print("conflict " + " ".join("%s=%s" % (k, h) for k, h in r["conflicts"].items()))
    sys.exit(1)


def release(a):
  print("released " + " ".join(_call("release", a)))


def claims(a):
  for k, h in _call("claims", a):
    print("%s\t%s" % (k, h))


def inbox(a):
  for m in _call("inbox", [a[0]]):
    print(_fmt(m))


def read(a):
  for m in _call("read", [a[0]]):
    print(_fmt(m))


def watch(a):
  hits = _call("watch", [a[0], a[1] if len(a) > 1 else "",
                         float(a[2]) if len(a) > 2 else 0.0])
  if not hits:
    sys.exit(1)
  for m in hits:
    print(_fmt(m))


def roster(a):
  for k, b in _call("roster", []):
    print("%s\t%s" % (k, b))


def count(a):
  r = _call_if_up("roster", [])
  if r:
    print(len(r))


def signals(a):
  msgs = _call_if_up("inbox", [a[0] if a else _busid_from_cwd()])
  if msgs is None:
    return
  c = {"ready": 0, "reply": 0, "ask": 0, "other": 0}
  for m in msgs:
    c[next((k for k in ("ready", "reply", "ask")
            if m["body"].startswith(k + ":")), "other")] += 1
  if c["ready"] + c["reply"] + c["ask"] > 0:
    print("ready %d reply %d ask %d" % (c["ready"], c["reply"], c["ask"]))
  elif c["other"] > 0:
    print("waiting %d" % c["other"])


def peek(a):
  bid = a[0] if a else _busid_from_cwd()
  msgs = _call_if_up("inbox", [bid])
  if not msgs:
    return
  print("[bus] unread for %s (peek — run `bus read %s` to consume):" % (bid, bid))
  for m in msgs:
    print(_fmt(m))


def board(a):
  try:
    refs = subprocess.check_output(
        ["git", "for-each-ref", "--format=%(refname:short)", "refs/heads"],
        text=True, stderr=subprocess.DEVNULL).split()
  except Exception:
    return
  slices = sorted(b[len("organize-"):] for b in refs if b.startswith("organize-"))
  if not slices:
    return
  live = {k for k, _ in (_call_if_up("roster", []) or [])}
  unread = []
  for aid in ["vision"] + ["organize-" + s for s in slices]:
    unread += _call_if_up("inbox", [aid]) or []
  ready = {m["body"].split()[0][len("ready:"):]
           for m in unread if m["body"].startswith("ready:")}

  def ahead(base, tip):
    try:
      return int(subprocess.check_output(
          ["git", "rev-list", "--count", "%s..%s" % (base, tip)],
          text=True, stderr=subprocess.DEVNULL))
    except Exception:
      return 0

  def state(branch, n):
    if branch in ready and n > 0:
      return "READY unfolded (%d ahead) <- fold it" % n
    if n == 0:
      return "folded"
    return "dispatched (%d ahead%s)" % (n, ", live" if branch in live else "")

  trunk = next((b for b in ("main", "master") if b in refs), None)
  for s in slices:
    sb = "organize-" + s
    print("%s\t%s" % (sb, state(sb, ahead(trunk, sb) if trunk else 0)))
    for t in sorted(b for b in refs if b.startswith("implement-" + s + "-")):
      print("  %s\t%s" % (t, state(t, ahead(sb, t))))


def gc(a):
  _call("gc", []); print("gc done")


MCP_TOOLS = [
    ("bus_register", "Register or refresh this agent on the shared bus roster.",
     {"id": "string", "branch": "string", "ttl": "integer"}, ["id"]),
    ("bus_post", "Post a message to another agent's mailbox ('*' broadcasts; logical "
                 "'vision'/'up'/'my-organizer' resolve by branch lineage).",
     {"from": "string", "to": "string", "body": "string"}, ["from", "to", "body"]),
    ("bus_ask", "Ask another agent a question; returns a correlation token to watch "
                "for the reply (watch <self> reply:<token>).",
     {"from": "string", "to": "string", "body": "string"}, ["from", "to", "body"]),
    ("bus_reply", "Answer an ask, correlating by the token from the ask.",
     {"from": "string", "to": "string", "token": "string", "body": "string"},
     ["from", "to", "token", "body"]),
    ("bus_claim", "Atomically claim a set of keys (space-separated) - e.g. one "
                  "file:<path> per file a task will touch, or slice:<slice> before a "
                  "reconcile/promote. All-or-nothing: if any key is held by another live "
                  "agent, nothing is claimed and the conflicts are returned; re-claiming "
                  "keys you already hold is idempotent.",
     {"holder": "string", "keys": "string"}, ["holder", "keys"]),
    ("bus_release", "Release the space-separated keys you hold, or all your claims if "
                    "keys is omitted.",
     {"holder": "string", "keys": "string"}, ["holder"]),
    ("bus_claims", "List current claims (optionally filtered by key prefix) as "
                   "key<TAB>holder.",
     {"prefix": "string"}, []),
    ("bus_inbox", "Peek an agent's unread messages without consuming them.",
     {"id": "string"}, ["id"]),
    ("bus_read", "Read an agent's unread messages and advance its cursor.",
     {"id": "string"}, ["id"]),
    ("bus_roster", "List the agents currently live on the bus.", {}, []),
    ("bus_gc", "Drop expired agents and messages every recipient has already read.", {}, []),
]


def _mcp_call(name, args):
  if name == "bus_register":
    return "registered " + _call("register",
        [args["id"], args.get("branch", ""), args.get("ttl", DEFAULT_TTL)])
  if name == "bus_post":
    return "posted #%d -> %s" % (
        _call("post", [args["from"], args["to"], args["body"]]), args["to"])
  if name == "bus_ask":
    n, tok = _call("ask", [args["from"], args["to"], args["body"]])
    return "asked #%d -> %s; watch reply:%s for the answer" % (n, args["to"], tok)
  if name == "bus_reply":
    return "posted #%d -> %s" % (
        _call("reply", [args["from"], args["to"], args["token"], args["body"]]), args["to"])
  if name == "bus_claim":
    r = _call("claim", [args["holder"]] + args["keys"].split())
    return ("claimed " + args["keys"]) if r["ok"] else \
        ("conflict " + " ".join("%s=%s" % (k, h) for k, h in r["conflicts"].items()))
  if name == "bus_release":
    return "released " + " ".join(
        _call("release", [args["holder"]] + args.get("keys", "").split()))
  if name == "bus_claims":
    return "\n".join("%s\t%s" % (k, h)
                     for k, h in _call("claims", [args.get("prefix", "")])) or "(no claims)"
  if name == "bus_inbox":
    return "\n".join(_fmt(m) for m in _call("inbox", [args["id"]])) or "(no unread messages)"
  if name == "bus_read":
    return "\n".join(_fmt(m) for m in _call("read", [args["id"]])) or "(no unread messages)"
  if name == "bus_roster":
    return "\n".join("%s\t%s" % (k, b) for k, b in _call("roster", [])) or "(roster empty)"
  if name == "bus_gc":
    _call("gc", []); return "gc done"
  raise ValueError("unknown tool: " + str(name))


def mcp(a):
  def send(obj):
    sys.stdout.write(json.dumps(obj) + "\n"); sys.stdout.flush()

  for line in sys.stdin:
    line = line.strip()
    if not line:
      continue
    try:
      msg = json.loads(line)
    except Exception:
      continue
    mid, method = msg.get("id"), msg.get("method")
    if method == "initialize":
      send({"jsonrpc": "2.0", "id": mid, "result": {
          "protocolVersion": (msg.get("params") or {}).get("protocolVersion", "2024-11-05"),
          "capabilities": {"tools": {}},
          "serverInfo": {"name": "voit-bus", "version": "0.1.0"}}})
    elif method == "tools/list":
      send({"jsonrpc": "2.0", "id": mid, "result": {"tools": [
          {"name": n, "description": desc, "inputSchema": {
              "type": "object",
              "properties": {k: {"type": t} for k, t in props.items()},
              "required": req}}
          for n, desc, props, req in MCP_TOOLS]}})
    elif method == "tools/call":
      p = msg.get("params") or {}
      try:
        text = _mcp_call(p.get("name"), p.get("arguments") or {})
        err = False
      except Exception as e:
        text, err = "error: %s" % e, True
      send({"jsonrpc": "2.0", "id": mid, "result": {
          "content": [{"type": "text", "text": text}], "isError": err}})
    elif method == "ping":
      send({"jsonrpc": "2.0", "id": mid, "result": {}})
    elif mid is not None:
      send({"jsonrpc": "2.0", "id": mid,
            "error": {"code": -32601, "message": "method not found: %s" % method}})


CMDS = {"register": register, "post": post, "ask": ask, "reply": reply,
        "claim": claim, "release": release, "claims": claims,
        "inbox": inbox, "read": read, "watch": watch, "roster": roster,
        "count": count, "signals": signals, "peek": peek, "board": board,
        "gc": gc, "daemon": daemon, "mcp": mcp}


def main():
  if len(sys.argv) < 2 or sys.argv[1] not in CMDS:
    print(USAGE, file=sys.stderr); sys.exit(2)
  CMDS[sys.argv[1]](sys.argv[2:])


if __name__ == "__main__":
  main()
