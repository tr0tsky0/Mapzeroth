"""Shared by the Modern generators (gen_modern_nodes.py, gen_modern_edges.py, gen_modern_abilities.py), which
each write part of Data/Modern/CONVERSION_NOTES.md: the node generator the top of it, the other two a section
each. Every one of them replaces only what it owns and leaves the rest alone, so running one generator by
itself never loses another's notes.

Layout of the file: the node generator's notes, then the edge section, then the ability section. A section
runs from its "## " heading to the next "## " heading (or the end of the file).
"""

# The sections the other generators own, in the order they appear. The node generator's own text is everything
# above the first of them.
SECTIONS = [
    "## Edge conversion (tools/gen_modern_edges.py)",
    "## Ability conversion (tools/gen_modern_abilities.py)",
]


def _split(text):
    """(head, {heading: body}) where head is the node generator's text and body includes its heading line."""
    positions = sorted((text.index(h), h) for h in SECTIONS if h in text)
    if not positions:
        return text, {}
    head = text[:positions[0][0]]
    sections = {}
    for i, (start, heading) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        sections[heading] = text[start:end]
    return head, sections


def _join(head, sections):
    parts = [head.rstrip("\n") + "\n"]
    for heading in SECTIONS:          # always in the file's fixed order
        if heading in sections:
            parts.append("\n" + sections[heading].strip("\n") + "\n")
    return "".join(parts)


def write_head(path, head_text):
    """The node generator's notes: replaces the top of the file, keeps the other generators' sections."""
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    _, sections = _split(existing)
    path.write_text(_join(head_text, sections), encoding="utf-8")


def write_section(path, heading, body_lines):
    """An edge/ability generator's notes: replaces its own section, keeps everything else."""
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    head, sections = _split(existing)
    sections[heading] = "\n".join(body_lines)
    path.write_text(_join(head, sections), encoding="utf-8")
