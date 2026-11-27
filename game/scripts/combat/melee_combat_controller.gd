extends RefCounted
class_name MeleeCombatController
## Reusable melee combat rules. Arena owns presentation and encounter lifecycle.

static func combo_damage(base_damage: int, combo_index: int, unlocked: Array, flank_followup: bool = false) -> int:
    var multipliers := [1.0, 1.15, 1.35]
    var damage := float(base_damage) * float(multipliers[clampi(combo_index, 0, 2)])
    if "street_fundamentals" in unlocked and combo_index == 2:
        damage *= 1.10
    if "pressure_fighter" in unlocked and combo_index == 2:
        damage *= 1.18
    if flank_followup:
        damage *= 1.35 if "slip_and_return" in unlocked else 1.20
    return roundi(damage)

static func heavy_damage(base_damage: int, unlocked: Array) -> int:
    var damage := float(base_damage) * 1.8
    if "counter_specialist" in unlocked:
        damage *= 0.90
    return roundi(damage)

static func dodge_cost(base_cost: float, unlocked: Array) -> float:
    return base_cost * (0.88 if "quick_step" in unlocked else 1.0)

static func dodge_duration(unlocked: Array) -> float:
    return 0.24 if "quick_step" in unlocked else 0.20

static func counter_damage(unlocked: Array) -> float:
    return 20.0 * (1.30 if "counter_specialist" in unlocked else 1.0)

static func has_node(unlocked: Array, node_id: String) -> bool:
    return node_id in unlocked
