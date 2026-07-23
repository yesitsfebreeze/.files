# §head docs/build.py:273-310 collect
# §sig def collect() -> list[dict]:
seen: set[Path] = set()
    docs: list[dict] = []
    for glob, category, _weight in SOURCES:
        for path in sorted(REPO_ROOT.glob(glob)):
            if not path.is_file() or path.suffix != ".md":
                continue
            rp = path.resolve()
            if rp in seen:
                continue
            seen.add(rp)
            rel = path.relative_to(REPO_ROOT).as_posix()
            raw = path.read_text(encoding="utf-8", errors="replace")
            meta, body = split_frontmatter(raw)
            # Title: frontmatter name -> first H1 -> filename
            title = meta.get("name")
            if not title:
                h1 = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
                title = h1.group(1).strip() if h1 else path.stem
            desc = meta.get("description", "")
            body_html = render_markdown(body)
            # Plaintext for search index
            plain = re.sub(r"<[^>]+>", " ", body_html)
            plain = html.unescape(plain)
            plain = re.sub(r"\s+", " ", plain).strip()
            docs.append({
                "id": rel,
                "title": title,
                "category": category,
                "path": rel,
                "desc": desc,
                "html": body_html,
                "text": plain[:8000],
            })
    # Stable sort: category order, then path
    cat_idx = {c: n for n, c in enumerate(CATEGORY_ORDER)}
    docs.sort(key=lambda d: (cat_idx.get(d["category"], 99), d["path"]))
    return docs
# §foot docs/build.py collect