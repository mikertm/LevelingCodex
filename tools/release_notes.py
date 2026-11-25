"""Write the release notes CurseForge shows for one version.

    python tools/release_notes.py v0.20.0 > RELEASE_NOTES.md          (Markdown, what the release uploads)
    python tools/release_notes.py --html v0.20.0 > RELEASE_NOTES.html (the same notes as HTML)
    python tools/release_notes.py --check     (every version section converts cleanly)

Takes that version's section of CHANGELOG.md (from its "## v0.20.0" heading to the next "## ").
The release workflow runs it before the packager and fails when the changelog has no section for
the tag; only this version's notes are uploaded, never the whole changelog.

Markdown (the default) is the format CurseForge's author console edits in. Uploaded as HTML
(v0.20.1 to v0.23.0) the public page was fine, but the console's changelog editor turned the HTML
into Markdown and then showed that Markdown as plain text ("### Talents * **A talent path...**"
on one line, every mark escaped), and saving the file there kept the mess. The Markdown written
here is normalised so any Markdown reader agrees on it: "###" headings, "-" bullets nested by four
spaces, each bullet and paragraph on one line (indented continuation lines joined), a blank line
between blocks, and "<" written as &lt; so text like "<dungeon>" never reads as an HTML tag.

The HTML (--html) has "###" headings, "-" bullets (nested by two spaces, with indented
continuation lines), paragraphs, **bold**, *italic*, `code` and [links](url); everything else
is escaped.
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHANGELOG = ROOT / "CHANGELOG.md"


def sections(text):
    """Version heading -> its lines, in file order."""
    out, current = {}, None
    for line in text.replace("\r\n", "\n").split("\n"):
        if line.startswith("## "):
            current = line[3:].strip()
            out[current] = []
        elif current is not None:
            out[current].append(line)
    return out


def inline(text):
    text = html.escape(text, quote=False)
    codes = []

    def keep(m):
        codes.append("<code>" + m.group(1) + "</code>")
        return "\0%d\0" % (len(codes) - 1)
    text = re.sub(r"`([^`]+)`", keep, text)
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", lambda m: '<a href="%s">%s</a>' % (html.escape(m.group(2)), m.group(1)), text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![*\w])\*(?=\S)(.+?)(?<=\S)\*(?![*\w])", r"<em>\1</em>", text)
    return re.sub(r"\0(\d+)\0", lambda m: codes[int(m.group(1))], text)


def convert(lines):
    out = []
    depth = 0          # open <ul> levels
    item_open = False  # an <li> waiting for its </li>
    para = []

    def flush_para():
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
            para.clear()

    def close_lists(to):
        nonlocal depth, item_open
        while depth > to:
            if item_open:
                out.append("</li>")
            out.append("</ul>")
            depth -= 1
            item_open = depth > 0

    for raw in lines:
        line = raw.rstrip()
        bullet = re.match(r"^( *)[-*] +(.*)$", line)
        if not line.strip():
            flush_para()
            continue
        if line.startswith("#"):
            flush_para()
            close_lists(0)
            level = min(6, len(line) - len(line.lstrip("#")))
            out.append("<h%d>%s</h%d>" % (level, inline(line.lstrip("#").strip()), level))
        elif bullet:
            flush_para()
            want = len(bullet.group(1)) // 4  # the changelog nests by four spaces + 1
            if want > depth:
                while depth < want:
                    out.append("<ul>")
                    depth += 1
                    item_open = False
            else:
                close_lists(want)
                if item_open:
                    out.append("</li>")
            out.append("<li>" + inline(bullet.group(2)))
            item_open = True
        elif depth and line.startswith(" "):
            out[-1] += " " + inline(line.strip())  # a bullet's continuation line
        else:
            close_lists(0)
            para.append(line.strip())
    flush_para()
    close_lists(0)
    return "\n".join(out) + "\n"


def markdown(lines):
    """The section as normalised Markdown (see the module notes)."""
    blocks = []   # each a list of lines; blocks are joined by a blank line
    para = []
    items = None  # the open list's lines
    depth = 0     # the last bullet's nesting (0 = top level)

    def flush_para():
        if para:
            blocks.append([" ".join(para).replace("<", "&lt;")])
            para.clear()

    def close_list():
        nonlocal items, depth
        if items:
            blocks.append(items)
        items, depth = None, 0

    for raw in lines:
        line = raw.rstrip()
        bullet = re.match(r"^( *)[-*] +(.*)$", line)
        if not line.strip():
            flush_para()
            continue
        if line.startswith("#"):
            flush_para()
            close_list()
            level = min(6, len(line) - len(line.lstrip("#")))
            blocks.append(["#" * level + " " + line.lstrip("#").strip().replace("<", "&lt;")])
        elif bullet:
            flush_para()
            want = len(bullet.group(1)) // 4  # the changelog nests by four spaces
            depth = 0 if items is None else min(want, depth + 1)
            if items is None:
                items = []
            items.append("    " * depth + "- " + bullet.group(2).strip().replace("<", "&lt;"))
        elif items is not None and line.startswith(" "):
            items[-1] += " " + line.strip().replace("<", "&lt;")  # a bullet's continuation line
        else:
            close_list()
            para.append(line.strip())
    flush_para()
    close_list()
    return "\n\n".join("\n".join(b) for b in blocks) + "\n"


def notes(version, html_out=False):
    found = sections(CHANGELOG.read_text(encoding="utf-8"))
    if version not in found:
        raise SystemExit("CHANGELOG.md has no '## %s' section: add the release notes before tagging." % version)
    return convert(found[version]) if html_out else markdown(found[version])


def check():
    """Every version section converts: the HTML with no Markdown left over, the Markdown normalised."""
    problems = []
    for version, lines in sections(CHANGELOG.read_text(encoding="utf-8")).items():
        text = convert(lines)
        visible = re.sub(r"<[^>]+>", "", text)
        for mark in ("**", "`", "](", "\n#"):
            if mark in visible:
                problems.append("%s: '%s' left in the notes" % (version, mark.strip()))
        if "<li>" not in text and "<p>" not in text:
            problems.append("%s: no notes" % version)
        md = markdown(lines)
        if "<" in md:
            problems.append("%s: a raw '<' in the Markdown notes" % version)
        for line in md.split("\n"):
            indent = len(line) - len(line.lstrip(" "))
            if indent % 4 or (indent and not line.lstrip().startswith("- ")):
                problems.append("%s: Markdown line indented by %d: %s" % (version, indent, line.strip()[:40]))
        if not md.strip():
            problems.append("%s: no Markdown notes" % version)
    return problems


def main():
    args = sys.argv[1:]
    if args == ["--check"]:
        problems = check()
        for p in problems:
            print(p)
        return 1 if problems else 0
    html_out = bool(args) and args[0] == "--html"
    if html_out:
        args = args[1:]
    if len(args) != 1:
        raise SystemExit(__doc__)
    sys.stdout.write(notes(args[0], html_out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
