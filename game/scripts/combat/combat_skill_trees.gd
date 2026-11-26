extends RefCounted
class_name CombatSkillTrees
## Data-only definitions for the melee and firearms progression trees.
## Purchase validation, persistence, UI, and gameplay effects are integrated separately.

const TREES := {
    "melee": {
        "display_name": "Fist Fighting",
        "description": "Combos, defense, counters, and footwork.",
        "nodes": {
            "street_fundamentals": {"name": "Street Fundamentals", "tier": 0, "cost": 1, "requires": [], "description": "Unlocks the foundational three-hit combo and clear hit confirmation.", "effects": {"combo_foundation": true}},
            "guard_up": {"name": "Guard Up", "tier": 0, "cost": 1, "requires": [], "description": "Unlocks a timed frontal block.", "effects": {"guard_unlocked": true}},
            "quick_step": {"name": "Quick Step", "tier": 0, "cost": 1, "requires": [], "description": "Slightly reduces dodge recovery.", "effects": {"dodge_recovery_multiplier": 0.92}},
            "combination_flow": {"name": "Combination Flow", "tier": 1, "cost": 2, "requires": ["street_fundamentals"], "description": "Widens the combo input window and rewards completed combinations.", "effects": {"combo_window_multiplier": 1.15}},
            "body_shot": {"name": "Body Shot", "tier": 1, "cost": 2, "requires": ["street_fundamentals"], "description": "Unlocks a stamina-costly strike that can disrupt a windup.", "effects": {"body_shot_unlocked": true}},
            "counter_window": {"name": "Counter Window", "tier": 2, "cost": 3, "requires": ["guard_up", "combination_flow"], "description": "A well-timed block creates a brief counter opportunity.", "effects": {"counter_unlocked": true}},
            "angle_change": {"name": "Angle Change", "tier": 1, "cost": 2, "requires": ["quick_step"], "description": "A directional dodge creates a short flank opportunity.", "effects": {"flank_window_unlocked": true}},
            "ring_control": {"name": "Ring Control", "tier": 1, "cost": 2, "requires": ["quick_step"], "description": "Improves movement control near an opponent.", "effects": {"combat_control_multiplier": 1.08}},
            "slip_and_return": {"name": "Slip and Return", "tier": 2, "cost": 3, "requires": ["angle_change", "counter_window"], "description": "A perfectly timed dodge grants one empowered follow-up.", "effects": {"dodge_followup_unlocked": true}},
            "pressure_fighter": {"name": "Pressure Fighter", "tier": 3, "cost": 4, "requires": ["combination_flow", "body_shot", "counter_window"], "description": "Maintains combo momentum, but slows stamina recovery while attacking.", "effects": {"pressure_mastery": true}},
            "counter_specialist": {"name": "Counter Specialist", "tier": 3, "cost": 4, "requires": ["counter_window", "slip_and_return"], "description": "Improves counter opportunities at the cost of heavy-strike output.", "effects": {"counter_mastery": true}}
        }
    },
    "firearms": {
        "display_name": "Firearms",
        "description": "Handling, readiness, mobility, and awareness.",
        "nodes": {
            "steady_hands": {"name": "Steady Hands", "tier": 0, "cost": 1, "requires": [], "description": "Reduces aim drift while stationary.", "effects": {"stationary_aim_stability": 1.10}},
            "fast_hands": {"name": "Fast Hands", "tier": 0, "cost": 1, "requires": [], "description": "Modestly shortens reload time.", "effects": {"reload_duration_multiplier": 0.92}},
            "combat_awareness": {"name": "Combat Awareness", "tier": 0, "cost": 1, "requires": [], "description": "Improves enemy threat indicators and flank feedback.", "effects": {"threat_feedback": true}},
            "controlled_burst": {"name": "Controlled Burst", "tier": 1, "cost": 2, "requires": ["steady_hands"], "description": "Improves consistency during short firing bursts.", "effects": {"burst_stability": 1.12}},
            "snap_aim": {"name": "Snap Aim", "tier": 1, "cost": 2, "requires": ["steady_hands"], "description": "Speeds aim entry with a small moving-accuracy trade-off.", "effects": {"aim_transition_multiplier": 0.88}},
            "composure": {"name": "Composure", "tier": 2, "cost": 3, "requires": ["snap_aim", "combat_awareness"], "description": "Restores aim stability sooner after taking a hit.", "effects": {"aim_recovery_multiplier": 1.15}},
            "quick_reload": {"name": "Quick Reload", "tier": 1, "cost": 2, "requires": ["fast_hands"], "description": "Further shortens reload duration.", "effects": {"reload_duration_multiplier": 0.84}},
            "ammo_discipline": {"name": "Ammo Discipline", "tier": 1, "cost": 2, "requires": ["fast_hands"], "description": "Can retain some unused magazine capacity on a tactical reload; creates no ammunition.", "effects": {"tactical_reload_retention": true}},
            "last_round_focus": {"name": "Last Round Focus", "tier": 2, "cost": 3, "requires": ["quick_reload", "ammo_discipline"], "description": "Improves low-ammo feedback and handling near magazine depletion.", "effects": {"low_ammo_handling": 1.08}},
            "move_and_aim": {"name": "Move and Aim", "tier": 1, "cost": 2, "requires": ["combat_awareness"], "description": "Reduces the movement penalty while aiming.", "effects": {"aim_move_penalty_multiplier": 0.85}},
            "cover_awareness": {"name": "Cover Awareness", "tier": 1, "cost": 2, "requires": ["combat_awareness"], "description": "Improves cover and line-of-sight feedback.", "effects": {"cover_feedback": true}},
            "reposition": {"name": "Reposition", "tier": 2, "cost": 3, "requires": ["move_and_aim", "cover_awareness"], "description": "Improves recovery when leaving aim mode.", "effects": {"aim_exit_recovery_multiplier": 1.15}},
            "precision_specialist": {"name": "Precision Specialist", "tier": 3, "cost": 4, "requires": ["controlled_burst", "composure"], "description": "Improves deliberate shot stability but slows movement while aiming.", "effects": {"precision_mastery": true}},
            "mobile_operator": {"name": "Mobile Operator", "tier": 3, "cost": 4, "requires": ["move_and_aim", "reposition"], "description": "Improves movement and aim transitions but reduces sustained-fire stability.", "effects": {"mobility_mastery": true}}
        }
    }
}

static func get_tree(style: String) -> Dictionary:
    return TREES.get(style.to_lower(), {})

static func can_purchase(style: String, node_id: String, unlocked_nodes: Array, available_points: int) -> bool:
    var tree := get_tree(style)
    if tree.is_empty():
        return false
    var nodes: Dictionary = tree.get("nodes", {})
    if not nodes.has(node_id) or node_id in unlocked_nodes:
        return false
    var node: Dictionary = nodes[node_id]
    if available_points < int(node.get("cost", 0)):
        return false
    for prerequisite in node.get("requires", []):
        if prerequisite not in unlocked_nodes:
            return false
    return true
