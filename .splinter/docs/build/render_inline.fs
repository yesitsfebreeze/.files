# §head docs/build.py:86-103 render_inline
# §sig def render_inline(text: str) -> str: # Protect code spans first by extracting them.
spans: list[str] = []

    def stash(m: re.Match) -> str:
        spans.append(f"<code>{html.escape(m.group(1))}</code>")
        return f"\x00{len(spans) - 1}\x00"

    text = _INLINE_CODE.sub(stash, text)
    text = html.escape(text, quote=False)
    text = _IMAGE.sub(lambda m: f'<img alt="{html.escape(m.group(1))}" src="{html.escape(m.group(2))}">', text)
    text = _LINK.sub(lambda m: f'<a href="{html.escape(m.group(2))}">{m.group(1)}</a>', text)
    text = _AUTOLINK.sub(lambda m: f'<a href="{html.escape(m.group(1))}">{html.escape(m.group(1))}</a>', text)
    text = _BOLD.sub(lambda m: f"<strong>{m.group(1) or m.group(2)}</strong>", text)
    text = _ITALIC.sub(lambda m: f"<em>{m.group(1) or m.group(2)}</em>", text)
    # Restore code spans.
    text = re.sub(r"\x00(\d+)\x00", lambda m: spans[int(m.group(1))], text)
    return text
# §foot docs/build.py render_inline