extends SceneTree

# Run: godot --headless --path game --script res://tests/test_weapon_inventory.gd

const SAVE_PATH := "user://savegame.json"
var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state: Variant = root.get_node_or_null("GameState")
    var saves: Variant = root.get_node_or_null("SaveManager")
    if state == null or saves == null:
        push_error("Weapon inventory test could not find required autoloads.")
        quit(1)
        return

    var original_save := FileAccess.get_file_as_string(SAVE_PATH) if FileAccess.file_exists(SAVE_PATH) else ""
    var snapshot := {
        "cash": state.player_cash,
        "owned": state.owned_weapons.duplicate(true),
        "equipped": state.equipped_weapon_id,
        "ammo": state.weapon_ammo.duplicate(true)
    }

    state.player_cash = 1000
    state.owned_weapons = ["sidearm"]
    state.equipped_weapon_id = "sidearm"
    state.weapon_ammo = {
        "sidearm": {"magazine": 12, "reserve": 48},
        "smg": {"magazine": 24, "reserve": 96},
        "carbine": {"magazine": 20, "reserve": 80}
    }
    _check(not state.purchase_weapon("unknown"), "Unknown weapons must not be purchasable.")
    _check(state.purchase_weapon("smg"), "Player should be able to purchase the SMG with sufficient cash.")
    _check(state.equipped_weapon_id == "smg", "Newly purchased firearm should auto-equip.")
    _check(not state.purchase_weapon("smg"), "Duplicate firearm purchases must be rejected.")
    _check(state.purchase_weapon("carbine"), "Player should be able to purchase the carbine.")
    _check(state.player_cash == 500, "Weapon purchases should deduct their exact listed prices.")
    _check(state.equip_weapon("sidearm"), "Player should be able to equip an owned sidearm.")
    _check(not state.equip_weapon("unknown"), "Player must not equip an unknown weapon.")
    state.set_weapon_ammo("smg", 7, 31)
    _check(saves.save_game() == OK, "Weapon ownership and ammo should save.")
    state.owned_weapons = ["sidearm"]
    state.equipped_weapon_id = "sidearm"
    state.weapon_ammo = {}
    _check(saves.load_game() == OK, "Weapon ownership and ammo should load.")
    _check("smg" in state.owned_weapons and "carbine" in state.owned_weapons, "Purchased firearms did not persist.")
    _check(state.equipped_weapon_id == "sidearm", "Equipped weapon did not persist.")
    var restored_ammo: Dictionary = state.get_weapon_ammo("smg")
    _check(int(restored_ammo["magazine"]) == 7 and int(restored_ammo["reserve"]) == 31, "Weapon magazine and reserve ammo did not persist.")

    state.player_cash = snapshot["cash"]
    state.owned_weapons = snapshot["owned"]
    state.equipped_weapon_id = snapshot["equipped"]
    state.weapon_ammo = snapshot["ammo"]
    if original_save.is_empty():
        if FileAccess.file_exists(SAVE_PATH):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    else:
        var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if file != null:
            file.store_string(original_save)

    if _failures.is_empty():
        print("PASS: weapon purchase, ownership, equip rules, ammunition persistence, and save migration.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
