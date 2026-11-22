# Sprint 7 — Courier Side Hustles

Nia now offers one courier job per in-game day. Talk to Nia and choose a route, then deliver the package at the gold marker using E. The active job and daily completion flag are stored in GameState.world_flags, which is already persisted by save schema v5.

| Route | Destination | Reward |
|---|---|---|
| Market supply run | Maya's Market | $30, 30 XP, +2 local reputation, +2 Nia relationship |
| Apartment package | The Walk-Ups | $35, 35 XP, +2 local reputation, +2 Nia relationship |

The route remains active across save/reload. Completing either route consumes that day's courier opportunity; a new route becomes available on the next in-game day.

## Controls
- Talk to Nia and press 1 or 2 to accept a route.
- Visit the gold destination marker.
- Press E to complete the delivery.
- Esc closes Nia's route menu.

## Validation
CI import/export validation is pending. Runtime route selection, reward application, and save/reload behavior have not yet been exercised in Godot.
