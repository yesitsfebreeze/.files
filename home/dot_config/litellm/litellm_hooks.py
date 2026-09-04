"""The request path. Loaded by config.yaml `litellm_settings.callbacks`
(litellm resolves the module next to the config file — ~/.config/litellm/
litellm_hooks.py symlinks here; `llm sync` makes the link).

`model: auto` or `auto:<tier>`: a lookup in models.json — filter by tier,
by what the request carries (an image, a tools list) against the model's
stated caps, and by parked-state; sort by that job's precomputed score;
first goes out, every other candidate rides as litellm's per-request
`fallbacks` until one answers. No model is asked anything. ~1ms.

Every call's outcome is appended to performance.jsonl; a refusal parks the
model in status.json with the API's reason and a cooldown, an answer clears
it. `llm sync` folds the record back into the scores.
"""
import json, os, random, re, time
from litellm.integrations.custom_logger import CustomLogger

STATE = os.path.expanduser("~/.local/state/litellm")
MODELS, RECORD, STATUS = f"{STATE}/models.json", f"{STATE}/performance.jsonl", f"{STATE}/status.json"
EPSILON = 0.1  # one request in ten leads with a random untried model, so the record grows
# A context refusal is not a broken model — it is a request too big for that
# window. Park it a day (like unsupported): the walk drops to a wider model
# and the record says how big the request was. A short cooldown here just
# makes the same narrow model the first fallback on the next turn.
COOLDOWN = {"no-credit": 6 * 3600, "rate-limited": 15 * 60, "unsupported": 24 * 3600,
            "context": 24 * 3600, "error": 5 * 60}
JOB_WORDS = {"code": ("code", "review", "test", "refactor", "debug", "fix", "impl", "script"),
             "vision": ("image", "screenshot", "vision", "photo", "diagram"),
             "search": ("search", "research", "lookup", "find"),
             "agent": ("agent", "tool", "plan", "task", "workflow"),
             "document": ("document", "summar", "pdf", "report", "write", "essay")}
_CLAUDE = re.compile(r"opus|sonnet|haiku|fable|claude", re.I)
_THINK = {"thinking", "redacted_thinking"}
_cache = {}


def _json(path, default):
    """Parsed file, re-read only when its mtime moves."""
    try:
        mt = os.stat(path).st_mtime
        if _cache.get(path, (None,))[0] != mt:
            _cache[path] = (mt, json.load(open(path)))
        return _cache[path][1]
    except Exception:
        return default


def _write(path, obj):
    try:
        os.makedirs(STATE, exist_ok=True)
        with open(path + ".tmp", "w") as f:
            json.dump(obj, f, indent=2)
        os.replace(path + ".tmp", path)
    except Exception:
        pass


def task_of(data):
    tags = ((data.get("metadata") or {}).get("tags")) or []
    t = next((t.split("task:", 1)[1] for t in tags if t.startswith("task:")), None)
    u = data.get("user") or ""
    return t or (u.split("task:", 1)[1] if u.startswith("task:") else "untagged")


def needs(data):
    n = set()
    for m in data.get("messages") or []:
        c = m.get("content")
        if isinstance(c, list) and any((b.get("type") or "").startswith(("image", "input_image"))
                                       for b in c if isinstance(b, dict)):
            n.add("image")
    if data.get("tools"):
        n.add("tools")
    return n


def job_of(task, need):
    """Which arena job a task label is nearest: by what the request carries
    first (an image is vision, tools is agent), then by keyword, else text."""
    if "image" in need:
        return "vision"
    if "tools" in need:
        return "agent"
    t = task.lower()
    for job, words in JOB_WORDS.items():
        if any(w in t for w in words):
            return job
    return "text"


