"""tools/package_forever.py -- builds the Forever-only release zip of the rebuild, as the addon "Mapzeroth".

    python tools/package_forever.py [--version 2.0.0-beta.1] [--out dist]

The zip holds one folder, Mapzeroth/, with Mapzeroth.toc and exactly the files the development .toc
(Mapzeroth-Rebuild.toc) lists for Forever -- nothing else can get in (no tests, tools, docs, Modern data). The .toc is
rewritten for the release:

- `## Interface: 16001` only (Forever), so CurseForge files it under Forever and retail never offers it;
- `## Title: Mapzeroth`, the development notes and comments dropped, `## Version` set (--version, else the dev .toc's);
- every `Data\\Modern\\` line dropped (those files would skip themselves on Forever anyway, see Constants.lua's
  addon.RULESET, but they don't need to ship).

`## SavedVariables` is kept as the dev .toc has it: MapzerothRebuildDB, decided 2026-09-24 for the releases and the
joint version alike (the old addon's MapzerothDB holds little worth carrying over, so players start fresh). It holds
settings, found flight points and hearth binds: renaming it would wipe them.

Checks before writing: every listed file exists, none is under Data/Modern, and each Forever data file starts with its
guard. The zip goes to dist/ (ignored by git) as Mapzeroth-<version>-forever.zip.
"""
import argparse
import pathlib
import re
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEV_TOC = ROOT / "Mapzeroth-Rebuild.toc"
NAME = "Mapzeroth"
INTERFACE = "16001"
NOTES = "Plans the quickest way anywhere in WoW Forever: flights, boats, portals, hearthstones and your own spells."
GUARD = 'if addon.RULESET ~= "forever" then return end'


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--version", help="the release version (default: the dev .toc's ## Version)")
    parser.add_argument("--out", default=str(ROOT / "dist"), help="where the zip goes (default: dist/)")
    args = parser.parse_args()

    header, files = {}, []
    for line in DEV_TOC.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("## "):
            key, _, value = line[3:].partition(":")
            header[key.strip()] = value.strip()
        elif line and not line.startswith("#"):
            files.append(line)

    version = args.version or header.get("Version", "0.0.0")
    shipped = [f for f in files if not f.startswith("Data\\Modern\\")]

    problems = []
    for f in shipped:
        path = ROOT / f.replace("\\", "/")
        if not path.is_file():
            problems.append(f"listed but missing: {f}")
        elif f.startswith("Data\\Forever\\") and GUARD not in path.read_text(encoding="utf-8"):
            problems.append(f"Forever data file without its guard: {f}")
    if any(f.startswith("Data\\Modern\\") for f in shipped):
        problems.append("a Data\\Modern file would ship")
    if problems:
        sys.exit("not packaged:\n  " + "\n  ".join(problems))

    toc = [
        f"## Interface: {INTERFACE}",
        f"## Title: {NAME}",
        f"## Notes: {NOTES}",
        f"## Author: {header.get('Author', '')}",
        f"## Version: {version}",
    ]
    for key in ("SavedVariables", "SavedVariablesPerCharacter", "OptionalDeps", "Dependencies", "IconTexture"):
        if key in header:
            toc.append(f"## {key}: {header[key]}")
    toc.append("")
    toc += shipped

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"{NAME}-{version}-forever.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(f"{NAME}/{NAME}.toc", "\r\n".join(toc) + "\r\n")
        for f in shipped:
            z.write(ROOT / f.replace("\\", "/"), f"{NAME}/{f.replace(chr(92), '/')}")

    size = zip_path.stat().st_size
    print(f"wrote {zip_path} ({len(shipped) + 1} files, {size / 1024:.0f} KB): {NAME} {version}, Interface {INTERFACE}")


if __name__ == "__main__":
    main()
