extends RefCounted
class_name FirearmCombatController
## Weapon profiles and firearm handling calculations, independent of arena UI.

const WEAPONS := {
    "sidearm": {
        "name": "9mm Sidearm", "magazine": 12, "damage": 14.0,
        "cooldown": 0.42, "range": 440.0, "reload": 1.25,
        "reserve_start": 48, "description": "Balanced handling and quick reloads."
    },
    "smg": {
        "name": "Compact SMG", "magazine": 24, "damage": 8.5,
        "cooldown": 0.17, "range": 340.0, "reload": 1.65,
        "reserve_start": 96, "description": "Fast close-range pressure; weaker at distance."
    },
    "carbine": {
        "name": "Street Carbine", "magazine": 20, "damage": 19.0,
        "cooldown": 0.36, "range": 640.0, "reload": 1.8,
        "reserve_start": 80, "description": "Slower, harder-hitting shots with longer reach."
    }
}
const WEAPON_ORDER := ["sidearm", "smg", "carbine"]

static func get_profile(weapon_id: String) -> Dictionary:
    return WEAPONS.get(weapon_id, WEAPONS["sidearm"]).duplicate(true)

static func get_shot_damage(weapon_id: String, aiming: bool, moving: bool, unlocked: Array, last_shot_recent: bool, ammo_after_shot: int) -> float:
    var profile := get_profile(weapon_id)
    var damage := float(profile["damage"])
    if aiming:
        damage *= 1.20
    if moving:
        damage *= 0.96 if "move_and_aim" in unlocked else 0.86
    elif aiming and "steady_hands" in unlocked:
        damage *= 1.10
    if "controlled_burst" in unlocked and last_shot_recent:
        damage *= 1.12
    if ammo_after_shot <= 2 and "last_round_focus" in unlocked:
        damage *= 1.08
    if aiming and "precision_specialist" in unlocked:
        damage *= 1.15
    if "mobile_operator" in unlocked and last_shot_recent:
        damage *= 0.92
    return damage

static func get_shot_cooldown(weapon_id: String, unlocked: Array) -> float:
    var cooldown := float(get_profile(weapon_id)["cooldown"])
    if "mobile_operator" in unlocked:
        cooldown *= 0.90
    elif "snap_aim" in unlocked:
        cooldown *= 0.92
    if "precision_specialist" in unlocked:
        cooldown += 0.04
    return cooldown

static func get_reload_duration(weapon_id: String, current_magazine: int, unlocked: Array) -> float:
    var duration := float(get_profile(weapon_id)["reload"])
    if "fast_hands" in unlocked:
        duration *= 0.92
    if "quick_reload" in unlocked:
        duration *= 0.84
    if current_magazine > 0 and "ammo_discipline" in unlocked:
        duration *= 0.88
    return duration

static func next_weapon(current_weapon: String) -> String:
    var index := WEAPON_ORDER.find(current_weapon)
    return WEAPON_ORDER[(index + 1) % WEAPON_ORDER.size()]
