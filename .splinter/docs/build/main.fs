# §head docs/build.py:547-560 main
# §sig def main(argv: list[str]) -> int:
docs = collect()
    if "--check" in argv:
        print(f"[check] {len(docs)} docs, {len({d['category'] for d in docs})} categories")
        for d in docs:
            print(f"  {d['category']:>14} | {d['path']}")
        return 0
    out_html = build_html(docs)
    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(out_html, encoding="utf-8")
    size_kb = len(out_html.encode("utf-8")) / 1024
    print(f"Built {OUT_FILE.relative_to(REPO_ROOT).as_posix()} "
          f"({len(docs)} docs, {len({d['category'] for d in docs})} sections, {size_kb:.0f} KB)")
    return 0
# §foot docs/build.py main