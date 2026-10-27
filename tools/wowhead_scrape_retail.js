// wowhead_scrape_retail.js -- pulls NPC locations for one role out of retail Wowhead, in the columns
// tools/gen_modern_pois.py and tools/gen_modern_stables.py read (tools/modern_source/*.tsv). Run it in the browser
// console on a retail NPC list page, for example https://www.wowhead.com/npcs?filter=23;1;0 (the Innkeeper flag), or
// on a search page (https://www.wowhead.com/search?q=stable+master: its NPC tab).
//
// Or, where no list page has them all (stable masters: the Stable Master flag, filter=27;1;0, has 19 on retail, and
// name-extended: searches names, not titles), on any www.wowhead.com page with the NPC ids set first:
//
//   window.MZR_IDS = [11069, 44252, ...]; window.MZR_TAG = 'Stable Master';
//
// Each NPC's name and title then come from its own page (MZR_TAG when the page gives no title), and its reactions
// aren't known (the generator takes the faction of the town or city it stands in).
//
// The list is capped at 1000 rows, so a big role takes several pages. Each run adds to what earlier runs found
// (kept in localStorage under KEY, one row per NPC per map), so run it on each page in turn, then:
//
//   copy(localStorage.getItem('mzr_scrape'))    -> paste into tools/modern_source/stablemasters.tsv
//   localStorage.removeItem('mzr_scrape')       -> start over
//
// It reads the NPC list out of the page, then fetches each NPC's own page (one every 250 ms) and reads
// `g_mapperData`: per zone and floor, the uiMap and its spawns (0-100). Columns, tab-separated:
//
//   npcID  name  tag  zoneAreaID  uiMapID  floor  x,y  firstSeenPatch  react
//
// x,y is the middle of the biggest group of spawns on that map (spawns within 2 of one another); a floor Wowhead
// gives no uiMap for (a multi-floor city) has the uiMap column empty. firstSeenPatch is left empty (the stables
// don't use it); react is the list's "a,h" (1 friendly to Alliance / Horde).