def classify(err):
    """What an API error means for availability, from its text (phrases as
    measured 2026-09-04: "balance greater than 0", "Insufficient balance",
    "Insufficient credits", "session usage limit", "is not supported")."""
    e = (err or "").lower()
    if any(k in e for k in ("insufficient balance", "insufficient credits", "balance greater than 0",
                            "payment required", "402", "no credit", "add credits")):
        return "no-credit"
    if any(k in e for k in ("429", "rate limit", "ratelimit", "usage limit", "too many requests", "quota")):
        return "rate-limited"
    if any(k in e for k in ("not supported", "not found", "does not exist", "no such model", "404")):
        return "unsupported"
    # A context-window refusal names the request size the model could not take.
    # It is its own state rather than `error` because the fix is not "try
    # again later" — the walk must drop to a wider model, and the record must
    # say how big the request was so the next sync can size it right.
    if any(k in e for k in ("context window", "context length", "context_length", "maximum context",
                            "too many tokens", "prompt is too long", "too long for")):
        return "context"
    return "error"


def est_tokens(data):
    """Rough size of the request in tokens: chars / 3.5, over messages, system
    and tools — conservative on purpose, an overflow costs a failed call."""
    n = sum(len(json.dumps(data.get(k) or "")) for k in ("messages", "system", "tools"))
    return int(n / 3.5)


def rank(models, status, task, tier, need, now=None, tokens=0):
    """Every eligible alias, best first: paid before free before local, and
    within each of those by score — the task's own record if the sync saw
    one, else the nearest job's precomputed score. A local model is the last
    resort, never a preference: it answers only when every remote one is
    gone. A model whose window is smaller than this request is out; a parked
    model is out too — unless nothing else is left, then the parked come back
    soonest-first rather than the request failing. So the walk is the live
    shelf, not the graveyard: one Claude Code turn used to try ~600 dead
    routes before it found a model, and the one it found was a 3B
    (2026-09-04)."""
    now = now or time.time()
    job = job_of(task, need)
    live, parked = [], []
    for a, m in models.items():
        if tier and m["tier"] != tier:
            continue
        c = m.get("caps") or {}
        if "image" in need and c.get("input") is not None and "image" not in c["input"]:
            continue
        if "tools" in need and c.get("tools") is False:
            continue
        if tokens and m.get("context") and m["context"] < tokens * 1.2:
            continue
        s = m.get("jobs", {})
        cls = 2 if m.get("local") else (0 if m["tier"] == "paid" else 1)
        score = (cls, -s.get(task, s.get(job, 0.4)))
        e = status.get(a)
        (parked if e and e.get("until", 0) > now else live).append((score, a, (e or {}).get("until", 0)))
    live.sort(key=lambda t: t[0])
    parked.sort(key=lambda t: t[2])
    out = [a for _, a, _ in live] or [a for _, a, _ in parked]
    if live and random.random() < EPSILON:
        # lead with a model this task has no record for, so the record grows —
        # from the same class as the leader, never a local one over a remote
        untried = [a for sc, a, _ in live if sc[0] == live[0][0][0] and task not in models[a].get("jobs", {})]
        if untried:
            pick = random.choice(untried)
            out.remove(pick); out.insert(0, pick)
    return out


def mark(alias, err, now=None):
    now = now or time.time()
    st = _json(STATUS, {})
    state = classify(err)
    prev = st.get(alias) or {}
    st[alias] = {"state": state, "since": prev.get("since") if prev.get("state") == state else now,
                 "until": now + COOLDOWN[state], "reason": (err or "")[:160]}
    _write(STATUS, st)


def clear(alias):
    st = _json(STATUS, {})
    if alias in st:
        del st[alias]
        _write(STATUS, st)


