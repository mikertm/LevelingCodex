"""Install the working copy into a WoW AddOns folder for in-game testing.

    python tools/install.py "C:\\Program Files (x86)\\World of Warcraft\\_forever_\\Interface\\AddOns"
    python tools/install.py            # uses LEVELINGCODEX_ADDONS, else the path above

Copies what the client loads (the files listed in LevelingCodex.toc, both .toc files and
Bindings.xml) into <AddOns>/LevelingCodex, removes .lua/.xml files left there by older builds
(they'd be stale code), leaves every other file alone, and checks each copy byte for byte.
The .toc copies get a real version in place of @project-version@ (the packager does that for
releases from the tag): `git describe`, e.g. v0.12.0-7-gabc1234, "-dirty" with uncommitted changes.
Then /reload in game (or restart the client if a .toc changed).
"""
import filecmp
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT = r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns"
TOKEN = b"@project-version@"
TOCS = ("LevelingCodex.toc", "LevelingCodex_Camelot.toc")


def version():
    try:
        out = subprocess.run(["git", "describe", "--tags", "--always", "--dirty"], cwd=ROOT,
                             capture_output=True, text=True, timeout=20)
        v = out.stdout.strip()
        if out.returncode == 0 and v:
            return v
    except (OSError, subprocess.SubprocessError):
        pass
    return "dev"


def source(f, ver):
    """The bytes to install for f: the file itself, or a .toc with the version filled in."""
    with open(os.path.join(ROOT, f), "rb") as fh:
        data = fh.read()
    return data.replace(TOKEN, ver.encode("ascii")) if f in TOCS else data


def payload():
    toc = open(os.path.join(ROOT, "LevelingCodex.toc"), encoding="utf-8").read().splitlines()
    files = ["LevelingCodex.toc", "LevelingCodex_Camelot.toc", "Bindings.xml", "media/quest-arrow.tga"]
    files += [l.strip() for l in toc if l.strip() and not l.startswith("#")]
    return files


def main():
    addons = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("LEVELINGCODEX_ADDONS", DEFAULT)
    if not os.path.isdir(addons):
        sys.exit("AddOns folder not found: " + addons)
    dest = os.path.join(addons, "LevelingCodex")
    os.makedirs(dest, exist_ok=True)
    files = payload()
    ver = version()
    for f in files:
        os.makedirs(os.path.dirname(os.path.join(dest, f)), exist_ok=True)
        if f in TOCS:
            with open(os.path.join(dest, f), "wb") as fh:
                fh.write(source(f, ver))
            shutil.copystat(os.path.join(ROOT, f), os.path.join(dest, f))
        else:
            shutil.copy2(os.path.join(ROOT, f), os.path.join(dest, f))
    removed, kept = [], []
    for f in sorted(os.listdir(dest)):
        if f in files:
            continue
        if f.lower().endswith((".lua", ".xml")):
            os.remove(os.path.join(dest, f))
            removed.append(f)
        else:
            kept.append(f)
    def same(f):
        if f not in TOCS:
            return filecmp.cmp(os.path.join(ROOT, f), os.path.join(dest, f), shallow=False)
        with open(os.path.join(dest, f), "rb") as fh:
            return fh.read() == source(f, ver)
    bad = [f for f in files if not same(f)]
    print("installed %d files into %s (version %s)" % (len(files), dest, ver))
    if removed:
        print("removed stale code from older builds: " + ", ".join(removed))
    if kept:
        print("left alone (not ours to manage): " + ", ".join(kept))
    if bad:
        sys.exit("copy check FAILED for: " + ", ".join(bad))
    print("all copies verified - /reload in game (restart the client if a .toc changed)")


if __name__ == "__main__":
    main()
