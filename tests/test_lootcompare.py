"""Pure equipment/configuration tests. Game API behavior is tested in scenarios.lua."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class LootCompareTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('ns={loot={}}; function load_module(s) assert(loadstring(s))("LevelingCodex",ns) end')
        path = ROOT/'LootCompare.lua'
        self.assertTrue(path.exists(), 'equipment comparison engine is missing')
        self.lua.globals().load_module(path.read_text())
        self.lua.execute('''
          L=ns.loot
          function item(id,str,slot)
            return {id=id,key=tostring(id),name="Gear",slot=slot or "INVTYPE_CHEST",requiredLevel=1,
              classID=4,subclassID=1,stats={str=str},restrictions={},effects={},state="ready",
              complete={stats=true,restrictions=true,effects=true}}
          end
          function ctx()
            return {class="WARRIOR",race="Human",faction="Alliance",level=60,
              profile={weights={str=1},weapon={melee=1,ranged=0,feral=false}},
              proficiencies={armor=4,dualWield=true,shield=true,weapons={[7]=true}},
              snapshot={slots={[5]=item(1,100),[11]=item(2,50,"INVTYPE_FINGER"),
                [12]=item(3,75,"INVTYPE_FINGER"),[16]=item(4,50,"INVTYPE_WEAPON"),
                [17]=item(5,30,"INVTYPE_SHIELD")},equipmentKnown=true}}
          end
        ''')

    def test_deadband_and_empty(self):
        self.lua.execute('''
          for _,v in ipairs({{102,"upgrade"},{101,"sidegrade"},{99,"sidegrade"},{98,"downgrade"}}) do
            assert(L.compare(item(10,v[1]),ctx()).verdict==v[2], v[2])
          end
          local c=ctx(); c.snapshot.slots[5]=false
          local r=L.compare(item(10,1),c); assert(r.verdict=="upgrade" and r.percent==nil)
          c.snapshot.slots[5]=item(1,0); assert(L.compare(item(10,0),c).verdict=="needsReview")
        ''')

    def test_paired_slots_unique_and_hands(self):
        self.lua.execute('''
          local c=ctx(); local r=L.compare(item(9,60,"INVTYPE_FINGER"),c)
          assert(r.verdict=="upgrade" and r.replacedSlots[1]==11)
          local i=item(9,90,"INVTYPE_FINGER"); i.restrictions.unique="u"
          c.snapshot.slots[12].restrictions.unique="u"
          r=L.compare(i,c); assert(r.replacedSlots[1]==12)
          r=L.compare(item(10,70,"INVTYPE_2HWEAPON"),ctx())
          assert(r.verdict=="downgrade" and #r.replacedSlots==2)
          c=ctx(); c.snapshot.slots[16]=item(8,90,"INVTYPE_2HWEAPON"); c.snapshot.slots[17]=false
          assert(L.compare(item(10,60,"INVTYPE_WEAPON"),c).verdict=="needsReview")
        ''')

    def test_restrictions_and_unknowns(self):
        self.lua.execute('''
          local i=item(9,110); i.requiredLevel=61
          assert(L.compare(i,ctx()).verdict=="cannotEquip")
          i.requiredLevel=1; i.restrictions.classes={"MAGE"}
          assert(L.compare(i,ctx()).verdict=="cannotEquip")
          i.restrictions={}; i.complete.effects=false
          assert(L.compare(i,ctx()).verdict=="needsReview")
          i.complete.effects=true; i.complete.stats=false
          assert(L.compare(i,ctx()).verdict=="needsReview")
          i.complete.stats=true; local c=ctx(); c.snapshot.slots[5]=nil
          assert(L.compare(i,c).verdict=="needsReview")
        ''')

    def test_feral_weapon_and_set(self):
        self.lua.execute('''
          local c=ctx(); c.profile.weapon.feral=true
          local i=item(9,100); i.damage=10000
          assert(L.compare(i,c).verdict=="sidegrade")
          i.restrictions.set=1
          assert(L.compare(i,c).verdict=="needsReview")
        ''')

    def test_unknown_proficiency_is_not_a_known_rejection(self):
        self.lua.execute('''
          local c=ctx();c.proficiencies={armor=1,armorKnown=false,weapons={},weaponKnown=false}
          local i=item(9,100);i.subclassID=4
          assert(L.compare(i,c).verdict=="needsReview")
        ''')

    def test_target_variants_and_partial_bags(self):
        path = ROOT/'LootTargets.lua'
        self.assertTrue(path.exists(), 'target tracking is missing')
        self.lua.execute('''
          saved={}; ns.charDB=function() return saved end
          snapshot={slots={},bagLinks={},bagsKnown=true,equipmentKnown=true}
          L.snapshot=function() return snapshot end
          L.item=function(ref) return {id=123,key=ref,link=ref,name=ref} end
          L.subscribe=function(f) onrefresh=f end
        ''')
        self.lua.globals().load_module(path.read_text())
        self.lua.execute('''
          local a=L.track("item:123:0:1"); local b=L.track("item:123:0:2")
          assert(a~=b and #L.targets()==2)
          snapshot.bagLinks["item:123:0:1"]=1; L.refreshTargets()
          assert(L.targets("obtained")[1].key==a)
          snapshot.bagsKnown=false; snapshot.bagLinks={}; L.refreshTargets()
          assert(#L.targets("obtained")==1)
          assert(L.setTargetState(a,"tracked")); assert(#L.targets("tracked")==2)
          assert(L.setTargetState(a,"dismissed")); assert(L.setTargetState(a,"tracked"))
        ''')


if __name__ == '__main__':
    unittest.main()
