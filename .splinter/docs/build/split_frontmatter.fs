# §head docs/build.py:51-64 split_frontmatter
# §sig def split_frontmatter(text: str) -> tuple[dict, str]:
"""Return (frontmatter_dict, body). Handles simple `key: value` YAML."""
    meta: dict[str, str] = {}
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            block = text[3:end].strip("\n")
            body = text[end + 4:].lstrip("\n")
            for line in block.splitlines():
                if ":" in line and not line.lstrip().startswith("#"):
                    k, _, v = line.partition(":")
                    meta[k.strip()] = v.strip().strip("\"'")
            return meta, body
    return meta, text
# §foot docs/build.py split_frontmatter