"""Generate and audit the equipment catalog. Offline commands never download.

Fetch explicitly with ``fetch --build B``; build from pinned cached inputs.
``--check`` verifies generated Lua against the committed normalized reference.
"""
import argparse
import collections
import json
import math
import os
from pathlib import Path
import unicodedata
import csv
import hashlib
import html
import re
import urllib.request
import concurrent.futures
from datetime import date

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / 'tools/reference/loot.json'
OUT = ROOT / 'LootData.lua'
KINDS = {'quest', 'boss', 'dungeonTrash', 'raidTrash', 'creature', 'rare',
         'object', 'world', 'vendor', 'craft', 'reputation', 'pvp'}
SLOTS = {1: 'INVTYPE_HEAD', 2: 'INVTYPE_NECK', 3: 'INVTYPE_SHOULDER', 5: 'INVTYPE_CHEST',
         6: 'INVTYPE_WAIST', 7: 'INVTYPE_LEGS', 8: 'INVTYPE_FEET', 9: 'INVTYPE_WRIST',
         10: 'INVTYPE_HAND', 11: 'INVTYPE_FINGER', 12: 'INVTYPE_TRINKET',
         13: 'INVTYPE_WEAPON', 14: 'INVTYPE_SHIELD', 15: 'INVTYPE_RANGED',
         16: 'INVTYPE_CLOAK', 17: 'INVTYPE_2HWEAPON', 20: 'INVTYPE_ROBE',
         21: 'INVTYPE_WEAPONMAINHAND', 22: 'INVTYPE_WEAPONOFFHAND',
         23: 'INVTYPE_HOLDABLE', 25: 'INVTYPE_THROWN', 26: 'INVTYPE_RANGEDRIGHT',
         28: 'INVTYPE_RELIC'}


def ascii_text(text):
    return unicodedata.normalize('NFKD', str(text)).encode('ascii', 'ignore').decode()


def normalize_items(tables, build):
    """Accept normalized input rows. Client-table joins live in import_client()."""
    result = {}
    for raw in tables:
        item = dict(raw)
        key = str(int(item['id']))
        if key in result:
            raise ValueError('duplicate item ' + key)
        item.setdefault('stats', {})
        item.setdefault('complete', {'stats': False, 'restrictions': False, 'effects': False})
        item.setdefault('sourceIDs', [])
        result[key] = item
    return result


def normalize_sources(raw, items, manifest):
    result = {}
    for source in raw:
        key = source['id']
        if key in result:
            raise ValueError('duplicate source ' + key)
        if str(source['item']) not in items:
            raise ValueError('unknown source item ' + key)
        result[key] = dict(source)
    return result


def validate(ref):
    errors = []
    if ref.get('schema') != 1 or not ref.get('build'):
        errors.append('unsupported schema or missing build')
    items, sources = ref.get('items', {}), ref.get('sources', {})
    for key, it in items.items():
        if str(it.get('id')) != str(key) or not it.get('name') or not it.get('slot'):
            errors.append('invalid item identity ' + str(key))
        if not 0 <= it.get('requiredLevel', 0) <= 60:
            errors.append('invalid required level ' + str(key))
        for sid in it.get('sourceIDs', []):
            if sid not in sources or str(sources[sid].get('item')) != str(key):
                errors.append('missing/mismatched source ' + str(sid))
        for n in it.get('stats', {}).values():
            if not isinstance(n, (int, float)) or not math.isfinite(n):
                errors.append('invalid stats ' + str(key))
        if it.get('complete', {}).get('stats') and 'stats' not in it:
            errors.append('complete stats absent ' + str(key))
    for key, s in sources.items():
        if s.get('type') not in KINDS or key != s.get('id') or str(s.get('item')) not in items:
            errors.append('invalid source ' + str(key))
        if 'x' in s or 'y' in s:
            if not s.get('map') or not all(isinstance(s.get(a), (int, float)) and 0 <= s[a] <= 100 for a in ('x', 'y')):
                errors.append('invalid source coordinates ' + str(key))
        if s.get('cost', 0) < 0 or any(n < 0 for n in s.get('materials', {}).values()):
            errors.append('invalid source cost ' + str(key))
    for key, quest in ref.get('questFacts', {}).items():
        if str(quest.get('id')) != key or not quest.get('name'):
            errors.append('invalid quest identity ' + key)
        for where in quest.get('start', []) + quest.get('finish', []):
            if not where.get('name'):
                errors.append('missing quest contact ' + key)
            if 'map' in where and not all(isinstance(where.get(a), (int, float)) and 0 <= where[a] <= 100
                                          for a in ('x', 'y')):
                errors.append('invalid quest contact coordinates ' + key)
    return errors


