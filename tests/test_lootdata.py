"""Offline guarantees for the loot catalog; no network is needed by this suite."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch
import sys

ROOT = Path(__file__).resolve().parents[1]


class LootDataTests(unittest.TestCase):
    def setUp(self):
        path = ROOT / 'tools' / 'lootdata.py'
        self.assertTrue(path.exists(), 'loot catalog generator is missing')
        spec = importlib.util.spec_from_file_location('lootdata', path)
        self.g = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.g)
        self.fixture = {'schema': 1, 'build': 'test', 'items': {
            '1': {'id': 1, 'name': 'Plain Sword', 'slot': 'INVTYPE_WEAPON', 'requiredLevel': 1,
                  'stats': {}, 'complete': {'stats': False, 'restrictions': True, 'effects': True},
                  'sourceIDs': ['quest:1', 'vendor:2']}}, 'sources': {
            'quest:1': {'id': 'quest:1', 'type': 'quest', 'item': 1, 'quest': 1},
            'vendor:2': {'id': 'vendor:2', 'type': 'vendor', 'item': 1, 'npc': 2}}, 'enchants': {}}

    def test_schema_unknown_is_not_zero(self):
        self.assertEqual(self.g.validate(self.fixture), [])
        self.assertNotIn('cost', self.fixture['sources']['vendor:2'])
        self.assertFalse(self.fixture['items']['1']['complete']['stats'])

    def test_multiple_sources_survive(self):
        sources = self.g.normalize_sources(list(self.fixture['sources'].values()), self.fixture['items'], {})
        self.assertEqual(set(sources), {'quest:1', 'vendor:2'})
        self.assertEqual(self.g.coverage(self.fixture)['items'], 1)

    def test_render_is_deterministic_ascii(self):
        other = copy.deepcopy(self.fixture)
        other['sources'] = dict(reversed(list(other['sources'].items())))
        self.assertEqual(self.g.render(self.fixture), self.g.render(other))
        self.g.render(other).encode('ascii')

    def test_reject_invalid_coordinates_and_missing_source(self):
        self.fixture['sources']['vendor:2'].update(map=1, x=101, y=50)
        self.assertTrue(self.g.validate(self.fixture))
        self.fixture['sources'].pop('quest:1')
        self.assertTrue(any('source' in str(e) for e in self.g.validate(self.fixture)))

    def test_reject_duplicate_sources(self):
        row = self.fixture['sources']['quest:1']
        with self.assertRaises(ValueError):
            self.g.normalize_sources([row, row], self.fixture['items'], {})

    def test_tooltip_stats_and_unmodeled_effect(self):
        tip = {'name': 'Sash', 'quality': 3, 'icon': 'inv_belt_01', 'tooltip':
               '<br>17 Armor<br>+3 Stamina<br>+3 Intellect<br>Requires Level 10'
               '<br>Equip: Increases damage and healing done by magical spells and effects by up to 4.'}
        item = self.g.parse_tooltip(5, tip, {'slot': 'INVTYPE_WAIST'})
        self.assertEqual(item['stats'], {'armor': 17, 'sta': 3, 'int': 3, 'sp': 4})
        self.assertTrue(item['complete']['stats'])
        tip['tooltip'] += '<br>Chance on hit: Increases Strength by 200 for 12 sec.'
        self.assertFalse(self.g.parse_tooltip(5, tip, {})['complete']['effects'])

    def test_forever_identity_wins(self):
        result = self.g.parse_tooltip(1, {'name': 'Forever Name', 'tooltip': '<br>+4 Strength'},
                                      {'name': 'Old Name', 'stats': {'str': 2}})
        self.assertEqual(result['name'], 'Forever Name')
        self.assertEqual(result['stats']['str'], 4)

    def test_classic_source_is_unverified_without_evidence(self):
        sources = self.g.normalize_sources([{'id': 'world:1', 'type': 'world', 'item': 1,
                                            'evidence': 'candidate'}], self.fixture['items'], {})
        self.assertEqual(sources['world:1']['evidence'], 'candidate')

    def test_coverage_counts_unique_items(self):
        self.assertEqual(self.g.coverage(self.fixture)['items'], 1)

    def test_enchant_slots_and_proc_uncertainty(self):
        class Spells:
            def render(self, sid):
                return {'1': 'Permanently enchant a two-handed melee weapon to grant +25 Agility.',
                        '2': 'Permanently enchant boots to sometimes restore mana.'}[sid]
        enchants = self.g.build_enchants(Spells(), {
            'Enchant 2H Weapon - Agility': {'spell': 1, 'mats': [['Dust', 2]]},
            'Enchant Boots - Mana': {'spell': 2, 'mats': [['Dust', 2]]}})
        self.assertEqual(enchants['1']['stats']['agi'], 25)
        self.assertNotIn('INVTYPE_WEAPON', enchants['1']['slots'])
        self.assertFalse(enchants['2']['complete']['effects'])

    def test_update_report_includes_loot(self):
        sys.path.insert(0, str(ROOT/'tools'))
        import gamedata
        ref = json.loads((ROOT/'tools/reference/forever.json').read_text())
        rows = gamedata.full_audit(ref, 'LOOT')
        self.assertTrue(any(c=='LOOT' for c,_,_ in rows), 'loot is absent from game-data audits')

    def test_offline_checks_do_not_fetch(self):
        with patch('urllib.request.urlopen', side_effect=AssertionError('offline command fetched data')):
            self.assertFalse(self.g.validate(self.fixture))
            self.assertIn('ns.lootData', self.g.render(self.fixture))

    def test_dungeon_entrance_is_labeled(self):
        ref={'sources':{'boss':{'instance':36,'name':'Boss'}}}
        routes={'ALLIANCE':{'sections':[{'instanceID':36,'steps':[{'type':'dungeon','map':1436,'x':42,'y':72}]}]}}
        self.g.add_entrances(ref,routes)
        s=ref['sources']['boss']
        self.assertEqual((s['map'],s['x'],s['locationKind']),(1436,42,'entrance'))


if __name__ == '__main__':
    unittest.main()
