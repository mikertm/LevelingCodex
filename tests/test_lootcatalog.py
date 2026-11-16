from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LootCatalogTests(unittest.TestCase):
    def test_sources_deduplicate_and_filters_preserve_alternatives(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={lootData={items={[1]={id=1,name="First",slot="INVTYPE_CHEST",requiredLevel=1,sourceIDs={"q","v"}},
            [2]={id=2,name="Second",slot="INVTYPE_CHEST",requiredLevel=1,sourceIDs={"v2"}}},
            sources={q={id="q",item=1,type="quest"},v={id="v",item=1,type="vendor"},v2={id="v2",item=2,type="vendor"}},
            bySlot={INVTYPE_CHEST={1,2}},enchants={}},loot={}}
          local L=ns.loot; L.call=function(f,...) if f then return f(...) end end
          L.context=function() return {level=30,faction="Alliance",class="WARRIOR",snapshot={slots={}}} end
          L.item=function(ref) return type(ref)=="table" and ref or ns.lootData.items[ref] end
          L.compare=function(i,c) return {verdict="upgrade",delta=1,reason="test"} end
          L.slotsFor=function() return {5} end
          ns.plain=tostring
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        p=ROOT/'LootCatalog.lua'
        self.assertTrue(p.exists(),'catalog ranking is missing')
        lua.globals().load_module(p.read_text())
        lua.execute('''
          local r=ns.loot.candidates({source="vendor"}); assert(r.total==2 and #r.rows==2)
          assert(r.rows[1].item.id==1 and #r.rows[1].sources==1 and r.rows[1].sources[1].id=="v")
          r=ns.loot.candidates({},nil,0,1); assert(r.total==2 and #r.rows==1)
          local b=ns.loot.candidates({},nil,1,1); assert(b.rows[1].item.id~=r.rows[1].item.id)
          ns.lootData.sources.q.faction="Horde";ns.lootData.sources.v.faction="Horde"
          r=ns.loot.candidates({}); assert(r.total==1,"wrong-faction fixed rewards are not recommended")
        ''')

if __name__=='__main__': unittest.main()
