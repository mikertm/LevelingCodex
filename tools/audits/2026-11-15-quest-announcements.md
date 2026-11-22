# Quest announcement polish

The owner requested graphical party announcements before publishing v0.26.0.
Reviewed the installed Forever quest tracker's `Modules/quest trackerAnnounce.lua`,
`Modules/QuestLinks/Link.lua`, and `Modules/EventHandler/QuestEventHandler.lua`:
it sends a standard raid marker and formats the logo locally through a chat
filter; `questAnnounceCompleted` refers to turn-in, not readiness.

## Changes

- Party messages use a moon marker, explicit status, progress counts and native
  quest/item hyperlinks supplied by the client. Link validation preserves the
  original ID and payload; unavailable links fall back to readable labels.
- Codex recipients render a Level 60 badge and colored status icons. Other
  clients receive the standard marker, status and native links. Custom texture
  escapes stay local. Turn-ins use a check; ready quests use a question mark.
- Cache native quest links for the session so removing a quest at turn-in does
  not lose its link. No persistence is required.
- Enforce the 255-byte chat limit without cutting hyperlinks or UTF-8 text.
- Settings and Quests > Party offer a private graphical preview. Previewing
  neither enables announcements nor sends a party message.
- Keep announcement opt-ins, one-line-per-second queue, coalesced updates,
  login quiet time, and raid exclusion. Respect quest tracker's accepted and turned-in
  switches in addition to its objective/item switches.
- Chat filter registration is guarded, with bounded retry for clients whose
  chat filters are not ready at login; absent APIs keep readable party messages.

## Verification

Harness scenarios cover native links after turn-in, sender/metadata preservation,
unrelated chat, private previews from both UI locations, minimal APIs, oversized
messages, quest tracker duplicate suppression, and the existing queue/raid/quiet rules.
No `Data.lua` changes. In game, use the private preview and then verify party
announcements with a consenting party member; no live chat was sent during tests.
