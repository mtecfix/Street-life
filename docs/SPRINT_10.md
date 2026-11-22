# Sprint 10 — Combat Depth: Combos and Heavy Strikes

The combat controller now offers two attack styles while preserving the existing movement, dodge, enemy telegraph, health, stamina, and encounter reward systems.

## Controls
- **Space — Light attack:** chains up to three hits while the combo window remains open. Each successive hit deals more damage.
- **Q — Heavy strike:** costs 36 stamina, has a longer cooldown, and deals 1.8 times the player's current base attack damage.
- **Shift — Dodge:** unchanged.
- **WASD — Move:** unchanged.
- **Esc — Retreat/return:** unchanged.

A heavy strike that lands during an enemy windup interrupts the telegraphed attack and places the opponent into a short recovery window. Combo damage continues to scale with the Power skill because it uses the player's current attack damage.

## Validation
CI checks the three combo damage multipliers and heavy-strike damage formula before Web export. Interactive timing, stamina balance, interruption behavior, and browser gameplay remain to be playtested.