class Router(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        meta = data.get("metadata") or {}
        model = data.get("model") or ""
        if "dispatcher" not in (meta.get("tags") or []) and (model == "auto" or model.startswith("auto:")):
            tier = model.split(":", 1)[1] if ":" in model else None
            task, need = task_of(data), needs(data)
            ranked = rank(_json(MODELS, {}), _json(STATUS, {}), task, tier, need, tokens=est_tokens(data))
            if not ranked:
                from fastapi import HTTPException
                raise HTTPException(status_code=503, detail={
                    "error": f"no model available right now for {model} (task {task}, needs {sorted(need) or 'text'})"})
            data["model"], data["fallbacks"] = ranked[0], ranked[1:]
            data.setdefault("metadata", {})["router_task"] = task
            # `user` survives litellm's fallback call; our metadata does not
            data.setdefault("user", f"task:{task}")
        # Claude Code replays its own `thinking` blocks every turn; only Claude
        # wants them back (signature check), openai-compatible upstreams 400.
        if call_type == "anthropic_messages" and not _CLAUDE.search(data.get("model") or ""):
            for m in data.get("messages") or []:
                c = m.get("content")
                if m.get("role") == "assistant" and isinstance(c, list):
                    m["content"] = [b for b in c if b.get("type") not in _THINK]
        return data

    async def async_log_success_event(self, kwargs, response_obj, start_time, end_time):
        self._record(kwargs, None, start_time, end_time)

    async def async_log_failure_event(self, kwargs, response_obj, start_time, end_time):
        self._record(kwargs, str(kwargs.get("exception") or kwargs.get("error") or "error"), start_time, end_time)

    def _record(self, kwargs, err, t0, t1):
        meta = (kwargs.get("litellm_params") or {}).get("metadata") or {}
        if "dispatcher" in (meta.get("tags") or []):
            return
        task = meta.get("router_task") or task_of({"metadata": meta, "user": kwargs.get("user")
                                                   or (kwargs.get("litellm_params") or {}).get("user")})
        model = meta.get("model_group") or kwargs.get("model")  # the alias litellm actually ran
        rec = {"ts": time.time(), "kind": "call", "task": task, "model": model, "success": err is None,
               "latency_s": (t1 - t0).total_seconds() if t0 and t1 else None,
               # litellm hands the logging callbacks `model_call_details`: the
               # request lives under `messages` / `optional_params`, never `data`.
               "tokens": est_tokens({"messages": kwargs.get("messages"),
                                     "tools": (kwargs.get("optional_params") or {}).get("tools")})}
        if err:
            rec["state"], rec["error"] = classify(err), err[:160]
        try:
            with open(RECORD, "a") as f:
                f.write(json.dumps(rec) + "\n")
        except Exception:
            pass
        if model:
            mark(model, err) if err else clear(model)


router = Router()


if __name__ == "__main__":
    import asyncio, tempfile
    with tempfile.TemporaryDirectory() as d:
        MODELS, STATUS, RECORD = f"{d}/m.json", f"{d}/s.json", f"{d}/r.jsonl"
        _write(MODELS, {
            "a": {"tier": "free", "caps": {"input": ["text"], "tools": False}, "jobs": {"text": 0.6, "code": 0.5, "t": 1.0}},
            "b": {"tier": "free", "caps": {"input": None, "tools": None}, "jobs": {"text": 0.5, "code": 0.9}},
            "p": {"tier": "paid", "caps": {"input": ["text", "image"], "tools": True}, "jobs": {"text": 0.9, "vision": 0.9, "agent": 0.9}}})
        EPSILON = 0.0
        M, S = _json(MODELS, {}), {}
        assert rank(M, S, "t", "free", set()) == ["a", "b"]           # own record beats job score
        M3 = {"loc": {"tier": "free", "local": True, "caps": {}, "jobs": {"text": 0.99}},
              "fr": {"tier": "free", "caps": {}, "jobs": {"text": 0.3}},
              "pd": {"tier": "paid", "caps": {}, "jobs": {"text": 0.1}}}
        assert rank(M3, {}, "x", None, set()) == ["pd", "fr", "loc"]   # paid > free > local, whatever the score
        assert rank(M3, {"pd": {"until": time.time() + 9}}, "x", None, set()) == ["fr", "loc"]
        assert rank(M, S, "code-review", "free", set()) == ["b", "a"]  # keyword -> code
        assert rank(M, S, "x", None, {"image"}) == ["p", "b"]          # image: a says text-only
        assert rank(M, S, "x", None, {"tools"}) == ["p", "b"]          # tools: a says no
        assert job_of("summarize this", set()) == "document" and job_of("hello", set()) == "text"
        assert classify("Insufficient balance") == "no-credit" and classify("session usage limit") == "rate-limited"
        mark("b", "Insufficient credits", now=1000.0)
        assert _json(STATUS, {})["b"]["since"] == 1000.0
        mark("b", "Insufficient credits", now=2000.0)
        assert _json(STATUS, {})["b"]["since"] == 1000.0               # same state keeps its since
        S = {"b": {"state": "no-credit", "since": 1, "until": time.time() + 60}}
        assert rank(M, S, "code", "free", set()) == ["a"]              # parked is off the walk while a live one exists
        S["a"] = {"state": "error", "since": 1, "until": time.time() + 30}
        assert rank(M, S, "code", "free", set()) == ["a", "b"]         # all parked: soonest back first
        M2 = {"s": {"tier": "free", "caps": {}, "context": 8000, "jobs": {"text": 0.9}},
              "l": {"tier": "free", "caps": {}, "context": 200000, "jobs": {"text": 0.5}},
              "u": {"tier": "free", "caps": {}, "context": None, "jobs": {"text": 0.4}}}
        assert rank(M2, {}, "x", None, set(), tokens=20000) == ["l", "u"]  # too small a window is out; unknown stays
        assert est_tokens({"messages": [{"role": "user", "content": "x" * 3500}]}) >= 1000
        assert classify("This model's maximum context length is 32768 tokens") == "context"
        # the fallback list litellm appends to every error names hundreds of
        # models; a loose "context"/"exceeds"/"32k" match parked live ones a day
        assert classify("Insufficient credits. Fallbacks=[{'a-32k': ['b']}]") == "no-credit"
        assert classify("upstream 500. Available Model Group Fallbacks=['glm-128k']") == "error"
        clear("b"); assert "b" not in _json(STATUS, {})
        data = asyncio.run(router.async_pre_call_hook(None, None,
                           {"model": "auto:free", "metadata": {"tags": ["task:t"]}}, "completion"))
        assert data["model"] == "a" and data["fallbacks"] == ["b"] and data["user"] == "task:t"
        try:
            asyncio.run(router.async_pre_call_hook(None, None, {"model": "auto:paid", "tools": [{}],
                        "messages": [{"role": "user", "content": [{"type": "image"}]}]}, "completion"))
            asyncio.run(router.async_pre_call_hook(None, None, {"model": "auto:free", "tools": [{}],
                        "messages": [{"role": "user", "content": [{"type": "image"}]}]}, "completion"))
        except Exception as e:
            assert "no model available" in str(e.detail)
        import datetime
        now = datetime.datetime.now()
        asyncio.run(router.async_log_failure_event({"model": "x", "exception": "Insufficient credits",
                    "litellm_params": {"metadata": {"model_group": "a", "router_task": "t"}}}, None, now, now))
        r = json.loads(open(RECORD).readline())
        assert r["model"] == "a" and r["state"] == "no-credit" and not r["success"]
        assert "a" in _json(STATUS, {})
        asyncio.run(router.async_log_success_event({"model": "x", "litellm_params": {"metadata": {"model_group": "a"}},
                    "user": "task:t", "messages": [{"role": "user", "content": "x" * 3500}]}, None, now, now))
        assert "a" not in _json(STATUS, {})
        last = json.loads(open(RECORD).readlines()[-1])
        assert last["task"] == "t" and last["tokens"] >= 1000  # the record sizes the request, not {}
    print("ok")