def coverage(ref):
    items = ref['items']
    return {'items': len(items), 'sources': len(ref['sources']),
            'missingStats': sum(not i.get('complete', {}).get('stats') for i in items.values()),
            'unknownRestrictions': sum(not i.get('complete', {}).get('restrictions') for i in items.values()),
            'unmodeledEffects': sum(not i.get('complete', {}).get('effects') for i in items.values()),
            'bySlot': dict(collections.Counter(i['slot'] for i in items.values())),
            'bySource': dict(collections.Counter(s['type'] for s in ref['sources'].values())),
            'missingLocations': sum('map' not in s for s in ref['sources'].values()),
            'matrix': coverage_matrix(ref)}


def coverage_matrix(ref):
    classes={'WARRIOR':1,'PALADIN':2,'HUNTER':3,'ROGUE':4,'PRIEST':5,'SHAMAN':7,'MAGE':8,'WARLOCK':9,'DRUID':11}
    matrix={}
    for cls,bit in classes.items():
        for faction in ('Alliance','Horde'):
            bands={str(start):collections.Counter() for start in (1,11,21,31,41,51)}
            for item in ref['items'].values():
                restrictions=item.get('restrictions',{})
                if restrictions.get('classes') and cls not in restrictions['classes']:
                    continue
                if restrictions.get('classMask') and not restrictions['classMask'] & (1 << (bit-1)):
                    continue
                sources=[ref['sources'][sid] for sid in item.get('sourceIDs',[]) if sid in ref['sources']]
                if sources and all(s.get('faction') not in (None,'All',faction) for s in sources):
                    continue
                lvl=max(1,item.get('requiredLevel',1))
                band=str(((lvl-1)//10)*10+1)
                if band in bands:
                    bands[band][item['slot']]+=1
            matrix[cls+'/'+faction]={key:dict(value) for key,value in bands.items()}
    return matrix


def build_enchants(spells, recipes):
    body={'Boots':['INVTYPE_FEET'],'Bracer':['INVTYPE_WRIST'],'Chest':['INVTYPE_CHEST','INVTYPE_ROBE'],
          'Cloak':['INVTYPE_CLOAK'],'Gloves':['INVTYPE_HAND'],'Shield':['INVTYPE_SHIELD'],
          '2H Weapon':['INVTYPE_2HWEAPON'],'Weapon':['INVTYPE_WEAPON','INVTYPE_WEAPONMAINHAND','INVTYPE_WEAPONOFFHAND','INVTYPE_2HWEAPON']}
    out={}
    for name,r in sorted(recipes.items()):
        m=re.match(r'Enchant (.+?) - ',name)
        if not m or m[1] not in body:
            continue
        desc=spells.render(str(r['spell']))
        stats={}
        conditional=bool(re.search(r'when|sometimes|chance|often|\$|\{',desc,re.I))
        if not conditional:
            for label,key in STAT_NAMES.items():
                match=re.search(r'\+?(\d+) (?:to )?'+label+r'\b',desc,re.I) or re.search(label+r' by (\d+)\b',desc,re.I)
                if match:
                    stats[key]=int(match[1])
            match=re.search(r'(?:spell power|spell damage).*?(\d+)',desc,re.I)
            if match:
                stats['sp']=int(match[1])
            match=re.search(r'(\d+) (?:to all stats|to all attributes|all stats)',desc,re.I)
            if match:
                for k in ('str','agi','sta','int','spi'): stats[k]=int(match[1])
        known=bool(stats) and not conditional
        out[str(r['spell'])]={'id':r['spell'],'name':ascii_text(name),'slots':{s:True for s in body[m[1]]},
            'stats':stats,'complete':{'stats':True,'effects':known,'restrictions':True},
            'recipe':r['spell'],'materials':dict(r.get('mats',[])), 'plan':r.get('plan'),
            'profession':'ENCHANTING','requiredSkill':r.get('min',0),'source':'Client recipe; ask an enchanter or use the profession guide'}
    return out


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, str):
        return json.dumps(ascii_text(value), ensure_ascii=True)
    if isinstance(value, (float, int)):
        if not math.isfinite(value):
            raise ValueError('nonfinite Lua number')
        return str(value)
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return '{' + ','.join('[' + (str(int(k)) if str(k).isdigit() else lua(k)) + ']=' + lua(v)
                          for k, v in sorted(value.items(), key=lambda kv: str(kv[0]))) + '}'


def render(ref):
    errors = validate(ref)
    if errors:
        raise ValueError('; '.join(errors[:10]))
    data = {k: ref[k] for k in ('schema', 'build', 'items', 'sources', 'enchants')}
    if ref.get('questFacts'):
        data['questFacts'] = ref['questFacts']
    if ref.get('access'):
        data['access'] = ref['access']
    data['coverage'] = coverage(ref)
    indexes = {k: collections.defaultdict(list) for k in ('bySlot', 'bySource', 'byCreature')}
    for key, item in sorted(ref['items'].items(), key=lambda kv: int(kv[0])):
        indexes['bySlot'][item['slot']].append(int(key))
    for key, source in sorted(ref['sources'].items()):
        indexes['bySource'][source['type']].append(key)
        if source.get('npc'):
            indexes['byCreature'][source['npc']].append(key)
    data.update(indexes)
    lines = ['-- Generated by tools/lootdata.py; do not edit.', 'local _, ns = ...', 'ns.lootData = {}']
    for k, v in data.items():
        # One record per line keeps large generated diffs reviewable.
        if isinstance(v, dict):
            lines.append('ns.lootData.' + k + ' = {')
            for a, b in sorted(v.items(), key=lambda kv: str(kv[0])):
                key = str(int(a)) if str(a).isdigit() else lua(a)
                lines.append('[' + key + ']=' + lua(b) + ',')
            lines.append('}')
        else:
            lines.append('ns.lootData.' + k + ' = ' + lua(v))
    return '\n'.join(lines) + '\n'


def atomic_write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + '.part')
    temp.write_text(text, encoding='utf-8', newline='\n')
    os.replace(temp, path)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('command', nargs='?', choices=['fetch', 'build', 'audit', 'coverage'])
    p.add_argument('--check', action='store_true')
    p.add_argument('--build')
    p.add_argument('--cache', type=Path)
    p.add_argument('--output', type=Path)
    args = p.parse_args()
    if args.command in ('fetch', 'build'):
        return build_command(args)
    if not REF.exists():
        p.error('missing committed loot reference; run build from pinned cached inputs')
    ref = json.loads(REF.read_text(encoding='utf-8'))
    errors = validate(ref)
    if args.check:
        errors += [] if OUT.exists() and OUT.read_text(encoding='utf-8') == render(ref) else ['LootData.lua is stale']
    if args.command == 'coverage':
        text = json.dumps(coverage(ref), indent=2, sort_keys=True) + '\n'
        if args.output:
            atomic_write(args.output, text)
        else:
            print(text)
    for e in errors:
        print('ERROR:', e)
    print('loot audit: %d errors, %d items' % (len(errors), len(ref['items'])))
    return bool(errors)


