from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class LootItemTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          ns={lootData={items={},sources={}},plain=tostring,after=function(t,f) jobs[#jobs+1]=f end,
            charDB=function() return {} end}; jobs={}; stats={}; equipped={}; bags={}; requests=0
          function UnitClass() return "Warrior","WARRIOR" end
          function UnitRace() return "Human","Human" end
          function UnitLevel() return 30 end
          function UnitFactionGroup() return "Alliance" end
          function GetInventoryItemLink(u,s) return equipped[s] end
          C_Container={GetContainerNumSlots=function(b) return b==0 and #bags or 0 end,
            GetContainerItemInfo=function(b,s) return bags[s] and {hyperlink=bags[s]} end}
          C_Item={GetItemStats=function(link) return stats[link] end,
            RequestLoadItemDataByID=function() requests=requests+1 end}
          ns.itemInfo=function(link)
            if not stats[link] then return end
            return "Test",link,2,20,1,"Armor","Cloth",1,"INVTYPE_CHEST",134400,0,4,1
          end
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        for name in ('Loot.lua','LootItems.lua'):
            p=ROOT/name
            self.assertTrue(p.exists(), name+' is missing')
            self.lua.globals().load_module(p.read_text())

    def test_reads_exact_links_and_requests_once(self):
        self.lua.execute('''
          stats["item:1:0:1"]={ITEM_MOD_STRENGTH_SHORT=2}
          stats["item:1:0:2"]={ITEM_MOD_STRENGTH_SHORT=5}
          assert(ns.loot.item("item:1:0:1").stats.str==2)
          assert(ns.loot.item("item:1:0:2").stats.str==5)
          assert(ns.loot.item(2).state=="loading"); ns.loot.item(2); assert(requests==1)
        ''')

    def test_retries_are_bounded_and_late_success_refreshes(self):
        self.lua.execute('''
          ns.loot.item(3)
          for n=1,10 do local f=table.remove(jobs,1); if f then f() end end
          assert(requests<=4 and ns.loot.item(3).state=="unavailable")
          stats["item:3"]={ITEM_MOD_STAMINA_SHORT=4}
          ns.loot.refresh("item-data")
          assert(ns.loot.item(3).stats.sta==4)
        ''')

    def test_partial_snapshot_is_not_empty(self):
        self.lua.execute('''
          stats["item:1"]={ITEM_MOD_STRENGTH_SHORT=4}; equipped[5]="item:1"; bags[1]="item:1"
          local s=ns.loot.snapshot(); assert(s.slots[5].id==1 and s.bagLinks["item:1"]==1)
          C_Container.GetContainerNumSlots=function() error("not ready") end
          ns.loot.refresh("bags")
          s=ns.loot.snapshot(); assert(s.bagLinks["item:1"]==1 and not s.bagsKnown)
        ''')

    def test_non_catalog_tooltip_distinguishes_plain_stats_from_procs(self):
        self.lua.execute('''
          stats["item:99"]={ITEM_MOD_STRENGTH_SHORT=10}
          C_TooltipInfo={GetHyperlink=function() return {lines={{leftText="+10 Strength"}}} end}
          local i=ns.loot.item(99); assert(i.complete.effects and i.complete.restrictions)
          C_TooltipInfo.GetHyperlink=function() return {lines={{leftText="Use: Turns you into a chicken"}}} end
          ns.loot.refresh("tooltip changed")
          assert(not ns.loot.item(99).complete.effects)
        ''')

    def test_link_context_does_not_change_ownership_identity(self):
        self.lua.execute('''
          local a=ns.loot.itemKey("item:123:0:0:0:0:0:42:0:20:0")
          local b=ns.loot.itemKey("item:123:0:0:0:0:0:42:0:30:0")
          assert(a==b)
          assert(a~=ns.loot.itemKey("item:123:0:0:0:0:0:43:0:30:0"))
        ''')


if __name__=='__main__': unittest.main()
