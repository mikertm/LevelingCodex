from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LootCatalogTests(unittest.TestCase):
    def test_visible_equipment_categories_include_every_inventory_type(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={lootData={items={},sources={},enchants={},bySlot={}},loot={}}
          L=ns.loot; L.call=function(f,...) if f then return f(...) end end
          L.context=function() return {level=60,faction="Alliance"} end
          L.compare=function() return {verdict="upgrade",delta=1} end
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
          groups={INVTYPE_CHEST={"INVTYPE_CHEST","INVTYPE_ROBE"},
            INVTYPE_WEAPON={"INVTYPE_WEAPON","INVTYPE_WEAPONMAINHAND","INVTYPE_2HWEAPON"},
            INVTYPE_WEAPONOFFHAND={"INVTYPE_WEAPON","INVTYPE_WEAPONOFFHAND","INVTYPE_SHIELD","INVTYPE_HOLDABLE"},
            INVTYPE_RANGED={"INVTYPE_RANGED","INVTYPE_RANGEDRIGHT","INVTYPE_THROWN"}}
          local id=0
          for _,types in pairs(groups) do for _,slot in ipairs(types) do
            if not ns.lootData.bySlot[slot] then
              id=id+1;local key="vendor"..id
              ns.lootData.items[id]={id=id,name=slot,slot=slot,requiredLevel=1,sourceIDs={key}}
              ns.lootData.sources[key]={id=key,item=id,type="vendor",requiredLevel=1}
              ns.lootData.bySlot[slot]={id}
            end
          end end
        ''')
        lua.globals().load_module((ROOT/'LootCatalog.lua').read_text())
        lua.execute('''
          for category,types in pairs(groups) do
            assert(L.candidates({slot=category}).total==#types,category.." omits inventory types")
          end
          ns.lootData.items[1].requiredLevel=20
          L.context=function() return {level=10,faction="Alliance"} end
          L.compare=function(it,c) return {verdict=it.requiredLevel>c.level and "cannotEquip" or "upgrade",delta=1} end
          local future=L.candidates({maxLevel=20,search="1"})
          assert(future.total==1 and future.rows[1].futureLevel==20,"explicit future browsing keeps level-locked gear visible")
        ''')

    def test_sources_deduplicate_and_filters_preserve_alternatives(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={lootData={items={[1]={id=1,name="First",slot="INVTYPE_CHEST",requiredLevel=1,sourceIDs={"q","v"}},
            [2]={id=2,name="Second",slot="INVTYPE_CHEST",requiredLevel=1,sourceIDs={"v2"}}},
            sources={q={id="q",item=1,type="quest",requiredLevel=1},
              v={id="v",item=1,type="vendor",requiredLevel=1},v2={id="v2",item=2,type="vendor",requiredLevel=1}},
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
          ns.lootData.sources.q.requiredLevel=50;ns.lootData.sources.v.requiredLevel=50
          assert(ns.loot.candidates({}).total==1,"source requirements gate current-level recommendations")
          assert(ns.loot.candidates({maxLevel=60}).total==2,"explicit future planning exposes later sources")
          assert(#ns.loot.sources(1)==2,"details retain locked sources and their requirements")
          ns.lootData.sources.q.requiredLevel=1;ns.lootData.sources.v.requiredLevel=1
          ns.lootData.sources.q.faction="Horde";ns.lootData.sources.v.faction="Horde"
          r=ns.loot.candidates({}); assert(r.total==1,"wrong-faction fixed rewards are not recommended")
        ''')

    def test_recommendations_require_level_appropriate_acquisition(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={loot={},lootData={items={},sources={},bySlot={},access={
            creatures={[10]=25,[20]=60},instances={[30]=22,[40]=57},raids={[99]=true},zones={}}}}
          local L=ns.loot
          L.call=function(f,...) if f then return f(...) end end
          L.context=function() return {level=31,faction="Alliance"} end
          L.compare=function() return {verdict="upgrade",confidence="complete",delta=1} end
          L.version=1
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
          function add(id,source,tradable)
            local key="source"..id
            ns.lootData.items[id]={id=id,name="Item "..id,slot="INVTYPE_WEAPON",level=65,
              requiredLevel=1,sourceIDs=source and {key} or {},tradable=tradable}
            if source then source.id=key;source.item=id;ns.lootData.sources[key]=source end
          end
          add(1,nil,false)
          add(2,{type="quest",requiredLevel=60},true)
          add(3,{type="boss",npc=20,instance=99},false)
          add(4,{type="dungeonTrash",instance=40},false)
          add(5,{type="boss",npc=10,instance=30},false)
          add(6,{type="creature",npc=20},true)
          add(7,{type="quest",requiredLevel=30},false)
          add(8,{type="object",map=1429},false)
          add(9,{type="vendor",map=1429,npc=20},false)
          ns.lootData.items[9].restrictions={text="Requires Revered"}
        ''')
        lua.globals().load_module((ROOT/'LootCatalog.lua').read_text())
        lua.execute('''
          local L=ns.loot
          local now=L.candidates({})
          assert(now.total==2 and now.rows[1].item.id==5 and now.rows[2].item.id==7)
          local later=L.candidates({maxLevel=60,search="3"})
          assert(later.total==1 and later.rows[1].futureLevel==60)
          assert(L.candidates({search="1",showUnverified=true}).rows[1].availabilityUnverified)
          assert(L.candidates({search="2",showUnverified=true}).total==0)
          assert(L.candidates({search="8",source="object",showUnverified=true}).rows[1].availabilityUnverified)
          assert(L.candidates({search="1",source="vendor",showUnverified=true}).total==0)
          assert(L.candidates({search="9",showUnverified=true}).rows[1].availabilityUnverified)
        ''')

if __name__=='__main__': unittest.main()