def apply_overrides(ref, overrides):
    for key, patch in overrides.get('items', {}).items():
        ref['items'][key].update(patch)
    for key, patch in overrides.get('sources', {}).items():
        source = ref['sources'].setdefault(key, {'id': key})
        source.update(patch)
        sources = ref['items'][str(source['item'])]['sourceIDs']
        if key not in sources:
            sources.append(key)


def build_command(args):
    cache = ROOT / 'tools/.cache/loot' / (args.build or json.loads((ROOT/'tools/reference/forever.json').read_text())['build'])
    if args.command == 'fetch':
        fetch_catalog(args, cache)
        return 0
    base = cache / 'base.json'
    if not base.exists():
        raise SystemExit('missing pinned cached inputs: run fetch --build BUILD first')
    ref = json.loads(base.read_text(encoding='utf-8'))
    excluded = []
    for key, item in list(ref['items'].items()):
        path = cache / 'tips' / (key + '.json')
        if not path.exists():
            continue
        tip = json.loads(path.read_text(encoding='utf-8'))
        if tip.get('error') or not tip.get('name'):
            excluded.append({'id': key, 'reason': 'tooltip unavailable'})
            continue
        ref['items'][key] = parse_tooltip(int(key), tip, item)
        if ref['items'][key].get('requiredLevel', 0) > 60:
            del ref['items'][key]
            excluded.append({'id': key, 'reason': 'requires level above 60'})
    ref['sources'] = {k: v for k, v in ref['sources'].items() if str(v['item']) in ref['items']}
    for item in ref['items'].values():
        item['sourceIDs'] = [k for k in item.get('sourceIDs', []) if k in ref['sources']]
    from gamedata import load_lua_global
    from questroute import ROUTES
    routes = load_lua_global(ROUTES, 'LevelingCodexQuests')
    add_entrances(ref, routes)
    overrides = ROOT/'tools/reference/loot-overrides.json'
    if overrides.exists():
        apply_overrides(ref, json.loads(overrides.read_text(encoding='utf-8')))
    add_access_levels(ref, routes)
    errors = validate(ref)
    if errors:
        raise SystemExit('\n'.join(errors[:20]))
    atomic_write(REF, json.dumps(ref, sort_keys=True, separators=(',', ':')) + '\n')
    atomic_write(OUT, render(ref))
    manifest = json.loads((cache/'manifest.json').read_text(encoding='utf-8'))
    manifest['excluded'] = excluded
    manifest['coverage'] = coverage(ref)
    atomic_write(ROOT/'tools/reference/loot-manifest.json', json.dumps(manifest, indent=2, sort_keys=True)+'\n')
    print('built', len(ref['items']), 'items,', len(ref['sources']), 'sources')
    return 0


