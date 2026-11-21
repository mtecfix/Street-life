# Gameplay Systems

## Initial implementation order
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
- NPC: identity, schedule, disposition, dialogue and memory.
- Economy: item definitions, pricing, supply/demand and transactions.
- Inventory: item stacks, equipment and capacity.
- Progression: skills, unlocks and player attributes.
- Factions: membership, relationships, territory and conflict.
- Missions: objectives, prerequisites, outcomes and rewards.
- World events: time-based triggers and event consequences.

## Event-driven communication
Use signals or the EventBus for cross-system notifications. Avoid direct dependencies between unrelated systems. Events should carry typed, minimal payloads.
