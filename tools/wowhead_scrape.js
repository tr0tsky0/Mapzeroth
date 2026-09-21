// wowhead_scrape.js -- pulls NPC locations for one role out of Wowhead's Forever
// database. Run it in the browser console (or the Claude browser pane's JS tool)
// on a Forever NPC list page filtered to a role, for example:
//
//   https://www.wowhead.com/forever/npcs?filter=23;1;0      (Innkeeper)
//
// Role filter ids on that page: 18 Auctioneer, 19 Banker, 20 Battlemaster,
// 21 Flight master, 22 Guild master, 23 Innkeeper, 24 Class trainer,
// 25 Tabard vendor, 27 Stable master, 28 Trainer, 29 Vendor.
// The page's list is capped at 1000 rows, so narrow big roles further.
//
// It reads the NPC list out of the page, then fetches each NPC's own page
// (same origin, one every 250 ms) and reads `g_mapperData`, which holds the
// map id and x, y coordinates (0-100, as the map cursor shows them). Result:
// window.__npcs = [{ id, name, tag, loc, map }], and a tab-separated dump.

(async function () {
    const source = [...document.scripts].map(s => s.textContent).find(t => t && t.includes('new Listview'));
    const start = source.indexOf('"data":') + 7;
    let depth = 0, end = start;
    for (let k = start; k < source.length; k++) {
        const c = source[k];
        if (c === '[') depth++;
        else if (c === ']') { depth--; if (depth === 0) { end = k + 1; break; } }
    }
    const npcs = JSON.parse(source.slice(start, end));

    const results = [];
    for (const n of npcs) {
        const html = await (await fetch('/forever/npc=' + n.id)).text();
        const m = html.match(/g_mapperData\s*=\s*(\{[\s\S]*?\});/);
        results.push({ id: n.id, name: n.name, tag: n.tag, loc: n.location, map: m ? JSON.parse(m[1]) : null });
        await new Promise(r => setTimeout(r, 250));
    }
    window.__npcs = results;

    // id <tab> name <tab> tag <tab> uiMapId <tab> map name <tab> "x,y x,y ..."
    const lines = [];
    for (const r of results) {
        for (const zone in (r.map || {})) {
            for (const e of r.map[zone]) {
                lines.push([r.id, r.name, r.tag || '', e.uiMapId, e.uiMapName,
                    e.coords.map(c => c.join(',')).join(' ')].join('\t'));
            }
        }
    }
    window.__npcTsv = lines.join('\n');
    return { npcs: results.length, rows: lines.length };
})();
