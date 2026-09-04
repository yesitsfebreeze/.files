"""The request path. Loaded by config.yaml `litellm_settings.callbacks`
(litellm resolves the module next to the config file — ~/.config/litellm/
litellm_hooks.py symlinks here; `llm sync` makes the link).

`model: auto` or `auto:<tier>`: a lookup in models.json — filter by tier,
by what the request carries (an image, a tools list) against the model's
stated caps, and by parked-state; sort by that job's precomputed score;
first goes out, every other candidate rides as litellm's per-request
`fallbacks` until one answers — litellm walks them before the first byte,
the streaming hook below walks them after it. No model is asked anything. ~1ms.

Every call's outcome is appended to performance.jsonl; a refusal parks the
model in status.json with the API's reason and a time to probe it — the
API's own reset time when it names one, else a cooldown by kind. A parked
model stays off the walk until the proxy has asked it for one token and it
answered; a refusal parks it again. `llm sync` folds the record back into
the scores.
"""
import json, os, random, re, time
from litellm.integrations.custom_logger import CustomLogger

STATE = os.path.expanduser("~/.local/state/litellm")
MODELS, RECORD, STATUS = f"{STATE}/models.json", f"{STATE}/performance.jsonl", f"{STATE}/status.json"

# litellm resolves every `os.environ/` in config.yaml before it imports this
# module, so keys cannot be loaded here: a bare `litellm --config` with none
# in its env parks the whole shelf as "Missing credentials" within minutes
# (2026-09-04). Refuse to start instead — `llm serve` is the launch.
if __name__ != "__main__":
    try:
        _want = [l.strip().removeprefix("export ").partition("=")[0].strip() for l in open(f"{STATE}/credentials.env")]
    except FileNotFoundError:
        _want = []
    _missing = [k for k in _want if k and k not in os.environ]
    if _missing:
        raise SystemExit(f"litellm_hooks: {', '.join(_missing)} not in env — launch the proxy with `llm serve`")
EPSILON = 0.1  # one request in ten leads with a random untried model, so the record grows
# A context refusal is not a broken model — it is a request too big for that
# window. Park it a day (like unsupported): the walk drops to a wider model
# and the record says how big the request was. A short cooldown here just
# makes the same narrow model the first fallback on the next turn.
COOLDOWN = {"no-credit": 6 * 3600, "rate-limited": 2 * 60, "unsupported": 24 * 3600,
            "context": 24 * 3600, "error": 5 * 60}
MEDIA_TOKENS = 1600  # what an image or page costs a model, whatever its base64 weighs
# What a refusal asks of the user, by the phrase the API used (measured
# 2026-09-04). First match wins; the URL in the message rides along.
FIX = (("requires explicit opt in", "opt in"), ("provider you have enabled", "enable a provider for it"),
       ("insufficient credits", "add credits"), ("insufficient balance", "top up"),
       ("depleted your monthly", "buy credits"), ("balance greater than 0", "top up (anti-abuse gate)"),
       ("free-models-per-day", "daily free quota: wait for the reset or add credits"),
       ("batch api", "batch-only: drop it at sync"), ("support image input", "text-only: drop its image cap at sync"),
       ("not valid", "gone: drop it at sync"), ("not supported", "gone: drop it at sync"),
       ("no endpoints", "gone: drop it at sync"), ("0 endpoints", "gone: drop it at sync"))
PROBE_EVERY, PROBE_BATCH = 60, 20  # a sweep a minute, so 600 parks expiring together take half an hour, not a burst
# A user request that arrives after `until` would land on a model the proxy
# hasn't confirmed is back. Probe a few minutes before the stated reset so
# the answer (cleared, or re-parked with the new reason) is in by then — a
# subscription the user has been told is back is in the walk, not behind a
# cold start. No shorter than a minute, no longer than half the cooldown
# (so context/unsupported parks don't get probed every five minutes).
PROBE_EARLY = {"no-credit": 300, "rate-limited": 30, "unsupported": 3600, "context": 3600, "error": 60}
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


def _blocks(o):
    """Every dict in the request, however deep — a screenshot Claude Code
    reads back comes nested in a tool_result, not at the top of a message."""
    if isinstance(o, dict):
        yield o
        for v in o.values():
            yield from _blocks(v)
    elif isinstance(o, list):
        for v in o:
            yield from _blocks(v)


