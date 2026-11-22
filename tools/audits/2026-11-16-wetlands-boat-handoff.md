# Wetlands to Darkshire boat handoff

The owner reached the Wetlands chapter's Stormwind-to-Auberdine boat step with
no remaining Auberdine turn-in shown, immediately followed by Darkshire's
Auberdine-to-Stormwind boat. The outgoing travel was unconditional even though
quest catch-up could already have passed its destination delivery.

- Gate the Wetlands outgoing boat on carrying 98209, Bloom of the Heavens.
  Players actually carrying Nord'el still receive the existing delivery trip.
- Mark Darkshire's return boat passed once in Stormwind, using the existing
  skipOn gate. Players already in Auberdine still receive the return crossing.
- Leave the actual delivery and planned Blackfathom quest steps intact.
- Add a check to questWetlandsEnd; it failed before the outgoing gate and
  passed afterward. Existing scenario retains the real delivery/return case.
- No Data.lua changes. The prior Thandol return correction remains included.
