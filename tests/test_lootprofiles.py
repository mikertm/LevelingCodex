from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LootProfileTests(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          saved={}; ns={loot={refresh=function() end},charDB=function() return saved end,
            TALENT_PATHS={DRUID={{key="guide",spec="Feral",role="Melee damage"},
              {key="balance",spec="Balance",role="Caster damage"}}}}
          function UnitClass() return "Druid","DRUID" end
          ns.talentPath=function() return ns.TALENT_PATHS.DRUID[1] end
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        p=ROOT/'LootProfiles.lua'
        self.assertTrue(p.exists(),'loot profiles are missing')
        self.lua.globals().load_module(p.read_text())

    def test_every_path_maps_and_feral(self):
        self.lua.execute('''
          local p=ns.loot.profile({class="DRUID"}); assert(p.weapon.feral)
          assert(ns.loot.profile({class="DRUID",profileKey="balance"}).role=="Caster damage")
        ''')

    def test_every_real_path_maps(self):
        self.lua.globals().load_module((ROOT/'TalentPaths.lua').read_text(encoding='utf-8'))
        self.lua.execute('''
          for c,paths in pairs(ns.TALENT_PATHS) do for _,path in ipairs(paths) do
            local p=ns.loot.profile({class=c,profileKey=path.key})
            assert(p.key==path.key and p.class==c and next(p.weights),c..":"..path.key)
          end end
        ''')

    def test_code_roundtrip_and_invalid_preserves_profile(self):
        self.lua.execute('''
          assert(ns.loot.setProfile({class="DRUID",label="My profile",weights={str=3},weapon={feral=true}}))
          local code=ns.loot.profileCode(); ns.loot.resetProfile()
          assert(ns.loot.readProfileCode(code)); assert(ns.loot.profile().weights.str==3)
          assert(not ns.loot.readProfileCode("LCL1-DRUID-loadstring-danger"))
          assert(ns.loot.profile().weights.str==3)
          assert(not ns.loot.setProfile({class="DRUID",weights={str=0/0}}))
          assert(not ns.loot.setProfile({class="DRUID",weights={str=-1}}))
          assert(not ns.loot.setProfile({class="DRUID",weights={str=10001}}))
          assert(not ns.loot.readProfileCode(string.rep("x",4097)))
        ''')

if __name__=='__main__': unittest.main()
