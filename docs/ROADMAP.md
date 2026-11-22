# Roadmap

## Sprint 1 — Foundation and playable shell
- [x] Define architecture decisions.
- [x] Add Godot project and main scene.
- [x] Add player movement and collision.
- [x] Add neighborhood prototype.
- [x] Add dedicated combat arena and scene transition.
- [x] Add local save scaffolding.
- [ ] Run Godot editor import and runtime validation.
- [ ] Validate web export in target browsers.

## Sprint 2 — Interaction and encounter quality
- [x] Add NPC interaction prompts and dialogue.
- [x] Add enemy state machine and telegraphed attacks.
- [x] Add health, damage, defeat and encounter results.
- [x] Add a simple mission objective.

## Sprint 3 — Living neighborhood
- [x] Add NPC schedule data and WorldClock integration.
- [x] Add inventory, item definitions, cash and shop purchases.
- [x] Upgrade local save schema to v3 with v1/v2 migration support.
- [x] Persist reputation, NPC relationships and world flags.
- [x] Add first authored neighborhood interiors (market and apartment).
- [x] Add apartment rest interaction and time advancement.
- [ ] Run Godot editor import and runtime validation.
- [ ] Exercise v1/v2 save migration against real fixture files.
- [ ] Validate movement, interactions and purchases in browser export.

## Sprint 4 — Vertical slice
- [x] Add five distinct NPCs with authored dialogue and schedules.
- [x] Add one complete mission with multiple outcomes and consequences.
- [x] Add a second encounter variant and an unlockable alley encounter.
- [x] Add original resident pixel-style art assets.
- [ ] Run Godot editor import and runtime validation.
- [ ] Verify mission branches, rewards, and persistent consequences.
- [ ] Run browser performance and usability checks.


## Sprint 5 — Player progression and training
- [x] Add XP rewards and persistent level progression.
- [x] Grant one skill point per level gained.
- [x] Add Coach-led Power, Endurance, and Footwork training.
- [x] Scale combat damage, stamina, dodge cost, and movement from upgrades.
- [x] Upgrade save schema to v5 with v1-v4 migration defaults.
- [ ] Validate level-ups, training caps, and save migration in Godot runtime.

## Sprint 6 — Dynamic neighborhood events
- [x] Add three scheduled, repeatable neighborhood events.
- [x] Add event rewards tied to cash, XP, reputation, and relationships.
- [x] Persist once-per-day event completion using existing world flags.
- [x] Surface active events on the neighborhood map and HUD.
- [ ] Validate event schedules, rewards, and once-per-day persistence in Godot runtime.

## Sprint 7 — Courier side hustles
- [x] Add two selectable courier routes through Nia.
- [x] Add destination markers and delivery completion interactions.
- [x] Reward cash, XP, local reputation, and Nia relationship.
- [x] Persist active route and once-per-day completion using world flags.
- [ ] Validate route selection, delivery completion, and save/reload in Godot runtime.


## Sprint 8 — Faction standing and neighborhood trust
- [x] Add readable standing tiers for locals and rivals.
- [x] Surface faction standing in the neighborhood HUD and NPC dialogue.
- [x] Scale courier payouts with local standing perks.
- [x] Add headless standing-boundary tests to CI.
- [ ] Validate standing progression and courier payouts in interactive browser gameplay.


## Sprint 9 — Environment-specific combat scenes
- [x] Add distinct street-corner, market-front, and alley combat scenes.
- [x] Route each current encounter to its matching environment.
- [x] Keep the player's neighborhood return position across the fight transition.
- [x] Add headless CI checks for combat scene loading and environment identity.
- [ ] Validate combat transitions and return positioning in interactive gameplay.


## Sprint 10 — Combat depth: combos and heavy strikes
- [x] Add a three-hit light-attack combo with increasing damage.
- [x] Add a stamina-intensive heavy strike.
- [x] Allow a heavy strike to interrupt an enemy's telegraphed attack.
- [x] Add headless tests for combo and heavy-strike damage scaling.
- [ ] Validate attack timing, stamina balance, and enemy interruption in interactive gameplay.
