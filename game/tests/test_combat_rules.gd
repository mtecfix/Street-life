extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var packed_scene := load("res://scenes/combat/CombatArena.tscn") as PackedScene
    if packed_scene == null:
        push_error("Combat rules test could not load CombatArena.tscn.")
        quit(1)
        return

    var combat := packed_scene.instantiate()
    var light_expected := [25, 29, 34]
    for combo_index in range(3):
        var actual := int(combat.call("get_combo_damage", 25, combo_index))
        if actual != int(light_expected[combo_index]):
            push_error("Combo damage mismatch at hit %d: expected %d, got %d." % [combo_index + 1, int(light_expected[combo_index]), actual])
            combat.free()
            quit(1)
            return

    var heavy_actual := int(combat.call("get_heavy_attack_damage", 25))
    combat.free()
    if heavy_actual != 45:
        push_error("Heavy attack damage mismatch: expected 45, got %d." % heavy_actual)
        quit(1)
        return

    print("PASS: three-hit combo scaling and heavy attack damage.")
    quit(0)
