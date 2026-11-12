"""Write the release notes CurseForge shows for one version, as HTML.

    python tools/release_notes.py v0.20.0 > RELEASE_NOTES.html
    python tools/release_notes.py --check     (every version section converts cleanly)

Takes that version's section of CHANGELOG.md (from its "## v0.20.0" heading to the next "## ")
and converts its Markdown to HTML: "###" headings, "-" bullets (nested by two spaces, with
indented continuation lines), paragraphs, **bold**, *italic*, `code` and [links](url). Everything
else is escaped, so text like "<dungeon>" stays visible. The release workflow runs it before
the packager and fails when the changelog has no section for the tag. Uploading only this
version's notes as HTML keeps CurseForge from showing the whole changelog as one run-on block.
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
            want = len(bullet.group(1)) // 2 + 1
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


def notes(version):
    found = sections(CHANGELOG.read_text(encoding="utf-8"))
    if version not in found:
        raise SystemExit("CHANGELOG.md has no '## %s' section: add the release notes before tagging." % version)
    return convert(found[version])


def check():
    """Every version section converts with no Markdown left over."""
    problems = []
    for version, lines in sections(CHANGELOG.read_text(encoding="utf-8")).items():
        text = convert(lines)
        visible = re.sub(r"<[^>]+>", "", text)
        for mark in ("**", "`", "](", "\n#"):
            if mark in visible:
                problems.append("%s: '%s' left in the notes" % (version, mark.strip()))
        if "<li>" not in text and "<p>" not in text:
            problems.append("%s: no notes" % version)
    return problems


def main():
    if sys.argv[1:] == ["--check"]:
        problems = check()
        for p in problems:
            print(p)
        return 1 if problems else 0
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    sys.stdout.write(notes(sys.argv[1]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
