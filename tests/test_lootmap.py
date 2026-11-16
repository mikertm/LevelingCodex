from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LootMapTests(unittest.TestCase):
    def test_map_owned_separately_and_unknown_location_not_fabricated(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          ns={lootData={sources={vendor={id="vendor",map=1429,x=40,y=50,name="Vendor"},
            unknown={id="unknown",name="Unknown"}}},loot={call=function(f,...) if f then return f(...) end end}}
          quest=123; progress=0; C_Map={SetUserWaypoint=function(p) waypoint=p end,
            CanSetUserWaypointOnMap=function() return true end,ClearUserWaypoint=function() waypoint=nil end}
          function OpenWorldMap(m) opened=m end
          function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end
        ''')
        p=ROOT/'LootMap.lua';self.assertTrue(p.exists(),'loot mapping is missing')
        lua.globals().load_module(p.read_text())
        lua.execute('''
          assert(not ns.loot.showSourceOnMap("unknown")); assert(waypoint==nil)
          assert(ns.loot.showSourceOnMap("vendor")); assert(opened==1429)
          assert(waypoint.position.x==0.4 and quest==123 and progress==0)
          assert(ns.loot.mapTarget().sourceID=="vendor")
          ns.loot.clearMapTarget(); assert(ns.loot.mapTarget()==nil and waypoint==nil)
        ''')

if __name__=='__main__': unittest.main()