def add_entrances(ref, routes):
    entrances={}
    for faction in ('ALLIANCE','HORDE'):
        for section in routes.get(faction,{}).get('sections',[]):
            instance=section.get('instanceID')
            if not instance:
                continue
            for step in section.get('steps',[]):
                if step.get('type')=='dungeon' and all(step.get(k) is not None for k in ('map','x','y')):
                    entrances.setdefault(instance, {'map':step['map'],'x':step['x'],'y':step['y'],
                                                   'locationKind':'entrance','locationEvidence':'Codex dungeon route'})
                    break
    for s in ref['sources'].values():
        if not s.get('map') and s.get('instance') in entrances:
            s.update(entrances[s['instance']])


def source_creature_levels(sources, npcs):
    from questfacts import record
    ids = {s['npc'] for s in sources.values() if s.get('npc')}
    levels = {}
    for id_ in ids:
        level = record(npcs, id_).get('minLevel')
        if type(level) is int and level > 0:
            levels[str(id_)] = level
    return levels


def add_access_levels(ref, routes):
    # Dungeon starts come from the guide's leveling bands. Wing-less sources use the lowest
    # guide start alongside the named encounter's level when that level is known.
    instances, zones = {}, {}
    for faction in ('ALLIANCE', 'HORDE'):
        for section in routes[faction]['sections']:
            instance, zone = section.get('instanceID'), section.get('zone')
            start = section['levels'][0]
            if instance:
                key = str(instance)
                instances[key] = min(start, instances.get(key, start))
            elif zone and section.get('category') != 'dungeon':
                key = str(zone)
                zones[key] = min(start, zones.get(key, start))
    raids = {str(s['instance']): True for s in ref['sources'].values()
             if s.get('instance') and (s['type'] == 'raidTrash' or s.get('raid'))}
    ref['access'] = {'creatures': ref.pop('sourceCreatureLevels', {}), 'instances': instances,
                     'zones': zones, 'raids': raids}


