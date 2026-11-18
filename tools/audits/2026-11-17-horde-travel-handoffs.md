# Horde travel handoffs

Reviewed the 70 main and alternate Horde chapters at `73fd522` for travel steps that point back to departure and for guide switches while following a trip. The full Horde catalog contains 174 inbound travel rows. Simulated arrivals for all 20 boats, zeppelins, and airships in the main and alternate routes using the WoW client mock.

## Reproduced

| Route | Reproduction | Result |
| --- | --- | --- |
| Grom'gol to Stonard | At level 50, follow **The Basilisk's Bite** with **Cortello's Riddle** (624) still ready. Take the arrow's flight to Stonard for the Blasted Lands turn-in. | The guide keeps the Basilisk turn-in in flight. On landing it switches to the older Swamp of Sorrows chapter and sends you to the soggy scroll. |
| Ratchet to Booty Bay | At level 50, take the boat from the end of **Feralas and Un'Goro** or the opening of **Booty Bay, Stonard and the Blasted Lands** with **Deliver to MacKinley** ready. | The guide advances to MacKinley on arrival. Following the boat card's instruction to press Next after landing marks the turn-in skipped and opens **Booty Bay auction house**. Both entry points produce the same saved skip. |
| Orgrimmar to Tirisfal | Follow the zeppelin in **Silverpine: The Sepulcher**, **Alterac Mountains and Arathi Highlands**, **The Hinterlands: Revantusk Village and Jintha'alor**, or **Plaguelands: the Bulwark and Tirion Fordring**. Land outside Brill and walk into the Undercity. | The departure step stays current until Next. While already in Tirisfal or the Undercity, the arrow says to take the zeppelin back to Durotar from the tower outside Brill. The Sepulcher, Arathi, and Hinterlands instructions also omit when to press Next. |
| Starting a chapter after docking in Tirisfal | At the landing tower, select **Tirisfal and Silverpine**, **Silverpine: The Sepulcher**, **Alterac Mountains and Arathi Highlands**, or **Plaguelands: the Bulwark and Tirion Fordring**. | Each starts with the zeppelin from Durotar even though the character is at its Tirisfal destination. This also reproduces in Arathi with **Thundering Hearts** ready and in Plaguelands with **Delivery to Andron Gant** ready. |

The Stonard switch comes from `resumeLocal` in `Quests.lua`. It can choose a quest in the arrival zone even while the active quest is the reason for the trip. The Booty Bay result comes from two arrival paths. Starting the destination chapter locally or automatically passing its inbound boat can put the delivery on screen before the player presses Next. The Tirisfal rows point at their departure tower, and their chapters use other zones as their home maps. They have no arrival gate for Tirisfal or the Undercity.

When testing a shared fix, preserve deliberate chapter handoffs. For example, the final zeppelin in **Feralas: Camp Mojache and the Gordunni** leads directly to the opening Stranglethorn pickups on arrival at Grom'gol.

## Verification

- All 17 selected Horde and shared travel scenarios passed, including the five Horde starts, `questHordeSilverpine`, `questHordeStranglethorn`, `questZoneResume`, and `questFlightMorbent`.
- The offline Horde route data audit returned zero errors and 77 warnings. The arrival findings came from the client mock.
- In game, check Stonard with both turn-ins ready. At Booty Bay, look at the active step before pressing Next. After the zeppelin, check the arrow both at the Tirisfal landing tower and inside the Undercity.
