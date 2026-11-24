extends SceneTree

# Encounter archetype regression coverage.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_combat_enemy_styles.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _make_combat(encounter_id: String):
    # Autoloads are resolved from the tree at runtime. A script launched with
    # --script is compiled before autoloads are registered, so referring to
    # GameState by bare name fails with "Identifier not found".
    var state: Variant = root.get_node_or_null("GameState")
    if state == null:
        push_error("Combat enemy style test could not find the GameState autoload.")
        quit(1)
        return null
    state.current_encounter_id = encounter_id
    var packed: PackedScene = load("res://scenes/combat/CombatArena.tscn")
    var instance = packed.instantiate()
    root.add_child(instance)
    await process_frame
    return instance

func _run() -> void:
    var pressure = await _make_combat("corner_brawler")
    _check(pressure.enemy_style == "pressure", "Corner challenger should use pressure archetype.")
    pressure.player.position = Vector2(400, 270)
    pressure.enemy.position = Vector2(450, 270)
    pressure._update_enemy_positioning(0.1, 50.0)
    _check(pressure.enemy.position.x < 450.0, "Pressure fighter should close distance.")
    pressure.queue_free()

    var guard = await _make_combat("shop_guard")
    _check(guard.enemy_style == "guard", "Shopfront agitator should use guard archetype.")
    guard.player.position = Vector2(400, 270)
    guard.enemy.position = Vector2(440, 270)
    guard._update_enemy_positioning(0.1, 40.0)
    _check(guard.enemy.position.x > 440.0, "Guard should create space when the player crowds it.")
    guard.enemy_attack_sequence = 2
    guard._start_enemy_telegraph()
    _check(guard.enemy_attack_kind == "heavy", "Guard should periodically telegraph a heavy strike.")
    _check(guard.telegraph.color.r > guard.telegraph.color.g, "Heavy strike warning should use a distinct warning color.")
    guard.queue_free()

    var runner = await _make_combat("alley_ambush")
    _check(runner.enemy_style == "runner", "Alley runner should use runner archetype.")
    runner.enemy_attack_sequence = 2
    runner._start_enemy_telegraph()
    _check(runner.enemy_feint_active, "Runner should periodically use a feint.")
    var feint_health: float = runner.player_health
    runner._resolve_enemy_feint()
    _check(is_equal_approx(runner.player_health, feint_health), "A feint must not deal damage.")
    _check(runner.enemy_recovery > 0.0, "A completed feint should leave a punishable recovery window.")
    runner.player.position = Vector2(400, 270)
    runner.enemy.position = Vector2(450, 270)
    runner._update_enemy_positioning(0.1, 50.0)
    _check(runner.enemy.position.x > 450.0, "Runner should retreat when the player gets close.")
    runner.enemy.position = Vector2(520, 270)
    runner.player.position = Vector2(400, 270)
    runner.enemy_attack_cooldown_timer = 0.0
    runner.telegraph_timer = 0.01
    runner.telegraph = Polygon2D.new()
    runner.add_child(runner.telegraph)
    var before_rush: float = runner.enemy.position.x
    runner._resolve_enemy_attack()
    _check(runner.enemy.position.x < before_rush, "Runner should lunge toward the player when its warning resolves.")
    _check(runner.enemy_attack_cooldown_timer > 0.0, "A resolved attack should start its attack cooldown.")
    runner.queue_free()

    if _failures.is_empty():
        print("PASS: pressure, guard, and runner combat archetypes behave differently.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
