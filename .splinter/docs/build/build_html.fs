# §head docs/build.py:316-326 build_html
# §sig def build_html(docs: list[dict]) -> str:
data = json.dumps(docs, ensure_ascii=False, separators=(",", ":"))
    n = len(docs)
    cats = len({d["category"] for d in docs})
    template = TEMPLATE
    template = template.replace("/*__DOC_COUNT__*/", str(n))
    template = template.replace("/*__CAT_COUNT__*/", str(cats))
    # __DATA__ is placed inside a script block; </script> in data is escaped.
    safe_data = data.replace("</", "<\\/")
    template = template.replace("/*__DATA__*/", safe_data)
    return template
# §foot docs/build.py build_html