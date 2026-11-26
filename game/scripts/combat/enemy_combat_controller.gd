extends RefCounted
class_name EnemyCombatController
## Encounter enemy movement archetypes. The arena owns attacks and health resolution.

const ARCHETYPES := {
    "pressure_brawler": {
        "display_name": "Pressure Fighter",
        "preferred_distance": 54.0,
        "movement": "advance",
        "strafe_strength": 0.0
    },
    "counter_guard": {
        "display_name": "Counter Guard",
        "preferred_distance": 112.0,
        "movement": "hold",
        "strafe_strength": 0.0
    },
    "skirmisher": {
        "display_name": "Skirmisher",
        "preferred_distance": 118.0,
        "movement": "orbit",
        "strafe_strength": 0.72
    }
}

static func get_profile(archetype_id: String) -> Dictionary:
    return ARCHETYPES.get(archetype_id, ARCHETYPES["pressure_brawler"]).duplicate(true)

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
