extends SceneTree

const SCENE_CASES := [
    {"path": "res://scenes/combat/CombatArena.tscn", "environment": "corner"},
    {"path": "res://scenes/combat/CombatShopfront.tscn", "environment": "shopfront"},
    {"path": "res://scenes/combat/CombatAlley.tscn", "environment": "alley"}
]

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    for test_case in SCENE_CASES:
        var scene_path := str(test_case["path"])
        var packed_scene := load(scene_path) as PackedScene
        if packed_scene == null:
            push_error("Combat environment scene could not be loaded: %s" % scene_path)
            quit(1)
            return
        var instance := packed_scene.instantiate()
        var actual_environment := str(instance.get("environment_kind"))
        instance.free()
        if actual_environment != str(test_case["environment"]):
            push_error("Combat scene %s expected %s but got %s." % [scene_path, str(test_case["environment"]), actual_environment])
            quit(1)
            return

    print("PASS: corner, shopfront, and alley combat scenes load with the correct environment.")
    quit(0)
