extends SceneTree

# Run: godot --headless --path game --script res://tests/test_combat_skill_integration.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state: Variant = root.get_node_or_null("GameState")
    if state == null:
        push_error("Combat integration test could not find GameState.")
        quit(1)
        return
    var packed := load("res://scenes/combat/CombatArena.tscn") as PackedScene
    if packed == null:
        push_error("Combat arena scene failed to load.")
        quit(1)
        return
    var arena := packed.instantiate()
    root.add_child(arena)
    await process_frame

    arena.player.position = Vector2(250, 270)
    arena.enemy.position = Vector2(360, 270)
    arena.combat_style = "firearms"
    var starting_health: float = arena.enemy_health
    arena._firearm_attack()
    _check(arena.ammo_in_magazine == 11, "The 12-round sidearm should consume one magazine round.")
    _check(arena.enemy_health < starting_health, "An in-range firearm shot should damage the opponent.")

    arena.ammo_in_magazine = 0
    arena.reserve_ammo = 5
    arena._reload_firearm()
    _check(arena.reload_timer > 0.0, "Reload should enter a timed reload state.")
    arena.reload_timer = 0.01
    arena._process(0.02)
    _check(arena.ammo_in_magazine == 5 and arena.reserve_ammo == 0, "Reload should transfer only available reserve ammunition.")

    arena._cycle_firearm()
    _check(arena.active_weapon_id == "smg" and arena.ammo_in_magazine == 24, "Cycling to the SMG should load its independent magazine.")
    arena._cycle_firearm()
    _check(arena.active_weapon_id == "carbine" and arena.ammo_in_magazine == 20, "Cycling to the carbine should load its independent magazine.")
    arena._cycle_firearm()
    _check(arena.active_weapon_id == "sidearm" and arena.ammo_in_magazine == 5, "Returning to the sidearm should retain its magazine state.")
    _check(not arena._has_clear_shot(Vector2(40, 325), Vector2(150, 325)), "Arena cover should block a shot crossing its footprint.")

    state.combat_skill_unlocks = {"melee": ["guard_up", "counter_window", "body_shot"], "firearms": []}
    arena.combat_style = "melee"
    arena.player.position = Vector2(250, 270)
    arena.enemy.position = Vector2(300, 270)
    arena.facing_direction = Vector2.RIGHT
    arena.guard_timer = 0.5
    arena.telegraph_timer = 0.1
    var health_before_counter: float = arena.enemy_health
    arena._resolve_enemy_attack()
    _check(arena.enemy_health < health_before_counter, "A timed frontal guard with Counter Window should counterattack.")

    arena.attack_cooldown = 0.0
    var health_before_body_shot: float = arena.enemy_health
    arena._body_shot()
    _check(arena.enemy_health < health_before_body_shot, "Unlocked Body Shot should apply its special attack.")

    var ui_script = load("res://scripts/ui/combat_skill_tree_ui.gd")
    var ui: Control = ui_script.new()
    root.add_child(ui)
    await process_frame
    ui.toggle()
    _check(ui.visible, "Combat training UI should open when toggled.")
    ui.queue_free()
    arena.queue_free()

    state.combat_skill_unlocks = {"melee": [], "firearms": []}
    if _failures.is_empty():
        print("PASS: firearms, timed reload, melee guard/counter, body shot, and training UI integration.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
