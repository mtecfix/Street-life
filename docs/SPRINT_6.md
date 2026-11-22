# Sprint 6 — Dynamic Neighborhood Events

## Feature
Three time-windowed neighborhood events now rotate through the existing block. The active event appears as a cyan marker and can be completed by pressing E within interaction range.

| Event | Window | Reward |
|---|---|---|
| Market delivery | 7 AM–10 AM | $12, 15 XP, +2 locals reputation, +2 Maya relationship |
| Community court | 2 PM–5 PM | $18, 20 XP, +2 locals reputation |
| Rival watch | 7 PM–10 PM | $10, 20 XP, +2 locals reputation, -2 rivals reputation |

Each event can be completed once per in-game day. Completion history is stored in world_flags.daily_event_completions, already covered by save schema v5, so this sprint does not require a schema migration.

## Controls
- Visit the cyan event marker during its time window.
- Press E to complete the event.
- Rewards are saved immediately.
- Existing missions, NPC schedules, training, shops, and combat remain available.

## Validation
CI import/export validation is pending for this commit. Runtime event timing, reward application, and daily reset behavior have not yet been exercised in Godot.
