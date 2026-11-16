"""Offline guarantees for the loot catalog; no network is needed by this suite."""
import copy
import importlib.util
from pathlib import Path
import unittest

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


if __name__ == '__main__':
    unittest.main()
