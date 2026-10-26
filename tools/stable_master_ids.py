"""The ids of every NPC the retail client titles Stable Master, for tools/wowhead_scrape_retail.js's MZR_IDS (no Wowhead
list finds NPCs by title, and the wiki's category stops around Cataclysm).

Source: tools/modern_source/creature_retail.csv, the client's Creature table (https://wago.tools/db2/Creature, CSV, the
same export as the other *_retail.csv here). An NPC is a stable master when its title (Title_lang or TitleAlt_lang) is
"Stable Master" or "Stablemaster". Prints the line to paste into the browser console before the script.

    python tools/stable_master_ids.py
"""
import csv
import pathlib
import re
import sys

SOURCE = pathlib.Path(__file__).resolve().parent / "modern_source" / "creature_retail.csv"
STABLE_MASTER = re.compile(r"stable\s*master", re.I)


def main():
    if not SOURCE.exists():
        sys.exit(f"{SOURCE} is missing: export https://wago.tools/db2/Creature as CSV to it")
    ids = []
    with open(SOURCE, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            titles = (row.get("Title_lang") or "", row.get("TitleAlt_lang") or "")
            if any(STABLE_MASTER.search(t) for t in titles):
                ids.append(int(row["ID"]))
    ids.sort()
    print(f"// {len(ids)} stable masters", file=sys.stderr)
    print(f"window.MZR_IDS = [{', '.join(map(str, ids))}]; window.MZR_TAG = 'Stable Master';")


if __name__ == "__main__":
    main()
