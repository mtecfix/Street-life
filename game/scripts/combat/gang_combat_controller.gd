extends RefCounted
class_name GangCombatController
## Data-only coordinator for simultaneous rival-crew combat.
## The arena owns actor nodes and animations; this class owns roster state,
## target cycling, crowd-slot placement, and staggered attacker scheduling.

var combatants: Array[Dictionary] = []
var target_index := -1
var attack_cursor := -1
var next_attack_time := -1.0

func configure(roster: Array[Dictionary]) -> void:
    combatants.clear()
    target_index = -1
    attack_cursor = -1
    next_attack_time = -1.0
    for index in range(roster.size()):
        var member := roster[index].duplicate(true)
        member["id"] = str(member.get("id", "gang_%d" % index))
        member["name"] = str(member.get("name", "Crew member %d" % (index + 1)))
        member["max_health"] = maxf(1.0, float(member.get("max_health", member.get("health", 100.0))))
        member["health"] = clampf(float(member.get("health", member["max_health"])), 0.0, float(member["max_health"]))
        member["alive"] = bool(member.get("alive", float(member["health"]) > 0.0)) and float(member["health"]) > 0.0
        combatants.append(member)
    target_index = _first_alive_index()

func get_combatants() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for member in combatants:
        result.append(member.duplicate(true))
    return result

func get_alive_combatants() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for member in combatants:
        if bool(member.get("alive", false)):
            result.append(member.duplicate(true))
    return result

func get_alive_count() -> int:
    var count := 0
    for member in combatants:
        if bool(member.get("alive", false)):
            count += 1
    return count

func get_target_id() -> String:
    if target_index < 0 or target_index >= combatants.size():
        return ""
    if not bool(combatants[target_index].get("alive", false)):
        return ""
    return str(combatants[target_index]["id"])

func select_next_target(direction: int = 1) -> String:
    if combatants.is_empty() or get_alive_count() == 0:
        target_index = -1
        return ""
    var step := 1 if direction >= 0 else -1
    var start := target_index
    for offset in range(1, combatants.size() + 1):
        var candidate := posmod(start + step * offset, combatants.size())
        if bool(combatants[candidate].get("alive", false)):
            target_index = candidate
            return str(combatants[target_index]["id"])
    target_index = _first_alive_index()
    return get_target_id()

func set_target(target_id: String) -> bool:
    for index in range(combatants.size()):
        if str(combatants[index]["id"]) == target_id and bool(combatants[index].get("alive", false)):
            target_index = index
            return true
    return false

func apply_damage(target_id: String, amount: float) -> float:
    for index in range(combatants.size()):
        if str(combatants[index]["id"]) != target_id or not bool(combatants[index].get("alive", false)):
            continue
        var remaining := maxf(0.0, float(combatants[index]["health"]) - maxf(0.0, amount))
        combatants[index]["health"] = remaining
        if remaining <= 0.0:
            combatants[index]["alive"] = false
            if target_index == index:
                _select_nearest_alive(index)
        return remaining
    return -1.0

func mark_defeated(target_id: String) -> bool:
    return apply_damage(target_id, INF) == 0.0

func get_next_attacker(now_seconds: float, minimum_interval: float = 0.65) -> Dictionary:
    if now_seconds < next_attack_time or get_alive_count() == 0:
        return {}
    for offset in range(1, combatants.size() + 1):
        var candidate := posmod(attack_cursor + offset, combatants.size())
        if bool(combatants[candidate].get("alive", false)):
            attack_cursor = candidate
            next_attack_time = now_seconds + maxf(0.1, minimum_interval)
            return combatants[candidate].duplicate(true)
    return {}

static func get_crowd_offset(slot_index: int, slot_count: int, radius: float = 76.0) -> Vector2:
    if slot_count <= 0:
        return Vector2.ZERO
    var safe_count := maxi(1, slot_count)
    var angle := -PI / 2.0 + TAU * float(posmod(slot_index, safe_count)) / float(safe_count)
    return Vector2(cos(angle), sin(angle)) * maxf(0.0, radius)

func _first_alive_index() -> int:
    for index in range(combatants.size()):
        if bool(combatants[index].get("alive", false)):
            return index
    return -1

func _select_nearest_alive(defeated_index: int) -> void:
    if get_alive_count() == 0:
        target_index = -1
        return
    for offset in range(1, combatants.size() + 1):
        var candidate := posmod(defeated_index + offset, combatants.size())
        if bool(combatants[candidate].get("alive", false)):
            target_index = candidate
            return
