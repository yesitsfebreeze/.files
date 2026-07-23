# §head docs/build.py:82-83 _slug
# §sig def _slug(text: str) -> str:
return _HEADING_ID.sub("-", text.strip().lower()).strip("-")
# §foot docs/build.py _slug