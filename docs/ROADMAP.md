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
