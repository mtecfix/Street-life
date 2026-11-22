# Sprint 9 — Environment-Specific Combat Scenes

Combat no longer sends every encounter to a visually generic arena. The shared combat controller now supports location-themed scenes:

| Encounter | Combat scene | Environment |
|---|---|---|
| Corner challenger | `CombatArena.tscn` | Neighborhood street corner |
| Shopfront agitator | `CombatShopfront.tscn` | Maya's Market storefront |
| Alley runner | `CombatAlley.tscn` | Back alley |

The variants share the existing combat controller and retain its health, stamina, attack telegraph, dodge, rewards, XP, reputation, and mission outcome behavior.

The neighborhood position is captured before the scene transition and restored when the player returns. The corner job marker is positioned beside the market frontage so the shop-protection encounter is grounded in that part of the neighborhood.

## Validation
CI loads each combat scene headlessly and checks its environment identity before the Web export. This validates scene resources and routing variants, not live gameplay behavior. Interactive combat, collision feel, and return-position behavior still require runtime playtesting.
