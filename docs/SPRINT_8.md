# Sprint 8 — Faction Standing & Neighborhood Trust

Faction reputation now resolves into readable standing tiers.

| Faction | Reputation | Standing |
|---|---:|---|
| Locals | -100 to -25 | Unwelcome |
| Locals | -24 to 9 | Unknown |
| Locals | 10 to 29 | Known |
| Locals | 30 to 59 | Trusted |
| Locals | 60 to 100 | Pillar |
| Rivals | -100 to -25 | Hunted |
| Rivals | -24 to -11 | Wary |
| Rivals | -10 to 9 | Neutral |
| Rivals | 10 to 29 | Connected |
| Rivals | 30 to 100 | Insider |

Local standing now improves courier earnings: Known +$2, Trusted +$5, and Pillar +$8 per completed route. The neighborhood HUD displays both standing tiers and scores, and Maya's dialogue reacts to low or high local standing.

## Validation
CI runs headless boundary tests for every standing tier and courier bonus threshold before exporting the Web build. Interactive browser gameplay and end-to-end payout/save validation remain outstanding.
