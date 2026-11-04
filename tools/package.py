"""tools/package.py -- builds a one-game release zip of the rebuild, as the addon "Mapzeroth".

    python tools/package.py --ruleset forever|modern [--version 2.0.0] [--out dist]

The zip holds one folder, Mapzeroth/, with Mapzeroth.toc and exactly the files the development .toc
(Mapzeroth-Dev.toc) lists for that game -- nothing else can get in (no tests, tools, docs, the other game's data).
The .toc is rewritten for the release:

- `## Interface:` that game's only (Forever 16001, Modern 120105), so CurseForge files it under the one flavour;
- `## Title: Mapzeroth`, the development notes and comments dropped, `## Version` set (--version, else the dev .toc's);
- every line of the other game's `Data\\<Ruleset>\\` folder dropped (those files would skip themselves anyway, see
  Constants.lua's addon.RULESET, but they don't need to ship).

`## SavedVariables` is kept as the dev .toc has it: MapzerothRebuildDB, decided 2026-09-24 for every release (the old
addon's MapzerothDB holds little worth carrying over, so players start fresh). It holds settings, found flight points
and hearth binds: renaming it would wipe them.

Checks before writing: every listed file exists, none is the other game's data, and each of this game's data files
starts with its guard. The zip goes to dist/ (ignored by git) as Mapzeroth-<version>-<ruleset>.zip.
"""
import argparse
import pathlib
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEV_TOC = ROOT / "Mapzeroth-Dev.toc"
NAME = "Mapzeroth"
RULESETS = {
    "forever": {
        "folder": "Forever",
        "interface": "16001",
        "notes": "Plans the quickest way anywhere in WoW Forever: flights, boats, portals, hearthstones and your own spells.",
    },
    "modern": {
        "folder": "Modern",
        "interface": "120105",
        "notes": "Plans the quickest way anywhere in Azeroth: portals, flying, hearthstones, toys and your own spells.",
    },
}
ASSETS = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / "Media").glob("*.tga"))            # shipped as they are: pictures the Lua names, which the .toc does not list


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--ruleset", required=True, choices=sorted(RULESETS), help="which game the zip is for")
    parser.add_argument("--version", help="the release version (default: the dev .toc's ## Version)")
    parser.add_argument("--out", default=str(ROOT / "dist"), help="where the zip goes (default: dist/)")
    args = parser.parse_args()

    rules = RULESETS[args.ruleset]
    own = f"Data\\{rules['folder']}\\"
    others = [f"Data\\{r['folder']}\\" for k, r in RULESETS.items() if k != args.ruleset]
    guard = f'if addon.RULESET ~= "{args.ruleset}" then return end'

    header, files = {}, []
    for line in DEV_TOC.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("## "):
            key, _, value = line[3:].partition(":")
            header[key.strip()] = value.strip()
        elif line and not line.startswith("#"):
            files.append(line)

    version = args.version or header.get("Version", "0.0.0")
    shipped = [f for f in files if not any(f.startswith(o) for o in others)]

    problems = []
    for f in shipped:
        path = ROOT / f.replace("\\", "/")
        if not path.is_file():
            problems.append(f"listed but missing: {f}")
        elif f.startswith(own) and guard not in path.read_text(encoding="utf-8"):
            problems.append(f"{rules['folder']} data file without its guard: {f}")
    problems += [f"asset missing: {a}" for a in ASSETS if not (ROOT / a).is_file()]
    if not any(f.startswith(own) for f in shipped):
        problems.append(f"no {own} files listed")
    if problems:
        sys.exit("not packaged:\n  " + "\n  ".join(problems))

    toc = [
        f"## Interface: {rules['interface']}",
        f"## Title: {NAME}",
        f"## Notes: {rules['notes']}",
        f"## Author: {header.get('Author', '')}",
        f"## Version: {version}",
        f"## IconTexture: Interface\\AddOns\\{NAME}\\Media\\Logo",                   # the release folder's name, not the dev .toc's
    ]
    for key in ("Category", "SavedVariables", "SavedVariablesPerCharacter", "OptionalDeps", "Dependencies"):
        if key in header:
            toc.append(f"## {key}: {header[key]}")
    toc.append("")
    toc += shipped

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"{NAME}-{version}-{args.ruleset}.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(f"{NAME}/{NAME}.toc", "\r\n".join(toc) + "\r\n")
        for f in shipped:
            z.write(ROOT / f.replace("\\", "/"), f"{NAME}/{f.replace(chr(92), '/')}")
        for a in ASSETS:
            z.write(ROOT / a, f"{NAME}/{a}")

    size = zip_path.stat().st_size
    print(f"wrote {zip_path} ({len(shipped) + 1 + len(ASSETS)} files, {size / 1024:.0f} KB): {NAME} {version}, Interface {rules['interface']}")


if __name__ == "__main__":
    main()
