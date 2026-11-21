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
