extends SceneTree

# Run: godot --headless --path game --script res://tests/test_enemy_combat_controller.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var player := Vector2(400, 270)
    var enemy := Vector2(300, 270)
    var pressure := EnemyCombatController.get_movement_direction("pressure_brawler", player, enemy, 0.0)
    var guard := EnemyCombatController.get_movement_direction("counter_guard", player, enemy, 0.0)
    var skirmisher := EnemyCombatController.get_movement_direction("skirmisher", player, enemy, 0.0)
    _check(pressure.x > 0.9 and absf(pressure.y) < 0.01, "Pressure brawler should close distance directly.")
    _check(guard == Vector2.ZERO, "Counter guard should hold its preferred distance.")
    _check(skirmisher.length() > 0.9 and absf(skirmisher.x) < 0.9, "Skirmisher should orbit instead of charging directly.")
    _check(EnemyCombatController.get_recovery_duration("counter_guard") > EnemyCombatController.get_recovery_duration("pressure_brawler"), "Counter guard should have a longer punishable recovery.")
    _check(EnemyCombatController.get_recovery_duration("skirmisher") < EnemyCombatController.get_recovery_duration("pressure_brawler"), "Skirmisher should recover faster after its attack.")
    _check(EnemyCombatController.get_profile("unknown").get("movement") == "advance", "Unknown archetypes should safely fall back to pressure brawler.")

    if _failures.is_empty():
        print("PASS: enemy pressure, guard, skirmisher movement, and recovery profiles.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
