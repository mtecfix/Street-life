extends SceneTree

# Run: godot --headless --path game --script res://tests/test_gang_combat_controller.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var gang := GangCombatController.new()
    gang.configure([
        {"id": "lookout", "name": "Lookout", "health": 60.0},
        {"id": "bruiser", "name": "Bruiser", "health": 100.0},
        {"id": "runner", "name": "Runner", "health": 80.0}
    ])
    _check(gang.get_alive_count() == 3, "All configured gang members should start alive.")
    _check(gang.get_target_id() == "lookout", "The first living member should be the initial target.")
    _check(gang.select_next_target() == "bruiser", "Target cycling should advance to the next living member.")
    _check(gang.select_next_target(-1) == "lookout", "Reverse target cycling should work.")

    _check(gang.apply_damage("bruiser", 45.0) == 55.0, "Damage should reduce only the requested member's health.")
    _check(gang.apply_damage("bruiser", 100.0) == 0.0, "Lethal damage should clamp health to zero.")
    _check(gang.get_alive_count() == 2, "Defeated members should be removed from the living roster.")
    _check(gang.get_target_id() == "lookout", "Defeating a non-target should preserve the current target.")
    _check(gang.set_target("runner"), "A living member should be selectable.")
    _check(not gang.set_target("bruiser"), "A defeated member should not be selectable.")
    _check(gang.select_next_target() == "lookout", "Target cycling should skip defeated members.")

    var first := gang.get_next_attacker(0.0, 0.7)
    _check(str(first.get("id", "")) == "lookout", "The first eligible attacker should be selected.")
    _check(gang.get_next_attacker(0.2, 0.7).is_empty(), "Attack scheduling should prevent overlapping attack starts.")
    var second := gang.get_next_attacker(0.7, 0.7)
    _check(str(second.get("id", "")) == "runner", "The scheduler should skip defeated members and rotate attackers.")
    _check(gang.get_next_attacker(1.0, 0.7).is_empty(), "The minimum interval should be enforced after each scheduled attack.")

    var snapshot := gang.get_combatants()
    snapshot[0]["health"] = -999.0
    _check(float(gang.get_combatants()[0]["health"]) == 60.0, "Roster snapshots should be defensive copies.")
    _check(GangCombatController.get_crowd_offset(0, 4).distance_to(GangCombatController.get_crowd_offset(1, 4)) > 1.0, "Crowd slots should occupy distinct positions.")
    _check(GangCombatController.get_crowd_offset(0, 0) == Vector2.ZERO, "An empty crowd should have no offset.")

    gang.configure([])
    _check(gang.get_alive_count() == 0 and gang.get_target_id().is_empty(), "An empty roster should have no target.")
    _check(gang.get_next_attacker(100.0).is_empty(), "An empty roster should never schedule an attacker.")

    if _failures.is_empty():
        print("PASS: gang roster state, target cycling, damage, crowd slots, and staggered attack scheduling.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
