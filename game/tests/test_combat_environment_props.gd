extends SceneTree

# Location-specific combat prop regression coverage.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_combat_environment_props.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var corner_scene: PackedScene = load("res://scenes/combat/CombatArena.tscn")
    var shop_scene: PackedScene = load("res://scenes/combat/CombatShopfront.tscn")
    var alley_scene: PackedScene = load("res://scenes/combat/CombatAlley.tscn")

    var corner = corner_scene.instantiate()
    root.add_child(corner)
    await process_frame
    _check(corner.get_environment_prop_count() == 2, "Street-corner combat should include two location props.")
    _check(str(corner.environment_props[0]["kind"]) == "hydrant", "Street-corner props should include a hydrant.")
    corner.queue_free()

    var shop = shop_scene.instantiate()
    root.add_child(shop)
    await process_frame
    _check(shop.get_environment_prop_count() == 2, "Shopfront combat should include two location props.")
    _check(str(shop.environment_props[0]["kind"]) == "crate", "Shopfront props should include delivery clutter.")
    shop.player.position = Vector2(112, 252)
    shop.enemy.position = Vector2(690, 270)
    _check(shop._try_attack_environment_prop(25), "A nearby prop should receive a melee hit when closer than the enemy.")
    _check(int(shop.environment_props[0]["health"]) == 1, "A standard strike should damage a two-hit prop.")
    _check(shop._try_attack_environment_prop(45), "A heavy strike should be able to break the remaining prop health.")
    _check(shop.get_environment_prop_count() == 1, "Destroyed props should be removed from the active prop count.")
    shop.queue_free()

    var alley = alley_scene.instantiate()
    root.add_child(alley)
    await process_frame
    _check(alley.get_environment_prop_count() == 2, "Alley combat should include two location props.")
    for prop in alley.environment_props:
        var x := float(prop["position"].x)
        _check(x >= 210.0 and x <= 750.0, "Alley props should remain inside the playable horizontal bounds.")
    alley.queue_free()

    if _failures.is_empty():
        print("PASS: combat props are location-specific, attackable, and breakable.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
