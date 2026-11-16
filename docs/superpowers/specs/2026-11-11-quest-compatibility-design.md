# Quest compatibility design summary

The optional integrations coordinate automation, tracker placement and objective guidance.
The addon remains usable when either provider is missing or still loading.

## Automation

Read automation settings when interacting with an NPC. The external tracker's enabled
quest automation takes precedence, so only one implementation handles the interaction.
Alt and the configured provider modifier hold automation back. The same coordination
applies to enabled party announcements; ordinary party messages are untouched.

## Step window

A player-saved position wins. Otherwise, place the window beside the external tracker,
on the side facing the middle of the screen. Follow later moves, clamp to the display,
and leave secure controls alone during combat.

## Objective guidance

Use a public, versioned data contract without bundling a third-party spawn database.
Map the provider's area IDs to native map IDs. Within a quest camp, show the nearest
unfinished creature or object; item objectives use their drop sources. Ignore recently
cleared spawns briefly. Preserve localized client names and turn guidance off safely
when a provider read fails.

## Presentation and verification

Settings, debug output and documentation use generic provider descriptions. Exact API
symbols, dependency entries and saved keys remain in executable adapter code. Test the
full and minimal clients, missing or late providers, alternate settings, localization,
tracker movement, map boundaries, recently cleared spawns and combat restrictions.
