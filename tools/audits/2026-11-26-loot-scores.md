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
