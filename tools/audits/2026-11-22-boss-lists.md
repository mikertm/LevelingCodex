# Boss lists: Alliance parity and shared instances

## Changes

- **Alliance Stratholme** (`QuestDungeonData3060.lua`): adds Ezra Grimm (encounter 2797, after The Unforgiven: his
  smoke shop is on the living side and The Great Ezra Grimm needs his tobacco) and Magistrate Barthilas (482, after
  Balnazzar, at the way into the dead side). Before: 10 bosses. After: 12.
- **Alliance Scholomance**: adds Marduk Blackpool (2809) and Vectus (2813) after Rattlegore, on the Viewing Room
  balcony. Before: 11 bosses. After: 13.
- **Horde**: the Horde Stratholme and Scholomance guides copied the Alliance lists and inserted these four rows
  themselves (`tools/audits/2026-11-12-horde-dungeons-45-60.md`). They now come from the Alliance lists, so both
  factions show the same bosses in the same order and the tips are written once.

## Audit

`questroute.py audit` warned about every encounter of a shared instance that a guide doesn't list, so each
Scarlet Monastery, Dire Maul and Blackrock Spire wing listed the other wings' bosses. It now leaves out encounters
another guide for the same instance lists. Warnings left, all rare, summoned or event encounters on purpose:
Mana Wraith (City of Dalaran), the Lordaeron Captain, Blackrock Depths' Grebmar, Stilgiss, Phalanx, Plugger, The
Vault and Princess Moira (she must live for The Princess Saved?), Halycon and Lord Valthalak, Lord Hel'nurath and
Tsu'zee, Kormok, and Stratholme's rares and summons (Hearthsinger Forresten, Malor, the Swordsmith, the
Hammersmith, Postmaster Malown, Skul, Stonespine).

## Check in game

- An Alliance Stratholme run: Ezra Grimm and Magistrate Barthilas tick off when they die.
- An Alliance Scholomance run: Marduk Blackpool and Vectus tick off when they die.
