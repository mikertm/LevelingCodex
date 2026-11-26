from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LootHintTests(unittest.TestCase):
    def test_enemy_tooltips_only_show_native_text(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          callbacks={}; unit="Vendor"
          GameTooltip={lines={},HookScript=function(self,event,fn) callbacks[event]=fn end,
            AddLine=function(self,s) self.lines[#self.lines+1]=s end,
            GetUnit=function() return unit,"mouseover" end}
          function UnitGUID() return "Creature-0-1-2-3-"..(unit=="Vendor" and "42" or "43").."-ABC" end
          function UnitCanAttack() return unit~="Vendor" end
          ns={lootData={byCreature={[42]={"vendor"},[43]={"drop"}},sources={
            vendor={item=1,type="vendor"},drop={item=1,type="creature"}},
            items={[1]={id=1,name="Stock"}}},db=function() return {} end,plain=tostring,
            loot={call=function(f,...) if f then return f(...) end end,
              compare=function() return {verdict="upgrade"} end,labels={upgrade="Upgrade"}}}
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        lua.globals().load_module((ROOT/'LootHints.lua').read_text())
        lua.execute('''
          ns.loot.refreshHints();callbacks.OnTooltipSetUnit(GameTooltip)
          assert(#GameTooltip.lines==1 and GameTooltip.lines[1]:find("Codex vendor:",1,true))
          GameTooltip.lines={"Kobold","Level 8"}
          unit="Kobold";callbacks.OnTooltipSetUnit(GameTooltip)
          assert(#GameTooltip.lines==2 and GameTooltip.lines[1]=="Kobold" and GameTooltip.lines[2]=="Level 8",
            "enemy tooltips retain their native text without a loot list")
        ''')

    def test_tooltip_dedup_and_pending_reward_has_no_best_marker(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={loot={version=1,call=function(f,...) if f then return f(...) end end,
            context=function() return {} end,catalogRank=function() end,
            labels={upgrade="Upgrade"},item=function(ref) return {id=1,key=ref,name="Item",slot="INVTYPE_CHEST",classID=4} end,
            compare=function() return {verdict="upgrade",delta=3,percent=5,confidence="complete"} end},
            db=function() return {} end,plain=tostring}
          tip={lines={},AddLine=function(self,s) self.lines[#self.lines+1]=s end}
          function GetNumQuestChoices() return 2 end
          function GetQuestItemLink(_,i) if i==1 then return "item:1" end end
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        p=ROOT/'LootHints.lua';self.assertTrue(p.exists(),'loot hints are missing')
        lua.globals().load_module(p.read_text())
        lua.execute('''
          ns.loot.annotate(tip,"item:1"); ns.loot.annotate(tip,"item:1")
          assert(#tip.lines==1 and tip.lines[1]:find("Codex: Upgrade: +5.0% gear score",1,true))
          local r=ns.loot.rewardAdvice(); assert(r.state=="pending" and not r.bestChoice)
          function GetQuestItemLink(_,i) return "item:"..i end
          r=ns.loot.rewardAdvice(); assert(r.state=="complete" and r.bestChoice==1)
        ''')

if __name__=='__main__': unittest.main()
