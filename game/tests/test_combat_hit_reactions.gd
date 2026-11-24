extends SceneTree

# Combat impact feedback regression coverage.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_combat_hit_reactions.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Autoloads are resolved from the tree at runtime. A script launched with
    # --script is compiled before autoloads are registered, so referring to
    # GameState by bare name fails with "Identifier not found".
    var state: Variant = root.get_node_or_null("GameState")
    if state == null:
        push_error("Combat hit reaction test could not find the GameState autoload.")
        quit(1)
        return

    state.current_encounter_id = "corner_brawler"
    state.player_health = 100
    var scene: PackedScene = load("res://scenes/combat/CombatArena.tscn")
    var combat = scene.instantiate()
    root.add_child(combat)
    await process_frame

    combat.player.position = Vector2(400, 270)
    combat.enemy.position = Vector2(450, 270)
    var initial_health: float = combat.enemy_health
    combat._apply_enemy_hit(25, 135.0, 0.16)

    _check(combat.enemy_health == initial_health - 25.0, "A landed hit should reduce enemy health exactly once.")
    _check(combat.enemy_hitstun_timer >= 0.16, "A landed hit should briefly stun the enemy.")
    _check(combat.enemy_knockback_velocity.x > 0.0, "The enemy should be pushed away from the player.")
    _check(combat.hit_flash_timer > 0.0, "A landed hit should trigger visual impact feedback.")
    _check(combat.enemy_recoil_timer > 0.0, "A landed hit should trigger a visible recoil pose.")
    _check(combat.enemy_swing_timer == 0.0, "A hit should interrupt the enemy's active attack animation.")
    combat.player_swing_duration = 0.18
    combat.player_swing_timer = combat.player_swing_duration
    combat._update_combat_animation()
    _check(combat.player.scale.x > 1.0, "The player attack animation should visibly wind into its strike.")

    combat.player.position = Vector2(400, 270)
    combat.enemy.position = Vector2(450, 270)
    combat.player_health = 100.0
    combat.enemy_damage = 18.0
    combat._resolve_enemy_attack()
    _check(combat.player_health == 82.0, "A successful enemy strike should apply its damage.")
    _check(combat.player_knockback_velocity.x < 0.0, "A successful enemy strike should push the player away.")
    _check(combat.player_hit_flash_timer > 0.0, "A successful enemy strike should trigger player hit feedback.")
    _check(combat.enemy_swing_timer > 0.0, "An enemy attack should trigger its own strike animation.")

    combat.queue_free()
    if _failures.is_empty():
        print("PASS: combat hit reactions apply damage, stun, knockback, and impact feedback.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