STAT_NAMES = {'Strength': 'str', 'Agility': 'agi', 'Stamina': 'sta', 'Intellect': 'int',
              'Spirit': 'spi', 'Armor': 'armor', 'Attack Power': 'ap', 'Health': 'health', 'Mana': 'mana'}


def parse_tooltip(id_, tip, base):
    item = dict(base)
    item.update(id=id_, name=ascii_text(tip['name']), icon=tip.get('icon', base.get('icon')),
                quality=tip.get('quality', base.get('quality', 1)))
    raw = tip.get('tooltip', '').replace('\\"', '"')
    text = html.unescape(re.sub('<[^>]*>', '', re.sub(r'<br\s*/?>|</tr>|</td>', '\n', raw, flags=re.I)))
    lines = [re.sub(r'\s+', ' ', s).strip() for s in text.splitlines() if s.strip()]
    stats, unresolved = {}, []
    patterns = [
        (r'Increases damage and healing done by magical spells and effects by up to (\d+)', 'sp'),
        (r'Increases healing done by spells and effects by up to (\d+)', 'heal'),
        (r'Increases your spell damage by up to (\d+)', 'sp'),
        (r'\+\s*(\d+) (?:Ranged )?Attack Power', 'ap'),
        (r'Increases attack power by (\d+)', 'ap'),
        (r'Restores (\d+) mana per 5 sec', 'mp5'),
        (r'Improves your chance to hit with spells by (\d+)%', 'spellHit'),
        (r'Improves your chance to get a critical strike with spells by (\d+)%', 'spellCrit'),
        (r'Improves your chance to hit by (\d+)%', 'hit'),
        (r'Improves your chance to get a critical strike by (\d+)%', 'crit'),
        (r'Increased Defense \+(\d+)', 'defense'),
    ]
    for line in lines:
        if line.startswith(('Chance on hit:', 'Use:', 'Set:', '(')) and ('Set:' in line or line.startswith(('Chance on hit:', 'Use:'))):
            unresolved.append(line)
            continue
        for label, key in STAT_NAMES.items():
            m = re.fullmatch(r'\+?\s*(\d+) '+label, line)
            if m:
                stats[key] = stats.get(key, 0) + int(m[1])
        if line.startswith('Equip:'):
            found = False
            for pat, key in patterns:
                m = re.search(pat, line, flags=re.I)
                if m:
                    stats[key] = stats.get(key, 0) + int(m[1])
                    found = True
                    break
            if not found:
                school = re.search(r'Increases damage done by (Arcane|Fire|Frost|Nature|Shadow|Holy) spells and effects by up to (\d+)', line)
                if school:
                    stats['sp'+school[1]] = int(school[2]); found = True
            if not found:
                unresolved.append(line)
    item['stats'] = stats
    item['complete'] = {'stats': bool(raw), 'restrictions': bool(raw), 'effects': not unresolved and bool(raw)}
    item['warnings'] = [ascii_text(s) for s in unresolved]
    item['effects'] = item.get('effects', [])
    item['restrictions'] = dict(item.get('restrictions', {}))
    for pattern, key in [(r'Requires Level\s+(\d+)', 'requiredLevel'), (r'Item Level\s+(\d+)', 'level')]:
        m = re.search(pattern, text)
        if m:
            item[key] = int(m[1])
    m = re.search(r'(\d+(?:\.\d+)?) damage per second', text)
    if m:
        item['damage'] = float(m[1])
    m = re.search(r'Speed\s+(\d+(?:\.\d+)?)', text)
    if m:
        item['speed'] = float(m[1])
    m = re.search(r'Classes:\s*([^\n]+)', text)
    if m:
        item['restrictions']['classes'] = [s.strip().upper() for s in m[1].split(',')]
    if 'Unique-Equipped' in text:
        item['restrictions']['unique'] = str(base.get('uniqueGroup') or id_)
    for line in lines:
        if line.startswith('Requires ') and not re.match(r'Requires Level\b', line):
            # Keep non-level requirements conservative until a reader resolves their IDs.
            item['restrictions']['text'] = ascii_text(line)
    item['random'] = 'Random enchantment' in text or 'Random Enchantment' in text
    if item['random']:
        item['complete']['stats'] = False
    item['tradable'] = 'Binds when equipped' in text or 'Binds when used' in text
    item['evidence'] = 'forever-tooltip'
    item['sourceIDs'] = base.get('sourceIDs', [])
    return item