(async function () {
    const KEY = 'mzr_scrape';

    // The NPC lists on this page, merged by id. A list page has one Listview; a search page has one per tab (NPCs,
    // items, ...), so only the NPC tab's are kept: from the page's own Listview objects when it keeps them
    // (g_listviews), else read out of its scripts.
    function npcLists() {
        const isNpc = lv => lv && (lv.id === 'npcs' || lv.template === 'npc' || (lv.template && lv.template.id === 'npc'));
        let lists = Object.values(window.g_listviews || {}).filter(isNpc).map(lv => lv.data || []);
        if (!lists.length) {
            lists = [];
            for (const text of [...document.scripts].map(s => s.textContent || '')) {
                let at = 0;
                while ((at = text.indexOf('new Listview(', at)) >= 0) {
                    const from = at;
                    at += 13;
                    const m = /["']?data["']?\s*:\s*\[/g;
                    m.lastIndex = at;
                    if (!m.exec(text)) continue;
                    const start = m.lastIndex - 1;
                    // This Listview's own options, up to its data: is it the NPC tab?
                    if (!/template["']?\s*:\s*["']npc["']|\bid["']?\s*:\s*["']npcs["']/.test(text.slice(from, start))) continue;
                    let depth = 0, end = -1, quote = null;
                    for (let k = start; k < text.length; k++) {
                        const c = text[k];
                        if (quote) { if (c === '\\') k++; else if (c === quote) quote = null; continue; }
                        if (c === '"' || c === "'") quote = c;
                        else if (c === '[') depth++;
                        else if (c === ']' && --depth === 0) { end = k + 1; break; }
                    }
                    if (end < 0) continue;
                    const literal = text.slice(start, end);
                    try { lists.push(JSON.parse(literal)); }
                    catch (e) { lists.push(Function('return ' + literal)()); }    // the page's own script, not JSON
                }
            }
        }
        const byId = new Map();
        for (const list of lists) for (const n of list) if (n && n.id) byId.set(n.id, n);
        return [...byId.values()];
    }
    let npcs;
    if (window.MZR_IDS) {
        npcs = [...new Set(window.MZR_IDS.map(Number))].map(id => ({ id, fromPage: true }));
    } else {
        npcs = npcLists();
        if (!npcs.length) throw new Error('no NPC list on this page: run it on an NPC list or search page, or set MZR_IDS (see the top of the script)');
    }
    console.log(`mzr: ${npcs.length} NPCs on this page, about ${Math.ceil(npcs.length / 4 / 60)} min to fetch`);

    // The middle of the biggest group of spawns (single linkage, 2 map units).
    function middle(coords) {
        const left = coords.slice(), groups = [];
        while (left.length) {
            const group = [left.pop()];
            let grew = true;
            while (grew) {
                grew = false;
                for (let i = left.length - 1; i >= 0; i--) {
                    if (group.some(g => Math.hypot(g[0] - left[i][0], g[1] - left[i][1]) <= 2)) {
                        group.push(left.splice(i, 1)[0]);
                        grew = true;
                    }
                }
            }
            groups.push(group);
        }
        const best = groups.sort((a, b) => b.length - a.length)[0];
        const x = best.reduce((s, c) => s + c[0], 0) / best.length, y = best.reduce((s, c) => s + c[1], 0) / best.length;
        return x.toFixed(1) + ',' + y.toFixed(1);
    }

    const rows = new Map();
    for (const line of (localStorage.getItem(KEY) || '').split('\n')) {
        if (line) { const f = line.split('\t'); rows.set(f[0] + ':' + f[3] + ':' + f[4] + ':' + f[5], line); }
    }
    const before = rows.size;
    for (const [i, n] of npcs.entries()) {
        if (i % 50 === 0) console.log(`mzr: ${i}/${npcs.length}`);
        const html = await (await fetch('/npc=' + n.id)).text();
        const m = html.match(/g_mapperData\s*=\s*(\{[\s\S]*?\});/);
        const data = m ? JSON.parse(m[1]) : {};
        if (n.fromPage) {
            // "Name <Title> - NPC - World of Warcraft"
            const doc = new DOMParser().parseFromString(html, 'text/html');
            const title = (doc.querySelector('h1.heading-size-1') || {}).textContent || doc.title.split(' - ')[0] || '';
            const t = title.trim().match(/^(.*?)\s*(?:<([^>]*)>)?$/);
            n.name = t ? t[1] : title.trim();
            n.tag = (t && t[2]) || (doc.title.match(/<([^>]*)>/) || [])[1] || window.MZR_TAG || '';
            if (!Object.keys(data).length) console.log(`mzr: ${n.id} ${n.name}: no map data`);
        }
        const react = (n.react || []).map(v => v == null ? '' : v).join(',');
        for (const zone in data) {
            // zone -> floor -> { coords, uiMapId }, or zone -> [ { coords, uiMapId } ]
            const floors = Array.isArray(data[zone]) ? Object.assign({}, data[zone]) : data[zone];
            for (const floor in floors) {
                const e = floors[floor];
                if (!e || !e.coords || !e.coords.length) continue;
                const uiMap = e.uiMapId || '';
                const fields = [n.id, n.name, n.tag || '', zone, uiMap, uiMap ? '' : floor, middle(e.coords), '', react];
                rows.set(n.id + ':' + zone + ':' + uiMap + ':' + (uiMap ? '' : floor), fields.join('\t'));
            }
        }
        await new Promise(r => setTimeout(r, 250));
    }
    localStorage.setItem(KEY, [...rows.values()].join('\n'));
    console.log(`mzr: done, ${rows.size} rows kept (copy(localStorage.getItem('${KEY}')) to copy them)`);
    return { npcs: npcs.length, newRows: rows.size - before, rows: rows.size };
})();
