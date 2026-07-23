# §head docs/build.py:211-251 _render_list
# §sig def _render_list(lines: list[str], i_holder: list[int]) -> str:
"""Render a (possibly nested) list starting at lines[i_holder[0]]."""
    i = i_holder[0]
    n = len(lines)
    base_indent = len(re.match(r"^(\s*)", lines[i]).group(1))
    ordered = bool(re.match(r"^\s*\d+[.)]\s", lines[i]))
    tag = "ol" if ordered else "ul"
    items: list[str] = []
    cur: list[str] | None = None

    while i < n:
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        indent = len(re.match(r"^(\s*)", line).group(1))
        m = re.match(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$", line)
        if m and indent == base_indent:
            if cur is not None:
                items.append(cur_text(cur))
            cur = [m.group(3)]
            i += 1
        elif m and indent > base_indent:
            # nested list
            sub = _render_list(lines, sub_holder := [i])
            i = sub_holder[0]
            if cur is None:
                cur = [""]
            cur.append("\x01" + sub)  # marker for raw html
        elif not m and indent > base_indent and cur is not None:
            # continuation line
            cur.append(line.strip())
            i += 1
        else:
            break

    if cur is not None:
        items.append(cur_text(cur))

    i_holder[0] = i
    return f"<{tag}>" + "".join(f"<li>{it}</li>" for it in items) + f"</{tag}>"
# §foot docs/build.py _render_list