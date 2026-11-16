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
    return errors


def coverage(ref):
    items = ref['items']
    return {'items': len(items), 'sources': len(ref['sources']),
            'missingStats': sum(not i.get('complete', {}).get('stats') for i in items.values()),
            'unknownRestrictions': sum(not i.get('complete', {}).get('restrictions') for i in items.values()),
            'unmodeledEffects': sum(not i.get('complete', {}).get('effects') for i in items.values()),
            'bySlot': dict(collections.Counter(i['slot'] for i in items.values())),
            'bySource': dict(collections.Counter(s['type'] for s in ref['sources'].values())),
            'missingLocations': sum('map' not in s for s in ref['sources'].values())}


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


def build_command(args):
    raise SystemExit('missing pinned import inputs; catalog ingestion is not configured')


if __name__ == '__main__':
    raise SystemExit(main())
