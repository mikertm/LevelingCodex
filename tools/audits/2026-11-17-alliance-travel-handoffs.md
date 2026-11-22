# Alliance travel handoffs

Reviewed the 63 main and alternate Alliance chapters at `73fd522` for travel steps that return after arrival and for guide switches while following a route. The route scan found 67 inbound travel rows across the full Alliance catalog. Simulated arrivals for all 20 boat and ferry steps in the main and alternate routes using the WoW client mock.

## Reproduced

| Route | Reproduction | Result |
| --- | --- | --- |
| Darkshire to Sentinel Hill | At level 31, follow **Armed and Ready** from Darkshire with **Red Leather Bandanas** also ready in the log. Fly to Sentinel Hill. | The guide keeps **Armed and Ready** during the flight, then switches to the Westfall turn-in on landing. |
| Darkshore to Menethil Harbor | Follow Darkshore's ship from Auberdine at level 20 with **The Absent Minded Prospector** (942) ready. Land in Menethil before pressing Next. | The early Wetlands guide opens on **Flight path — Menethil Harbor**. The fossil turn-in remains in Ready to turn in. |
| Menethil Harbor to Theramore | Follow **Theramore and the Shimmering Flats** at level 33. Land in Theramore before pressing Next. | The optional **Theramore and the Marsh** guide opens. Starting **Theramore and the Shimmering Flats** again while at the dock shows the ship from Menethil. |
| Ratchet to Booty Bay | Follow the Tanaris and Un'Goro chapter at level 50 with **Deliver to MacKinley** and **Rescue OOX-17/TN!** ready. Land in Booty Bay before pressing Next. | The Pirates and Princess Poobah chapter opens on **The Captain's Chest**. Both deliveries remain in Ready to turn in and appear later in the new chapter. |

The switch comes from `resumeLocal` in `Quests.lua`. On zone entry it can favor a ready quest or an eligible chapter in the arrival zone. The guard checks the route step's map. An intermediate flight stop is outside the quest's map, and a boat row's map points at the departure pier. The Theramore restart has a second cause. The inbound boat is skipped automatically in the chapter's home zone, Thousand Needles, but has no arrival gate for Theramore.

A follow-up can protect an active guided trip through arrival, then let the route continue with its own steps. Keep the existing catch-up behavior when the player independently enters another zone. The Theramore crossing also needs to recognize that the player is already at the arrival stop when the chapter is started there.

## Verification

- All 15 existing flight, zone-entry, and chapter-handoff scenarios selected for this audit passed, including `questFlightMorbent`, `questFlightBack`, `questZoneResume`, `questWetlandsEnd`, and `questDuskwoodZoneEntry`.
- The offline Alliance route data audit returned zero errors and 259 warnings. The arrival findings above came from the client mock.
- In game, check arrival before pressing Next on the three ships above. For Sentinel Hill, keep an unrelated Westfall turn-in ready alongside **Armed and Ready**.

## Sentinel Hill reload in v0.28.1

After a reload at Sentinel Hill, the level 30–32 Darkshire chapter showed the Auberdine ship with Jungle Secrets immediately ahead. The ship only skipped on the Stormwind destination, and Sentinel Hill is on the Westfall map. The Darkshire departure now skips the ship on the nearby Eastern Kingdoms maps. The Stranglethorn approach points from Westfall to the east bridge into Duskwood, then down the southern road to Rebel Camp. The Jungle Secrets pickup carries the same directions for players whose progress already passed the travel step. [Westfall map](https://wow.zamimg.com/images/wow/maps/enus/original/40.jpg) · [Duskwood map](https://wow.zamimg.com/images/wow/maps/enus/original/10.jpg)

The reload scenario failed on `v0.28.1` and passed with the updated route. It walks through both borders to Thorsen's pickup. The existing Wetlands scenario still offers the ship after the Nord'el delivery in Auberdine, and the Sven flight handoff still passes at Sentinel Hill.