def read_csv(cache, name):
    with (cache/(name+'.csv')).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def quest_facts(ref, quests, npcs, objects):
    """Keep the recorded contacts and prerequisite links for reward quests."""
    from questfacts import record, ZONES
    zones = {area: (name, map_id) for name, (area, map_id) in ZONES.items()}
    zones[17] = ('The Barrens', 1413)
    zones[36] = ('Alterac Mountains', 1416)
    capital_sides = {1453: 'Alliance', 1455: 'Alliance', 1457: 'Alliance',
                     1454: 'Horde', 1456: 'Horde', 1458: 'Horde'}

    def contacts(edges):
        out = []
        for kind, records in ((1, npcs), (2, objects)):
            for id_ in sorted(set(edges.get(kind, {}).values())):
                entity = record(records, id_)
                if not entity.get('name'):
                    continue
                name = ascii_text(entity['name'])
                mapped = False
                for area, points in sorted(entity.get('spawns', {}).items()):
                    if area not in zones:
                        continue
                    xy = next((p for p in points.values()
                               if 0 <= p.get(1, -1) <= 100 and 0 <= p.get(2, -1) <= 100), None)
                    if xy is None:
                        continue
                    zone, map_id = zones[area]
                    where = {'name': name, 'zone': zone, 'map': map_id, 'x': round(xy[1], 2), 'y': round(xy[2], 2)}
                    if map_id in capital_sides:
                        where['faction'] = capital_sides[map_id]
                    out.append(where)
                    mapped = True
                if not mapped:
                    out.append({'name': name})
        return out

    pending = sorted({s['quest'] for s in ref['sources'].values() if s.get('quest')})
    seen, facts = set(), {}
    for id_ in pending:
        if id_ in seen:
            continue
        seen.add(id_)
        q = record(quests, id_)
        if not q.get('name'):
            continue
        previous = sorted({p for field in ('preQuestSingle', 'preQuestGroup')
                           for p in q.get(field, {}).values() if p > 0})
        pending.extend(previous)
        facts[str(id_)] = {'id': id_, 'name': ascii_text(q['name']),
                           'start': contacts(q.get('startedBy', {})), 'finish': contacts(q.get('finishedBy', {})),
                           'previous': previous}
    return facts


