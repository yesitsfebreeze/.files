# §head docs/build.py:106-208 render_markdown
# §sig def render_markdown(md: str) -> str:
lines = md.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    i = 0
    n = len(lines)

    def flush_para(buf: list[str]) -> None:
        if buf:
            out.append("<p>" + render_inline(" ".join(b.strip() for b in buf)) + "</p>")
            buf.clear()

    para: list[str] = []

    while i < n:
        line = lines[i]
        stripped = line.strip()

        # Fenced code block
        fence = re.match(r"^(```|~~~)(.*)$", stripped)
        if fence:
            flush_para(para)
            lang = fence.group(2).strip()
            i += 1
            code: list[str] = []
            while i < n and not lines[i].strip().startswith(fence.group(1)):
                code.append(lines[i])
                i += 1
            i += 1  # skip closing fence
            cls = f' class="language-{html.escape(lang)}"' if lang else ""
            out.append(f"<pre><code{cls}>" + html.escape("\n".join(code)) + "</code></pre>")
            continue

        # Heading
        h = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if h:
            flush_para(para)
            level = len(h.group(1))
            content = h.group(2).strip().rstrip("#").strip()
            hid = _slug(content)
            out.append(f'<h{level} id="{hid}">{render_inline(content)}</h{level}>')
            i += 1
            continue

        # Horizontal rule
        if re.match(r"^(\*\s*){3,}$|^(-\s*){3,}$|^(_\s*){3,}$", stripped):
            flush_para(para)
            out.append("<hr>")
            i += 1
            continue

        # Table (GFM): header row then a |---|---| separator
        if "|" in line and i + 1 < n and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[i + 1]) and "-" in lines[i + 1]:
            flush_para(para)
            def cells(row: str) -> list[str]:
                row = row.strip()
                if row.startswith("|"):
                    row = row[1:]
                if row.endswith("|"):
                    row = row[:-1]
                return [c.strip() for c in row.split("|")]
            header = cells(line)
            i += 2
            body_rows = []
            while i < n and "|" in lines[i] and lines[i].strip():
                body_rows.append(cells(lines[i]))
                i += 1
            thead = "".join(f"<th>{render_inline(c)}</th>" for c in header)
            tbody = "".join(
                "<tr>" + "".join(f"<td>{render_inline(c)}</td>" for c in r) + "</tr>"
                for r in body_rows
            )
            out.append(f"<table><thead><tr>{thead}</tr></thead><tbody>{tbody}</tbody></table>")
            continue

        # Blockquote
        if stripped.startswith(">"):
            flush_para(para)
            quote: list[str] = []
            while i < n and lines[i].strip().startswith(">"):
                quote.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            out.append("<blockquote>" + render_markdown("\n".join(quote)) + "</blockquote>")
            continue

        # Lists (unordered / ordered), supports one level of nesting by indent
        list_m = re.match(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$", line)
        if list_m:
            flush_para(para)
            out.append(_render_list(lines, i_holder := [i]))
            i = i_holder[0]
            continue

        # Blank line ends a paragraph
        if not stripped:
            flush_para(para)
            i += 1
            continue

        para.append(line)
        i += 1

    flush_para(para)
    return "\n".join(out)
# §foot docs/build.py render_markdown