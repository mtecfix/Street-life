extends SceneTree

# Run: godot --headless --path game --script res://tests/test_combat_skill_trees.gd

const SAVE_PATH := "user://savegame.json"
var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state: Variant = root.get_node_or_null("GameState")
    var saves: Variant = root.get_node_or_null("SaveManager")
    if state == null or saves == null:
        push_error("Combat skill tree test could not find progression autoloads.")
        quit(1)
        return
    var snapshot := {
        "skill_points": state.skill_points,
        "unlocks": state.combat_skill_unlocks.duplicate(true)
    }
    var original_save := FileAccess.get_file_as_string(SAVE_PATH) if FileAccess.file_exists(SAVE_PATH) else ""

    state.skill_points = 20
    state.combat_skill_unlocks = {"melee": [], "firearms": []}
    _check(not state.purchase_combat_skill("unknown", "street_fundamentals"), "Unknown combat discipline must be rejected.")
    _check(not state.purchase_combat_skill("melee", "combination_flow"), "A node must not unlock before its prerequisite.")
    _check(state.skill_points == 20, "Rejected purchases must not spend skill points.")
    _check(state.purchase_combat_skill("melee", "street_fundamentals"), "Melee foundation should unlock.")
    _check(state.purchase_combat_skill("melee", "combination_flow"), "A valid melee branch node should unlock.")
    _check(state.has_combat_skill("melee", "combination_flow"), "Unlocked melee node should be queryable.")
    _check(not state.has_combat_skill("firearms", "combination_flow"), "Melee unlocks must not leak into firearms.")
    _check(state.purchase_combat_skill("firearms", "fast_hands"), "Firearms foundation should unlock independently.")
    _check(state.purchase_combat_skill("firearms", "quick_reload"), "Firearms prerequisite chain should unlock.")
    _check(state.skill_points == 14, "Purchase costs should be deducted exactly.")

    _check(saves.save_game() == OK, "Combat skill unlocks should save.")
    state.combat_skill_unlocks = {"melee": [], "firearms": []}
    _check(saves.load_game() == OK, "Combat skill unlocks should load.")
    _check(state.has_combat_skill("melee", "combination_flow"), "Melee unlock did not persist.")
    _check(state.has_combat_skill("firearms", "quick_reload"), "Firearms unlock did not persist.")

    var refunded := state.respec_combat_skills("melee")
    _check(refunded == 3, "Melee respec should refund the exact points spent in that tree.")
    _check(not state.has_combat_skill("melee", "street_fundamentals"), "Respec should clear the selected tree.")
    _check(state.has_combat_skill("firearms", "quick_reload"), "Respec must not clear the other discipline.")
    _check(state.skill_points == 17, "Respec should return the correct number of points.")

    state.combat_skill_unlocks = snapshot["unlocks"]
    state.skill_points = snapshot["skill_points"]
    saves.save_game()
    if original_save.is_empty():
        if FileAccess.file_exists(SAVE_PATH):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    else:
        var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if file != null:
            file.store_string(original_save)

    if _failures.is_empty():
        print("PASS: combat skill prerequisites, independent trees, persistence, and respec.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