def _media(b):
    """The base64 payload of an image/document block, else None."""
    s = b.get("source")
    if isinstance(s, dict) and isinstance(s.get("data"), str):
        return s["data"]
    u = b.get("image_url")
    u = u.get("url") if isinstance(u, dict) else u
    return u if isinstance(u, str) and u.startswith("data:") else None


def needs(data):
    n = set()
    if any((b.get("type") or "").startswith(("image", "input_image")) for b in _blocks(data.get("messages"))):
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


def window_of(err):
    """The window a context refusal names ("maximum context length is 131072
    tokens", "context length of 32768"), or None. A fact from the model, so
    `llm sync` sizes it by this over anything a provider stated."""
    m = re.search(r"context (?:length|window)\D{0,24}?(\d{4,8})", err or "", re.I)
    return int(m.group(1)) if m else None


def unlock_at(err, now):
    """When the API itself says the model is back — openrouter's reset
    header (ms epoch), "try again in 30 seconds", "retry after 2 minutes" —
    clamped to [1 min, 24 h] from now; None when it says nothing."""
    e = err or ""
    m = re.search(r"X-RateLimit-Reset\W+(\d{13})", e)
    t = int(m.group(1)) / 1000 if m else None
    if t is None:
        m = re.search(r"(?:retry|try again)\s+(?:after|in)\s+(\d+)\s*(s|m|h)", e, re.I)
        t = now + int(m.group(1)) * {"s": 1, "m": 60, "h": 3600}[m.group(2).lower()] if m else None
    return min(max(t, now + 60), now + 86400) if t else None


def est_tokens(data):
    """Rough size of the request in tokens: chars / 3.5, over messages, system
    and tools — conservative on purpose, an overflow costs a failed call. An
    image or page counts flat, not by its base64: six screenshots weighed in
    as 9.1M tokens once and no window on the shelf holds that (2026-09-04)."""
    n = sum(len(json.dumps(data[k])) for k in ("messages", "system", "tools") if data.get(k))
    media = [m for b in _blocks(data.get("messages")) if (m := _media(b))]
    return int((n - sum(map(len, media))) / 3.5) + len(media) * MEDIA_TOKENS


def fix_of(err):
    """What would unlock a refused model, in the user's hands — "add credits:
    <url>", "opt in: <url>", "gone: drop it at sync" — or None when the
    text says nothing anyone can act on."""
    e = (err or "").lower()
    verb = next((v for k, v in FIX if k in e), None)
    m = re.search(r"https?://[^\s\"'<>)\]]+", err or "")
    return f"{verb}: {m.group(0)}" if verb and m else verb


