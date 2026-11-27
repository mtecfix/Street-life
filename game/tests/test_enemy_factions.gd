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

    _check(EnemyCombatController.get_faction_id_for_encounter("corner_brawler") == "corner_set", "Corner encounter should use Corner Set.")
    _check(EnemyCombatController.get_faction_id_for_encounter("shop_guard") == "market_crew", "Shopfront encounter should use Market Crew.")
    _check(EnemyCombatController.get_faction_id_for_encounter("alley_ambush") == "alley_runners", "Alley encounter should use Alley Runners.")
    _check(EnemyCombatController.get_faction_id_for_encounter("unknown") == "corner_set", "Unknown encounters should fall back to Corner Set.")

    var market_stats := EnemyCombatController.get_faction_adjusted_stats("market_crew", {
        "speed": 100.0, "damage": 20.0, "windup": 1.0
    })
    _check(is_equal_approx(float(market_stats["speed"]), 92.0), "Market Crew should move more deliberately.")
    _check(is_equal_approx(float(market_stats["damage"]), 22.4), "Market Crew should deal increased damage.")
    _check(is_equal_approx(float(market_stats["windup"]), 1.12), "Market Crew should telegraph attacks longer.")

    var runner_stats := EnemyCombatController.get_faction_adjusted_stats("alley_runners", {
        "speed": 100.0, "damage": 20.0, "windup": 1.0
    })
    _check(is_equal_approx(float(runner_stats["speed"]), 116.0), "Alley Runners should move faster.")
    _check(is_equal_approx(float(runner_stats["damage"]), 17.6), "Alley Runners should deal lighter damage.")
    _check(EnemyCombatController.get_faction_recovery_duration("pressure_brawler", "alley_runners") < EnemyCombatController.get_recovery_duration("pressure_brawler"), "Alley Runners should recover faster.")

    if _failures.is_empty():
        print("PASS: enemy archetypes, faction assignment, and faction combat modifiers.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
