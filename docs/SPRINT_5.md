# Sprint 5 — Player Progression & Training

## Progression
- Combat victories award XP: 50 for the corner challenger, 45 for the shopfront agitator, and 65 for the alley runner.
- The first level requires 100 XP; each subsequent level raises the threshold by 50 XP.
- Every level gained grants one spendable skill point. XP, level, unspent points, and skill ranks persist.

## Coach training
Talk to Coach during his neighborhood schedule and use the numbered choices:
- **1 — Power:** +5 player attack damage per rank.
- **2 — Endurance:** +15 maximum stamina and +2 stamina regeneration per rank.
- **3 — Footwork:** +12 movement speed and -4 dodge stamina cost per rank.
- Each discipline has three ranks. Training consumes one skill point; no cash cost.

## Controls
- E: interact with Coach.
- 1 / 2 / 3: purchase the corresponding upgrade while the training prompt is open.
- Esc: close the training prompt.
- Combat controls remain WASD/arrows, Space to attack, Shift to dodge, and Esc to retreat.

## Persistence and compatibility
Save schema v5 stores XP, level, skill points, and skill ranks. Older v1-v4 saves default to level 1 with zero XP, zero skill points, and rank 0 in all disciplines; existing progress remains restored.

## Validation
The CI Web export checks Godot import/export. It does not prove runtime balance, training UX, or save migration; those remain explicit runtime validation tasks.
