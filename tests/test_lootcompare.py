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
          c.snapshot.slots[5]=item(1,0); r=L.compare(item(10,0),c); assert(r.verdict=="sidegrade" and r.noValue, "nothing the build uses says so")
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
          r=L.compare(item(10,60,"INVTYPE_WEAPON"),c)
          assert(r.verdict=="downgrade" and r.estimate and r.replacedSlots[1]==16, "a one-hander is rated against the two-hander")
          r=L.compare(item(11,60,"INVTYPE_SHIELD"),c)
          assert(r.verdict=="needsReview" and r.reason:find("one-hand weapon",1,true), "an off-hand behind a two-hander says why")
        ''')

    def test_restrictions_and_unknowns(self):
        self.lua.execute('''
          local i=item(9,110); i.requiredLevel=61
          local r=L.compare(i,ctx())
          assert(r.verdict=="cannotEquip" and r.future and r.future.level==61 and r.future.verdict=="upgrade", "a future item is rated for its level")
          i.requiredLevel=1; i.restrictions.classes={"MAGE"}
          r=L.compare(i,ctx())
          assert(r.verdict=="cannotEquip" and not r.future)
          i.restrictions={}; i.complete.effects=false; i.warnings={"Use: Does a thing."}
          r=L.compare(i,ctx())
          assert(r.verdict=="upgrade" and r.estimate and r.notes[1]=="Use effect not counted", "an effect makes an estimate, not a blank")
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
          local r=L.compare(i,c)
          assert(r.verdict=="sidegrade" and r.estimate and r.notes[1]=="Set bonus not counted")
        ''')

    def test_unknown_proficiency_is_not_a_known_rejection(self):
        self.lua.execute('''
          local c=ctx();c.proficiencies={armor=1,armorKnown=false,weapons={},weaponKnown=false}
          local i=item(9,110);i.subclassID=4
          assert(L.compare(i,c).verdict=="upgrade", "a level 60 warrior wears plate")
          c.level=30; local r=L.compare(i,c)
          assert(r.verdict=="cannotEquip" and r.reason=="Armor proficiency required")
          c.class="MAGE"; c.level=60; assert(L.compare(i,c).verdict=="cannotEquip")
          c.class="UNKNOWN"; r=L.compare(i,c); assert(r.verdict=="upgrade" and r.estimate)
          c=ctx(); c.level=30; i.requiredLevel=40
          r=L.compare(i,c); assert(r.verdict=="cannotEquip" and r.future and r.future.verdict=="upgrade", "plate is rated for level 40")
          local w=item(12,110,"INVTYPE_WEAPONMAINHAND"); w.classID=2; w.subclassID=1; w.damage=10
          r=L.compare(w,ctx()); assert(r.verdict=="upgrade" and r.estimate and r.notes[1]:find("rain",1,true), "an untrained weapon says to train it")
          w.subclassID=19; assert(L.compare(w,ctx()).verdict=="cannotEquip", "a warrior can't use a wand")
        ''')

    def test_unread_equipment_snapshot_never_uses_stale_gear_conclusively(self):
        self.lua.execute('''
          local c=ctx();c.snapshot.equipmentKnown=false
          assert(L.compare(item(9,110),c).verdict=="needsReview")
        ''')

    def test_unknown_paired_slot_prevents_a_false_downgrade(self):
        self.lua.execute('''
          local c=ctx();c.snapshot.slots[11]=item(1,100,"INVTYPE_FINGER");c.snapshot.slots[12]=nil
          assert(L.compare(item(9,90,"INVTYPE_FINGER"),c).verdict=="needsReview")
          c.snapshot.slots[12]=false
          assert(L.compare(item(9,90,"INVTYPE_FINGER"),c).verdict=="upgrade")
        ''')

    def test_same_cached_unique_item_cannot_fill_a_second_slot(self):
        self.lua.execute('''
          local c=ctx();local i=item(9,90,"INVTYPE_FINGER");i.restrictions.unique="u"
          c.snapshot.slots[11]=i;c.snapshot.slots[12]=item(2,10,"INVTYPE_FINGER")
          local r=L.compare(i,c)
          assert(r.verdict=="sidegrade" and r.replacedSlots[1]==11)
        ''')

    def test_unknown_weapon_damage_cannot_get_a_conclusive_score(self):
        self.lua.execute('''
          local c=ctx();local i=item(9,100,"INVTYPE_WEAPONMAINHAND");i.classID=2;i.subclassID=7
          assert(L.compare(i,c).verdict=="needsReview")
          i.damage=10
          assert(L.compare(i,c).verdict=="upgrade")
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
          snapshot.bagsKnown=true;snapshot.bagLinks["item:123:0:1"]=1
          assert(L.setTargetState(a,"tracked")); assert(#L.targets("tracked")==2)
          L.refreshTargets(); assert(#L.targets("tracked")==2,"explicit restore survives an ownership refresh")
          snapshot.bagLinks={};L.refreshTargets()
          snapshot.bagLinks["item:123:0:1"]=1;L.refreshTargets()
          assert(#L.targets("obtained")==1,"a later acquisition still completes the target")
          assert(L.setTargetState(a,"dismissed")); assert(L.setTargetState(a,"tracked"))
        ''')


if __name__ == '__main__':
    unittest.main()
