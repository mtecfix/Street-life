# Technical Architecture

## Runtime
Godot 4.x, GDScript, scene-based architecture.

## Autoloads
- `EventBus`: cross-system notifications.
- `GameState`: session-level player and world state.
- `WorldClock`: in-game time.
- `SaveManager`: versioned local persistence.
- `SceneManager`: controlled scene transitions.

## Scene flow
`Main` → `World` ↔ `CombatArena`.

Combat is a separate scene. The SceneManager retains the previous scene identifier and returns the player to exploration after the encounter.

## Persistence
The first adapter writes versioned JSON to `user://savegame.json`. In web exports, Godot's user data directory is backed by browser storage when supported by the export/runtime configuration. Browser persistence behavior must be verified in target browsers.

Cloud synchronization is intentionally deferred. A future `SaveProvider` abstraction should support authentication, conflict resolution, schema migration and offline-first behavior without coupling network code to gameplay scenes.

## Web constraints
Target desktop browsers first. Start with a single-threaded web export to reduce hosting complexity. Validate audio, input, memory use, storage and browser refresh behavior on the actual deployed build.
