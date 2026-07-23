# §head docs/build.py:254-267 cur_text
# §sig def cur_text(parts: list[str]) -> str:
html_parts: list[str] = []
    text_buf: list[str] = []
    for p in parts:
        if p.startswith("\x01"):
            if text_buf:
                html_parts.append(render_inline(" ".join(t for t in text_buf if t).strip()))
                text_buf = []
            html_parts.append(p[1:])
        else:
            text_buf.append(p)
    if text_buf:
        html_parts.append(render_inline(" ".join(t for t in text_buf if t).strip()))
    return "".join(html_parts)
# §foot docs/build.py cur_text