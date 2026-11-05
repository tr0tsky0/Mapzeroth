"""tools/package.py -- builds the release zip of the rebuild, as the addon "Mapzeroth", for both games at once.

    python tools/package.py --forever 1.0.0 --modern 2.0.6 [--out dist]

The zip holds one folder, Mapzeroth/, with two .toc files, one per game, each listing only its own game's files:

- Mapzeroth_Forever.toc: `## Interface: 16001`, Forever's data (the WoW: Forever client loads `_Forever` and
  ignores `_Mainline`, checked at launch 2026-11-04);
- Mapzeroth_Mainline.toc: `## Interface: 120105`, Modern's data (Retail).

Both are made from the development .toc (Mapzeroth-Dev.toc): `## Title: Mapzeroth`, that game's notes and version,
the development comments dropped, and every line of the other game's `Data\\<Ruleset>\\` folder dropped. The zip's
files are the union of the two lists plus Media/*.tga; nothing else gets in (no tests, tools, docs).

`## SavedVariables` is kept as the dev .toc has it: MapzerothRebuildDB, decided 2026-09-24 for every release (the old
addon's MapzerothDB holds little worth carrying over, so players start fresh). It holds settings, found flight points
and hearth binds: renaming it would wipe them.

Checks before writing: every listed file exists, neither .toc lists the other game's data, and each data file starts
with its guard (Constants.lua's addon.RULESET; redundant now that each .toc lists only its own data, kept until the
guards are retired). The zip goes to dist/ (ignored by git) as Mapzeroth-<modern>-forever-<forever>.zip.

Versions and tags: each game is tagged on its own, `forever-<version>` and `modern-<version>`, on the commit that was
packaged; a release tags only the games whose version went up. Before the 2026-11-04 dual package the tags were bare
versions, so LEGACY_TAGS names each game's last one. A game's version must go up whenever any file its .toc lists
(or Media/) differs from its last tag, shared engine files included; the packager refuses otherwise, and prints the
tags to make. Uncommitted changes to shipped files are refused too, so the tag matches what was packaged.
"""
import argparse
import pathlib
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEV_TOC = ROOT / "Mapzeroth-Dev.toc"
NAME = "Mapzeroth"
RULESETS = {
    "forever": {
        "folder": "Forever",
        "suffix": "Forever",
        "interface": "16001",
        "notes": "Plans the quickest way anywhere in WoW Forever: flights, boats, portals, hearthstones and your own spells.",
    },
    "modern": {
        "folder": "Modern",
        "suffix": "Mainline",
        "interface": "120105",
        "notes": "Plans the quickest way anywhere in Azeroth: portals, flying, hearthstones, toys and your own spells.",
    },
}
ASSETS = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / "Media").glob("*.tga"))            # shipped as they are: pictures the Lua names, which the .toc does not list
LEGACY_TAGS = {"forever": "0.8.2", "modern": "2.0.5"}                                               # each game's last release before per-game tags


def git(*args):
    return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True)


def last_tag(ruleset):
    """(tag, version) of this game's latest release."""
    tags = git("tag", "-l", f"{ruleset}-*", "--sort=-v:refname").stdout.split()
    if tags:
        return tags[0], tags[0][len(ruleset) + 1:]
    return LEGACY_TAGS[ruleset], LEGACY_TAGS[ruleset]


def check_version(ruleset, version, paths, problems):
    """Refuses a changed game whose version didn't go up; returns the tag to make, or None if the game is unchanged."""
    tag, last = last_tag(ruleset)
    changed = git("diff", "--name-only", tag, "HEAD", "--", *paths).stdout.split()
    if version == last:
        if changed:
            problems.append(f"{ruleset}: {len(changed)} shipped file(s) changed since {tag} but --{ruleset} is still {version}"
                            f" (e.g. {', '.join(changed[:3])})")
        return None
    if git("rev-parse", "-q", "--verify", f"refs/tags/{ruleset}-{version}").returncode == 0:
        problems.append(f"{ruleset}: tag {ruleset}-{version} already exists")
    if not changed:
        print(f"note: {ruleset} {version} has no shipped changes since {tag}")
    return f"{ruleset}-{version}"


def read_dev_toc():
    header, files = {}, []
    for line in DEV_TOC.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("## "):
            key, _, value = line[3:].partition(":")
            header[key.strip()] = value.strip()
        elif line and not line.startswith("#"):
            files.append(line)
    return header, files


def build_toc(ruleset, version, header, files, problems):
    """One game's .toc lines and the files it lists; problems found are appended to `problems`."""
    rules = RULESETS[ruleset]
    own = f"Data\\{rules['folder']}\\"
    others = [f"Data\\{r['folder']}\\" for k, r in RULESETS.items() if k != ruleset]
    guard = f'if addon.RULESET ~= "{ruleset}" then return end'
    shipped = [f for f in files if not any(f.startswith(o) for o in others)]

    for f in shipped:
        path = ROOT / f.replace("\\", "/")
        if not path.is_file():
            problems.append(f"listed but missing: {f}")
        elif f.startswith(own) and guard not in path.read_text(encoding="utf-8"):
            problems.append(f"{rules['folder']} data file without its guard: {f}")
    if not any(f.startswith(own) for f in shipped):
        problems.append(f"no {own} files listed")

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
    return toc, shipped


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--forever", required=True, metavar="VERSION", help="Mapzeroth_Forever.toc's ## Version")
    parser.add_argument("--modern", required=True, metavar="VERSION", help="Mapzeroth_Mainline.toc's ## Version")
    parser.add_argument("--out", default=str(ROOT / "dist"), help="where the zip goes (default: dist/)")
    args = parser.parse_args()
    versions = {"forever": args.forever, "modern": args.modern}

    header, files = read_dev_toc()
    problems, tocs, union, new_tags = [], {}, [], []
    for ruleset in RULESETS:
        toc, shipped = build_toc(ruleset, versions[ruleset], header, files, problems)
        tocs[ruleset] = toc
        union += [f for f in shipped if f not in union]
        paths = [f.replace("\\", "/") for f in shipped] + ["Media"]
        tag = check_version(ruleset, versions[ruleset], paths, problems)
        if tag:
            new_tags.append(tag)
    problems += [f"asset missing: {a}" for a in ASSETS if not (ROOT / a).is_file()]
    dirty = git("status", "--porcelain", "--", *[f.replace("\\", "/") for f in union], "Media").stdout.splitlines()
    problems += [f"uncommitted: {line[3:]}" for line in dirty]
    if not new_tags:
        problems.append("neither version went up: nothing to release")
    if problems:
        sys.exit("not packaged:\n  " + "\n  ".join(problems))

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"{NAME}-{args.modern}-forever-{args.forever}.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for ruleset, toc in tocs.items():
            z.writestr(f"{NAME}/{NAME}_{RULESETS[ruleset]['suffix']}.toc", "\r\n".join(toc) + "\r\n")
        for f in union:
            z.write(ROOT / f.replace("\\", "/"), f"{NAME}/{f.replace(chr(92), '/')}")
        for a in ASSETS:
            z.write(ROOT / a, f"{NAME}/{a}")

    size = zip_path.stat().st_size
    print(f"wrote {zip_path} ({len(union) + len(tocs) + len(ASSETS)} files, {size / 1024:.0f} KB)")
    for ruleset, rules in RULESETS.items():
        print(f"  {NAME}_{rules['suffix']}.toc: {NAME} {versions[ruleset]}, Interface {rules['interface']}")
    head = git("rev-parse", "--short", "HEAD").stdout.strip()
    print(f"tag {head} with: " + ", ".join(new_tags))


if __name__ == "__main__":
    main()