def fetch_catalog(args, cache):
    """Read existing pinned quest/game facts and fetch only independently served item tooltips."""
    from questfacts import lua_reader, entity, record, REV, ZONES
    import questfacts
    build = args.build or json.loads((ROOT/'tools/reference/forever.json').read_text())['build']
    input_cache = args.cache or ROOT/'tools/.cache'
    game = input_cache/build
    quest_cache = input_cache/('questiedb-'+REV[:7])
    if not quest_cache.exists():
        quest_cache = input_cache/('quest-records-'+REV[:7])
    questfacts.CACHE = quest_cache
    lu, read = lua_reader()
    data = {kind: entity(lu, read, 'forever', kind) for kind in ('item','npc','object','quest')}
    sparse = {r['ID']: r for r in read_csv(game, 'ItemSparse')}
    client = {r['ID']: r for r in read_csv(game, 'Item')}
    area = {int(r['ID']): r for r in read_csv(game, 'AreaTable')}
    maps = {int(r['ID']): r for r in read_csv(game, 'Map')}
    zone_maps = {a: m for a, m in ZONES.values()}
    items, sources = {}, {}
    def source(item, kind, entity_id):
        key = f'{kind}:{entity_id}:{item["id"]}'
        e = record(data['quest' if kind == 'quest' else 'object' if kind == 'object' else 'npc'], entity_id)
        s = {'id': key, 'type': kind, 'item': item['id'], 'name': ascii_text(e.get('name', str(entity_id))), 'evidence': 'database-reference'}
        s['quest' if kind == 'quest' else 'object' if kind == 'object' else 'npc'] = entity_id
        positions = e.get('spawns', {})
        if kind == 'quest':
            s['requiredLevel'] = e.get('requiredLevel', 1)
            s['prerequisites'] = list((e.get('preQuestSingle') or {}).values()) + list((e.get('preQuestGroup') or {}).values())
            races = e.get('requiredRaces', 0)
            if races:
                # Match the existing reader's faction masks, including new races.
                s['faction'] = 'Alliance' if races & 0x10000004D and not races & 0x2000000B2 else 'Horde' if races & 0x2000000B2 and not races & 0x10000004D else 'All'
            starts = e.get('startedBy', {}).get(1, {})
            npc = next(iter(starts.values()), None)
            if npc:
                s['giver'] = npc
                giver = record(data['npc'], npc)
                s['giverName'] = ascii_text(giver.get('name', str(npc)))
                positions = giver.get('spawns', {})
        for zone, coords in positions.items():
            s.setdefault('zone', ascii_text(area.get(zone, {}).get('AreaName_lang', str(zone))))
            a = area.get(zone, {})
            inst = maps.get(int(a.get('ContinentID') or 0), {})
            if int(inst.get('InstanceType') or 0) in (1, 2) and kind not in ('quest','vendor'):
                s['type'] = 'raidTrash' if int(inst['InstanceType']) == 2 else 'dungeonTrash'
                if s['type'] == 'raidTrash':
                    s['raid'] = True
                s['instance'] = int(inst['ID']); s['dungeon'] = ascii_text(inst.get('MapName_lang', s['zone']))
                # Elite dungeon creatures are not necessarily bosses; keep this explicit.
            for xy in coords.values():
                if zone in zone_maps and 0 <= xy.get(1, -1) <= 100 and 0 <= xy.get(2, -1) <= 100:
                    s.update(map=zone_maps[zone], x=round(xy[1], 2), y=round(xy[2], 2))
                    break
            if s.get('map'):
                break
        sources[key] = s
        item['sourceIDs'].append(key)
    item_keys = set(int(k) for k in data['item'][1].keys()) | set(int(k) for k in sparse)
    for id_ in sorted(item_keys):
        key = str(id_)
        c, sp = client.get(key), sparse.get(key, {})
        if not c or int(c['InventoryType']) not in SLOTS or int(c['ClassID']) not in (2, 4):
            continue
        old = record(data['item'], id_)
        level = int(sp.get('RequiredLevel') or old.get('requiredLevel', 0))
        if level > 60 or level < 0:
            continue
        item = {'id': id_, 'name': ascii_text(sp.get('Display_lang') or old.get('name') or ('Item '+key)),
                'slot': SLOTS[int(c['InventoryType'])], 'classID': int(c['ClassID']), 'subclassID': int(c['SubclassID']),
                'requiredLevel': level, 'level': int(sp.get('ItemLevel') or old.get('itemLevel',0)),
                'icon': int(c['IconFileDataID']), 'stats': {}, 'effects': [], 'restrictions': {},
                'complete': {'stats': False, 'effects': False, 'restrictions': False}, 'sourceIDs': []}
        if sp:
            cm = int(sp.get('AllowableClass') or -1)
            if cm not in (-1, 0):
                item['restrictions']['classMask'] = cm
            if int(sp.get('ItemSet') or 0):
                item['restrictions']['set'] = int(sp['ItemSet'])
            if int(sp.get('RequiredSkill') or 0):
                item['restrictions'].update(skill=int(sp['RequiredSkill']), skillRank=int(sp.get('RequiredSkillRank') or 0))
        items[key] = item
        for field, kind in [('questRewards','quest'),('npcDrops','creature'),('objectDrops','object'),('vendors','vendor')]:
            for n in (old.get(field) or {}).values():
                source(item, kind, int(n))
    ref = {'schema': 1, 'build': build, 'items': items, 'sources': sources, 'enchants': {}}
    ref['questFacts'] = quest_facts(ref, data['quest'], data['npc'], data['object'])
    ref['sourceCreatureLevels'] = source_creature_levels(sources, data['npc'])
    # Existing profession output records are client-verified source links.
    game_ref = json.loads((ROOT/'tools/reference/forever.json').read_text())
    bosses={e[1].casefold() for instance in game_ref['quests']['instances'].values() for e in instance.get('encounters',[])}
    for s in sources.values():
        if s['type'] in ('dungeonTrash','raidTrash') and s['name'].casefold() in bosses:
            s['type']='boss'
        elif s['type']=='creature' and s.get('npc') and record(data['npc'],s['npc']).get('rank')==4:
            s['type']='rare'
    for key,item in items.items():
        sp=sparse.get(key,{})
        faction=int(sp.get('MinFactionID') or 0); rank=int(sp.get('RequiredPVPRank') or 0)
        if faction:
            sid='reputation:'+key
            sources[sid]={'id':sid,'item':item['id'],'type':'reputation','name':'Faction '+str(faction),
                          'reputation':faction,'standing':int(sp.get('MinReputation') or 0),'evidence':'client'}
            item['sourceIDs'].append(sid)
        if rank:
            sid='pvp:'+key
            sources[sid]={'id':sid,'item':item['id'],'type':'pvp','name':'PvP reward','rank':rank,'evidence':'client'}
            item['sourceIDs'].append(sid)
    for prof, p in game_ref['professions'].items():
        for name, r in p.get('recipes', {}).items():
            made = r.get('makes')
            # makes uses a product name; match exact names, never synthesize an item ID.
            for it in (i for i in items.values() if made and i['name'] == made[0]):
                key = f'craft:{r["spell"]}:{it["id"]}'
                sources[key] = {'id':key,'type':'craft','item':it['id'],'name':prof+': '+ascii_text(name),
                                'profession':prof.upper(), 'recipe':r['spell'],'materials':dict(r.get('mats',[])),'evidence':'client'}
                it['sourceIDs'].append(key)
    from gamedata import Tables, Spells
    ref['enchants']=build_enchants(Spells(Tables(str(game))),game_ref['professions']['Enchanting']['recipes'])
    atomic_write(cache/'base.json', json.dumps(ref, sort_keys=True, separators=(',',':')))
    manifest = {'schema':1,'build':build,'retrieved':str(date.today()),'sources':[
        {'url':'https://wago.tools/db2/Item/csv?build='+build, 'revision':build,'fields':'identity,slot,subclass,restrictions'},
        {'url':'https://github.com/Questie/QuestieDB/tree/'+REV,'revision':REV,'fields':'acquisition facts; reference evidence, not confirmed live drop rates'},
        {'url':'https://nether.wowhead.com/forever/tooltip/item/{id}', 'revision':str(date.today()),'fields':'name,stats,requirements,effects'}],
        'hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (game/'Item.csv',game/'ItemSparse.csv')},
        'notes':'Derived factual records. Acquisition reference is not proof of live server tuning; unknowns remain unknown.'}
    atomic_write(cache/'manifest.json', json.dumps(manifest, indent=2))
    tipdir = cache/'tips'; tipdir.mkdir(parents=True, exist_ok=True)
    pending = [k for k in items if not (tipdir/(k+'.json')).exists()]
    def download(key):
        u = 'https://nether.wowhead.com/forever/tooltip/item/'+key
        try:
            with urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'LevelingCodex-loot/1.0'}),timeout=20) as response:
                tip = json.load(response)
            atomic_write(tipdir/(key+'.json'), json.dumps(tip, ensure_ascii=True))
            return True
        except Exception:
            return False
    print('catalog candidates:', len(items), 'sources:',len(sources),'tooltips to fetch:',len(pending), flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for n, ok in enumerate(pool.map(download, pending), 1):
            if n % 250 == 0:
                print('tooltips processed:',n,'/',len(pending),flush=True)


if __name__ == '__main__':
    raise SystemExit(main())
