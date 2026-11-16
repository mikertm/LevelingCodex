from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LootHintTests(unittest.TestCase):
    def test_tooltip_dedup_and_pending_reward_has_no_best_marker(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={loot={version=1,call=function(f,...) if f then return f(...) end end,
            labels={upgrade="Upgrade"},item=function(ref) return {id=1,key=ref,name="Item",slot="INVTYPE_CHEST",classID=4} end,
            compare=function() return {verdict="upgrade",delta=3,percent=5,reason="Good stats"} end,
            enchants=function() return {} end},db=function() return {} end,plain=tostring}
          tip={lines={},AddLine=function(self,s) self.lines[#self.lines+1]=s end}
          function GetNumQuestChoices() return 2 end
          function GetQuestItemLink(_,i) if i==1 then return "item:1" end end
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        p=ROOT/'LootHints.lua';self.assertTrue(p.exists(),'loot hints are missing')
        lua.globals().load_module(p.read_text())
        lua.execute('''
          ns.loot.annotate(tip,"item:1"); ns.loot.annotate(tip,"item:1")
          assert(#tip.lines==3 and tip.lines[1]:find("Upgrade",1,true))
          local r=ns.loot.rewardAdvice(); assert(r.state=="pending" and not r.bestChoice)
          function GetQuestItemLink(_,i) return "item:"..i end
          r=ns.loot.rewardAdvice(); assert(r.state=="complete" and r.bestChoice==1)
        ''')

if __name__=='__main__': unittest.main()
