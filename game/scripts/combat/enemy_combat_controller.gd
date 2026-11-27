extends RefCounted
class_name EnemyCombatController
## Encounter enemy movement archetypes. The arena owns attacks and health resolution.

const FACTIONS := {
    "corner_set": {
        "name": "Corner Set",
        "callout": "LOCAL CREW",
        "speed_multiplier": 1.0,
        "damage_multiplier": 1.0,
        "windup_multiplier": 1.0,
        "recovery_multiplier": 1.0,
        "color": Color("#d66a55")
    },
    "market_crew": {
        "name": "Market Crew",
        "callout": "PROTECTING THE BLOCK",
        "speed_multiplier": 0.92,
        "damage_multiplier": 1.12,
        "windup_multiplier": 1.12,
        "recovery_multiplier": 1.08,
        "color": Color("#c58c4e")
    },
    "alley_runners": {
        "name": "Alley Runners",
        "callout": "RIVAL RUNNERS",
        "speed_multiplier": 1.16,
        "damage_multiplier": 0.88,
        "windup_multiplier": 0.88,
        "recovery_multiplier": 0.88,
        "color": Color("#9e6bb0")
    }
}

const ENCOUNTER_FACTIONS := {
    "corner_brawler": "corner_set",
    "shop_guard": "market_crew",
    "alley_ambush": "alley_runners"
}

const ARCHETYPES := {
    "pressure_brawler": {
        "display_name": "Pressure Fighter",
        "preferred_distance": 54.0,
        "movement": "advance",
        "recovery": 0.92,
        "strafe_strength": 0.0
    },
    "counter_guard": {
        "display_name": "Counter Guard",
        "preferred_distance": 112.0,
        "movement": "hold",
        "recovery": 1.35,
        "strafe_strength": 0.0
    },
    "skirmisher": {
        "display_name": "Skirmisher",
        "preferred_distance": 118.0,
        "movement": "orbit",
        "recovery": 0.72,
        "strafe_strength": 0.72
    }
}

static func get_profile(archetype_id: String) -> Dictionary:
    return ARCHETYPES.get(archetype_id, ARCHETYPES["pressure_brawler"]).duplicate(true)

static func get_recovery_duration(archetype_id: String) -> float:
    return float(get_profile(archetype_id)["recovery"])

static func get_movement_direction(archetype_id: String, player_position: Vector2, enemy_position: Vector2, elapsed_seconds: float) -> Vector2:
    var profile := get_profile(archetype_id)
    var to_player := player_position - enemy_position
    var distance := to_player.length()
    if distance <= 0.001:
        return Vector2.ZERO
    var toward := to_player / distance
    var preferred := float(profile["preferred_distance"])
    match str(profile["movement"]):
        "hold":
            if distance > preferred + 10.0:
                return toward
            if distance < preferred - 14.0:
                return -toward * 0.35
            return Vector2.ZERO
        "orbit":
            var tangent := Vector2(-toward.y, toward.x)
            var orbit_direction := 1.0 if sin(elapsed_seconds * 1.3) >= 0.0 else -1.0
            if distance > preferred + 30.0:
                return (toward + tangent * float(profile["strafe_strength"]) * orbit_direction).normalized()
            if distance < preferred - 22.0:
                return (-toward + tangent * float(profile["strafe_strength"]) * orbit_direction).normalized()
            return tangent * orbit_direction
        _:
            return toward


static func get_faction_id_for_encounter(encounter_id: String) -> String:
    return str(ENCOUNTER_FACTIONS.get(encounter_id, "corner_set"))

static func get_faction_profile(faction_id: String) -> Dictionary:
    return FACTIONS.get(faction_id, FACTIONS["corner_set"]).duplicate(true)

static func get_faction_adjusted_stats(faction_id: String, base_stats: Dictionary) -> Dictionary:
    var faction := get_faction_profile(faction_id)
    var adjusted := base_stats.duplicate(true)
    if adjusted.has("speed"):
        adjusted["speed"] = float(adjusted["speed"]) * float(faction["speed_multiplier"])
    if adjusted.has("damage"):
        adjusted["damage"] = float(adjusted["damage"]) * float(faction["damage_multiplier"])
    if adjusted.has("windup"):
        adjusted["windup"] = float(adjusted["windup"]) * float(faction["windup_multiplier"])
    if adjusted.has("recovery"):
        adjusted["recovery"] = float(adjusted["recovery"]) * float(faction["recovery_multiplier"])
    return adjusted

static func get_faction_recovery_duration(archetype_id: String, faction_id: String) -> float:
    var archetype_recovery := get_recovery_duration(archetype_id)
    var faction := get_faction_profile(faction_id)
    return archetype_recovery * float(faction["recovery_multiplier"])
