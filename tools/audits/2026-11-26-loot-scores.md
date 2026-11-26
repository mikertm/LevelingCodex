# Loot scores audit (2026-11-26)

Owner report: most gear tooltips said "Codex: Score unavailable". (The "Not ranked at your level"
and "Arms: Not ranked for your level" lines in the same screenshot are GearQuestForever's, not ours.)

## Why scores were missing
- `tools/lootdata.py` read Equip percentages as whole numbers only (`(\d+)%`). Forever writes
  "1.0%", so every crit/hit/dodge item kept the line as an unresolved effect: 1,682 lines.
  Forever's "Increases healing done by up to X and damage done by up to Y" wasn't read either.
- Any unresolved effect, set membership, enchant or gem on the item or on the equipped item made
  the comparison "provisional", which the tooltip showed as "Score unavailable".
- Random-suffix items without their suffix, unknown proficiencies (a weapon not trained yet, or a
  skill list the client didn't give) and off-hands behind a two-hander were blanks too.
- Items above your level only said "Cannot equip".

## Changes
- `lootdata.py resolve` re-reads the reference's unresolved Equip lines offline (`resolve_equip`,
  also used by `parse_tooltip`): 985 class 2/4 items still carry a real effect (Use, Chance on
  hit, set), down from 2,421.
- `L.score` returns `notes` (what the score leaves out) besides `warnings` (what stops it).
  `L.compare` gives a scored result `confidence = "complete"` with `estimate = true` and `notes`;
  only unknown stats, unknown weapon damage or unreadable equipment still stop a score.
- `L.eligible` falls back to class rules (armor by class and level 40, class weapon lists,
  shields, dual wield at 20) and turns an untrained weapon into a note.
- `r.future` = the rating at the item's required level (`L.compareSlots(..., skipLevel)`).
- Tooltip: "Codex: Upgrade: about +6.2% gear score | Rank #3" plus a detail line (what it
  replaces, what isn't counted, the profile).
- Weights: Tank parry 6, block 4, hit 4, crit 2; Healer spellCrit 5; Caster spellPen 0.4; a small
  armor weight for casters and ranged so an armor-only piece isn't a zero.

## Second pass (same day)
Every class run through `L.compare` at levels 12, 25, 40 and 55 against a median green set from
a few levels below (eligible items only), tallying verdicts, reasons, notes and zero scores.
- Wands scored their stats only (`weapon.ranged` is 0 for casters): `weapon.wand` (Caster 1,
  Healer 0.5 per DPS), used for weapon subclass 19.
- Relics had no class check (classMask 32767 on many): subclass 7 libram = Paladin, 8 idol =
  Druid, 9 totem = Shaman.
- 1,365 items carry `sp` without `heal`: the classic "damage and healing done by magical spells"
  line. `L.score` counts that spell power at the healing weight too, unless the client's tooltip
  says spell damage only (`item.spDamageOnly`, LootItems.lua). Forever's own healing gear lists
  `heal` separately (about 3 x `sp`), so it isn't doubled.
- Zero scores said "No stats your build uses" whatever the cause: `L.noValueReason` tells an
  effects-only trinket, resistances only, no stats listed (the reference dropped some relic and
  neck lines: no Forever tooltip cache to re-read) and an unrolled random bonus apart.
- Resistances (`RESISTANCE1_NAME`..`6`) are read from `GetItemStats` as `resHoly`..`resArcane`
  (weight 0, shown in the stat comparison). The reference has none: `parse_tooltip` drops the
  lines; a refetch would need the Forever tooltip source, which this environment can't reach.
- A worn item's enchant: "You'd lose the enchant on <name>" instead of "Equipped item's effects
  not counted".
- Left as is: an off-hand behind a two-hander still says "Pair it with a one-hand weapon in
  place of your two-hander" (no one-hander to pair it with); low-level percentages run large
  because the whole set's score is small.
