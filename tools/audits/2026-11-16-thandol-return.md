# Thandol Span return directions

Owner reported that quest 633's turn-in incorrectly instructed a swim beneath
the bridge. Changed only its return text in QuestData.lua: cross the bridge
south into the Wetlands, then take the road south to Rhag's Dun Modr camp.
The destination remains 49.92, 18.21. No Data.lua changes.

Added a check to the Wetlands scenario; it failed on the old swimming direction.
This corrects the return after the explosives/letter steps, not the earlier
river visit for the letter.