def rank(models, status, task, tier, need, now=None, tokens=0, out=0):
    """Every eligible alias, best first: paid before free before local, and
    within each of those by score — the task's own record if the sync saw
    one, else the nearest job's precomputed score. A local model is the last
    resort, never a preference: it answers only when every remote one is
    gone. A model whose window is smaller than this request plus the answer
    it asks for is out — and so is one whose window is unknown: unknown once
    meant "fits", which walked a 67K request into a 32K model (2026-09-04).
    A parked model is out too, whether or not its `until` has lapsed: only a probe or
    a real answer clears it — unless nothing else is left, then the parked
    come back soonest-first rather than the request failing. So the walk is the live
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
        if tokens and (m.get("context") or 0) < tokens * 1.2 + out:
            continue
        s = m.get("jobs", {})
        cls = 2 if m.get("local") else (0 if m["tier"] == "paid" else 1)
        score = (cls, -s.get(task, s.get(job, 0.4)))
        e = status.get(a)
        (parked if e else live).append((score, a, (e or {}).get("until", 0)))
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
    st = dict(_json(STATUS, {}))  # a lapsed park stays until the probe clears it; dropping it here un-parked models unprobed
    state = classify(err)
    prev = st.get(alias) or {}
    st[alias] = {"state": state, "since": prev.get("since") if prev.get("state") == state else now,
                 "until": unlock_at(err, now) or now + COOLDOWN[state], "reason": (err or "")[:160]}
    if fix := fix_of(err):
        st[alias]["fix"] = fix
    _write(STATUS, st)


def clear(alias):
    st = _json(STATUS, {})
    if alias in st:
        del st[alias]
        _write(STATUS, st)


async def probe():
    """Every parked model whose `until` is due (or close enough — a state-
    specific lead time so a subscription the API says is back at 14:32 is in
    the walk by 14:27, not discovered at 14:33) is asked for one token before
    it may return to the walk: an answer clears it, a refusal parks it again
    with the fresh reason. So a user request never leads with a model that
    is still dead, and `llm status`'s "probe in" is a time the proxy will
    actually check."""
    import asyncio
    while True:
        await asyncio.sleep(PROBE_EVERY)
        try:
            from litellm.proxy.proxy_server import llm_router
            now = time.time()
            due = []
            for a, e in _json(STATUS, {}).items():
                u = e.get("until", 0)
                lead = PROBE_EARLY.get(e.get("state", "error"), 60)
                if u - lead <= now:
                    due.append((u, a, e.get("state", "error")))
            due.sort()
            for _, a, _ in due[:PROBE_BATCH]:
                try:
                    # no fallbacks: a sibling hop answering must not clear this one
                    await asyncio.wait_for(llm_router.acompletion(
                        model=a, messages=[{"role": "user", "content": "ok"}], max_tokens=1,
                        metadata={"tags": ["dispatcher"]}, disable_fallbacks=True), 60)
                    clear(a)
                except Exception as e:
                    mark(a, str(e))
        except Exception:
            pass


class Router(CustomLogger):
    _probe = None

    def _start_probe(self):
        if Router._probe is None:
            import asyncio
            Router._probe = asyncio.ensure_future(probe())

    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        self._start_probe()
        model = data.get("model") or ""
        if model == "auto" or model.startswith("auto:"):
            tier = model.split(":", 1)[1] if ":" in model else None
            task, need, tokens = task_of(data), needs(data), est_tokens(data)
            ranked = rank(_json(MODELS, {}), _json(STATUS, {}), task, tier, need,
                          tokens=tokens, out=int(data.get("max_tokens") or 0))
            if not ranked:
                from fastapi import HTTPException
                raise HTTPException(status_code=503, detail={
                    "error": f"no model available right now for {model} (task {task}, needs {sorted(need) or 'text'}, ~{tokens} tokens)"})
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

    async def async_post_call_streaming_iterator_hook(self, user_api_key_dict, response, request_data):
        """The walk continues past the first byte. An upstream that answers 200
        and then puts its 429 in the stream (openrouter's "Provider returned
        error") is past litellm's fallbacks — the error went to Claude Code
        as-is and the turn was lost (2026-09-04). Here every stream is ours:
        while nothing has been sent, a failed stream is replaced by the next
        candidate's, and the record already parked the one that failed."""
        rest = list(request_data.get("fallbacks") or [])
        sent = False
        while True:
            try:
                async for chunk in response:
                    sent = True  # ponytail: any event counts, even a bare message_start; buffer up to the first delta if a client ever chokes on a restart
                    yield chunk
                return
            except Exception:
                if sent or not rest:
                    raise
                response = await self._restart(request_data, rest.pop(0), rest, user_api_key_dict)

    async def _restart(self, data, model, rest, user_api_key_dict):
        """The same request on the next candidate, by the route it came in on."""
        from litellm.proxy.proxy_server import llm_router
        from litellm.proxy.route_llm_request import route_request
        url = (data.get("proxy_server_request") or {}).get("url") or ""
        route = "anthropic_messages" if "/messages" in url else "acompletion"
        call = await route_request(data={**data, "model": model, "fallbacks": rest}, route_type=route,
                                   llm_router=llm_router, user_model=None, user_api_key_dict=user_api_key_dict)
        return await call

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
            if rec["state"] == "context" and window_of(err):
                rec["window"] = window_of(err)
        try:
            with open(RECORD, "a") as f:
                f.write(json.dumps(rec) + "\n")
        except Exception:
            pass
        if model and not model.startswith("auto"):  # a 503 from the walk itself parks nothing
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
        S = {"b": {"state": "no-credit", "since": 1, "until": time.time() - 60}}
        assert rank(M, S, "code", "free", set()) == ["a"]              # lapsed is still parked until a probe clears it
        assert unlock_at('429 {"headers":{"X-RateLimit-Reset":"1788566400000"}}', 1788566000) == 1788566400.0
        assert unlock_at("Rate limited. Please try again in 30 seconds", 100) == 160  # never sooner than a minute
        assert unlock_at("retry after 2 minutes", 100) == 220 and unlock_at("Insufficient credits", 100) is None
        mark("c", "429 X-RateLimit-Reset: 1788566400000 free-models-per-day", now=1788566000.0)
        assert _json(STATUS, {})["c"]["until"] == 1788566400.0
        M2 = {"s": {"tier": "free", "caps": {}, "context": 8000, "jobs": {"text": 0.9}},
              "l": {"tier": "free", "caps": {}, "context": 200000, "jobs": {"text": 0.5}},
              "u": {"tier": "free", "caps": {}, "context": None, "jobs": {"text": 0.4}}}
        assert rank(M2, {}, "x", None, set(), tokens=20000) == ["l"]       # too small a window is out, and so is an unknown one
        assert rank(M2, {}, "x", None, set(), tokens=5000) == ["s", "l"]
        assert rank(M2, {}, "x", None, set(), tokens=5000, out=4000) == ["l"]  # the answer it asks for counts
        assert est_tokens({"messages": [{"role": "user", "content": "x" * 3500}]}) >= 1000
        shot = {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": "A" * 5_000_000}}
        nested = {"messages": [{"role": "user", "content": [{"type": "tool_result", "content": [shot]}]}]}
        assert needs(nested) == {"image"}                                # a screenshot inside a tool_result is still an image
        assert est_tokens(nested) < 2000                                 # and weighs a picture, not its base64
        assert est_tokens({"messages": [{"role": "user", "content": [{"type": "image_url", "image_url": {"url": "data:image/png;base64," + "A" * 500000}}]}]}) < 2000
        assert fix_of("Insufficient credits. Add more using https://openrouter.ai/settings/credits\",\"code\":402") == "add credits: https://openrouter.ai/settings/credits"
        assert fix_of("This model collects data ... requires explicit opt in: https://opencode.ai/workspace/w/go") == "opt in: https://opencode.ai/workspace/w/go"
        assert fix_of("The requested model 'x' is not supported by any provider you have enabled") == "enable a provider for it"
        assert fix_of("Provider returned error") is None
        mark("f", "Insufficient credits. Add more using https://openrouter.ai/settings/credits", now=1.0)
        assert _json(STATUS, {})["f"]["fix"].startswith("add credits")
        mark("g", "boom", now=2.0)
        assert "f" in _json(STATUS, {})                                  # a lapsed park is not dropped by another mark
        clear("f"); clear("g")
        assert classify("This model's maximum context length is 32768 tokens") == "context"
        assert window_of("This model's maximum context length is 131072 tokens. However") == 131072
        assert window_of("Insufficient credits") is None
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
        asyncio.run(router.async_log_failure_event({"model": "x", "exception": "maximum context length is 32768 tokens",
                    "litellm_params": {"metadata": {"model_group": "b", "router_task": "t"}}}, None, now, now))
        assert json.loads(open(RECORD).readlines()[-1])["window"] == 32768  # the refusal's own number, for sync
        asyncio.run(router.async_log_success_event({"model": "x", "litellm_params": {"metadata": {"model_group": "a"}},
                    "user": "task:t", "messages": [{"role": "user", "content": "x" * 3500}]}, None, now, now))
        assert "a" not in _json(STATUS, {})
        last = json.loads(open(RECORD).readlines()[-1])
        assert last["task"] == "t" and last["tokens"] >= 1000  # the record sizes the request, not {}

        async def stream(*events, fail_at=None):
            for i, ev in enumerate(events):
                if i == fail_at:
                    raise RuntimeError("Provider returned error")
                yield ev
        tried = []
        async def restart(data, model, rest, key):
            tried.append(model)
            return stream("dead", fail_at=0) if model == "b" else stream("m1", "m2")
        router._restart = restart
        async def drain(resp, data):
            return [c async for c in router.async_post_call_streaming_iterator_hook(None, resp, data)]
        req = {"model": "a", "fallbacks": ["b", "c", "d"]}
        assert asyncio.run(drain(stream("x", fail_at=0), req)) == ["m1", "m2"] and tried == ["b", "c"]  # a dead first byte walks
        assert asyncio.run(drain(stream("m0", "m1"), req)) == ["m0", "m1"]                             # a good stream is untouched
        try:
            asyncio.run(drain(stream("m0", "m1", fail_at=1), req)); assert False
        except RuntimeError:
            pass                                                                                       # sent already: the error goes through
        try:
            asyncio.run(drain(stream("x", fail_at=0), {"model": "a"})); assert False
        except RuntimeError:
            pass                                                                                       # nothing left to walk
    print("ok")
