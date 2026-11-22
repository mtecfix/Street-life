# Gameplay Systems

## Implementation order
1. Player movement and interaction.
2. Scene transitions and encounter lifecycle.
3. Health and combat resolution.
4. NPC interaction and dialogue.
5. Inventory and economy.
6. World clock and NPC schedules.
7. Reputation, factions and mission outcomes.
8. Save versioning and cloud synchronization.

## System boundaries
- Player controller: movement, input and player-facing actions.
- Combat: encounter state, damage, enemy behavior and results.
- NPC: stable identity, schedule windows, disposition, relationship state and dialogue.
- Economy: item definitions, prices, cash transactions and inventory capacity.
- Inventory: item stacks and consumable effects.
- Progression: skills, unlocks and player attributes.
- Factions: membership, relationships, territory and conflict.
- Missions: objectives, prerequisites, outcomes and rewards.
- World events: time-based triggers and event consequences.
- Interiors: authored scene spaces with explicit entry, exit and interaction rules.

## Sprint 3 implementation
- WorldClock advances one game minute per real second and exposes day/hour/minute helpers.
- Rico, Maya and Dre use authored hour windows; their presence is refreshed when game time changes.
- Maya's Market sells snacks, first-aid kits and soda. The inventory has a 20-item stack-count capacity.
- Consumables restore player health in the neighborhood.
- The apartment has a rest interaction that restores health and advances time by eight hours.
- Save schema v3 persists inventory, reputation, NPC relationships and world flags while accepting v1 and v2 files.

## Event-driven communication
Use signals or the EventBus for cross-system notifications. Avoid direct dependencies between unrelated systems. Events should carry typed, minimal payloads.


## Sprint 8 implementation
- FactionManager maps local and rival reputation scores to named standing tiers.
- Local standing grants a courier cash bonus at known, trusted, and pillar thresholds.
- The neighborhood HUD displays both faction tiers and numeric reputation; Maya's dialogue reflects local standing.
- Headless CI tests cover tier boundaries and courier bonus thresholds. Interactive gameplay validation remains outstanding.


## Environment-specific combat
- Combat encounters load a scene styled for the location where the confrontation starts: street corner, market front, or back alley.
- The encounter's originating neighborhood position remains in GameState and is restored when combat returns to the neighborhood.
- The shared combat controller keeps the existing health, stamina, enemy telegraph, rewards, and progression behavior across all environment variants.
- Headless CI checks load each combat scene and verify its environment identity; interactive transition testing remains outstanding.


## Sprint 10 — Combat attack system
- Space chains up to three light attacks while the combo window remains open; successive hits scale damage.
- Q performs a heavier strike that costs more stamina and deals increased damage.
- A heavy strike that lands during an enemy windup cancels that telegraphed attack and creates a short enemy recovery window.
- The existing attack cooldown, stamina regeneration, player skill damage scaling, dodge, rewards, and encounter lifecycle remain in place.
- CI checks the damage formulas; combat feel and balance still require interactive playtesting.
