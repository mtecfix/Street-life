extends RefCounted
class_name EncounterWaveController
## Data-driven sequential rival crew reinforcements for the current single-target arena.

const ENCOUNTER_WAVES := {
    "corner_brawler": [
        {
            "name": "Corner challenger",
            "archetype": "pressure_brawler",
            "faction": "corner_set",
            "health": 100.0, "speed": 92.0, "attack_range": 76.0, "damage": 18.0, "windup": 0.78
        },
        {
            "name": "Corner enforcer",
            "archetype": "counter_guard",
            "faction": "corner_set",
            "health": 112.0, "speed": 84.0, "attack_range": 112.0, "damage": 20.0, "windup": 0.92
        }
    ],
    "shop_guard": [
        {
            "name": "Shopfront agitator",
            "archetype": "counter_guard",
            "faction": "market_crew",
            "health": 82.0, "speed": 82.0, "attack_range": 128.0, "damage": 20.0, "windup": 1.02
        },
        {
            "name": "Market bruiser",
            "archetype": "pressure_brawler",
            "faction": "market_crew",
            "health": 118.0, "speed": 88.0, "attack_range": 82.0, "damage": 19.0, "windup": 0.88
        }
    ],
    "alley_ambush": [
        {
            "name": "Alley runner",
            "archetype": "skirmisher",
            "faction": "alley_runners",
            "health": 95.0, "speed": 128.0, "attack_range": 142.0, "damage": 14.0, "windup": 0.58
        },
        {
            "name": "Alley spotter",
            "archetype": "pressure_brawler",
            "faction": "alley_runners",
            "health": 88.0, "speed": 112.0, "attack_range": 84.0, "damage": 15.0, "windup": 0.66
        },
        {
            "name": "Runner captain",
            "archetype": "counter_guard",
            "faction": "alley_runners",
            "health": 138.0, "speed": 104.0, "attack_range": 120.0, "damage": 18.0, "windup": 0.82
        }
    ]
}

static func get_waves(encounter_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var configured: Array = ENCOUNTER_WAVES.get(encounter_id, ENCOUNTER_WAVES["corner_brawler"])
    for wave in configured:
        result.append((wave as Dictionary).duplicate(true))
    return result

static func get_wave_count(encounter_id: String) -> int:
    return get_waves(encounter_id).size()

static func has_following_wave(encounter_id: String, current_index: int) -> bool:
    return current_index + 1 < get_wave_count(encounter_id)
