#!/usr/bin/env python3
import sys, os, subprocess, time
from urllib.parse import quote


def _root():
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return os.getcwd()


_r = _root()
LOG   = os.environ.get("VOIT_JD_USAGE_LOG") or os.path.join(_r, ".voit", "jd-usage.log")
CACHE = os.environ.get("VOIT_JD_CACHE_DIR") or os.path.join(_r, ".voit", "jd-cache")
N     = int(os.environ.get("VOIT_JD_CACHE_N") or 8)


def _slug(ref):
    return quote(ref, safe='')


def cmd_log(args):
    if len(args) < 2:
        sys.exit("usage: jd-cache.py log <verb> <target>")
    verb, target = args[0], args[1]
    log_dir = os.path.dirname(LOG)
    if log_dir:
        os.makedirs(log_dir, exist_ok=True)
    try:
        with open(LOG, "a") as f:
            f.write("%d\t%s\t%s\n" % (int(time.time()), verb, target))
    except Exception:
        pass


def cmd_populate(_args):
    stamp = os.path.join(CACHE, ".stamp")
    try:
        log_mtime = os.path.getmtime(LOG)
    except OSError:
        return
    try:
        if log_mtime <= os.path.getmtime(stamp):
            return
    except OSError:
        pass

    counts = {}
    try:
        with open(LOG) as f:
            for line in f:
                parts = line.rstrip("\n").split("\t", 2)
                if len(parts) < 3:
                    continue
                target = parts[2]
                if target.startswith("?"):
                    continue
                counts[target] = counts.get(target, 0) + 1
    except OSError:
        return

    ranked = sorted(counts.items(), key=lambda x: (-x[1], x[0]))
    top = [ref for ref, _ in ranked[:N]]
    top_slugs = set(_slug(ref) for ref in top)

    os.makedirs(CACHE, exist_ok=True)

    for ref in top:
        slug = _slug(ref)
        path = os.path.join(CACHE, slug + ".jd")
        try:
            r = subprocess.run(["jd", "get", ref], capture_output=True, text=True,
                               timeout=10)
            if r.returncode != 0 or not r.stdout.strip():
                continue
        except Exception:
            continue
        with open(path, "w") as f:
            f.write(r.stdout)

    try:
        for fname in os.listdir(CACHE):
            if fname.endswith(".jd") and fname[:-3] not in top_slugs:
                try:
                    os.unlink(os.path.join(CACHE, fname))
                except OSError:
                    pass
    except OSError:
        pass

    try:
        open(stamp, "w").close()
    except Exception:
        pass


def cmd_stat(_args):
    try:
        files = [f for f in os.listdir(CACHE) if f.endswith(".jd")]
    except OSError:
        return
    if not files:
        return
    total = sum(os.path.getsize(os.path.join(CACHE, f)) for f in files)
    print("%djd %.1fkb" % (len(files), total / 1024))


CMDS = {"log": cmd_log, "populate": cmd_populate, "stat": cmd_stat}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS:
        print("usage: jd-cache.py log|populate|stat", file=sys.stderr)
        sys.exit(2)
    CMDS[sys.argv[1]](sys.argv[2:])


if __name__ == "__main__":
    main()
