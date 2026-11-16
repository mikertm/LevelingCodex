# Quest compatibility implementation summary

Historical implementation notes for the optional quest-tracker and quest-data integrations.

1. Read the provider's automation settings at call time. Let its enabled auto-accept,
   auto-complete and announcement options take precedence, and respect its modifier key.
2. Place the step window beside the external tracker until the player saves a position.
   Recheck late-created or moved trackers, preserve screen bounds, and defer secure changes
   until combat ends.
3. Read the optional quest-data provider through its public contract. Guard missing APIs,
   compile zone mappings in an empty environment, and retry startup failures once.
4. Near a quest camp, find the nearest unfinished objective on the current map. Resolve
   item objectives through their drop sources and briefly avoid recently visited spawns.
5. Expose generic integration settings and debug status. Keep exact dependency names,
   global symbols and saved keys in the adapter code where interoperability requires them.
6. Exercise missing providers, older settings, late startup, moved trackers, unreadable
   data, localization and combat using the headless client scenarios.

The integration adapter and the test harness are the source of truth for exact API
identifiers. This summary does not change the shipped integration behavior.
