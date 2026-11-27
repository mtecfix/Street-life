extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 7

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        save_game()

func save_game() -> Error:
    var payload := {
        "version": SAVE_VERSION,
        "player_cash": GameState.player_cash,
        "player_health": GameState.player_health,
        "encounters_won": GameState.encounters_won,
        "player_xp": GameState.player_xp,
        "player_level": GameState.player_level,
        "skill_points": GameState.skill_points,
        "skill_levels": GameState.skill_levels.duplicate(true),
        "combat_skill_unlocks": GameState.combat_skill_unlocks.duplicate(true),
        "world_day": GameState.current_day,
        "world_minutes": WorldClock.total_minutes,
        "mission_active": GameState.mission_active,
        "mission_completed": GameState.mission_completed,
        "mission_choice": GameState.mission_choice,
        "mission_outcome": GameState.mission_outcome,
        "previous_world_position": [GameState.previous_world_position.x, GameState.previous_world_position.y],
        "inventory": GameState.inventory.duplicate(true),
        "owned_weapons": GameState.owned_weapons.duplicate(true),
        "equipped_weapon_id": GameState.equipped_weapon_id,
        "weapon_ammo": GameState.weapon_ammo.duplicate(true),
        "reputation": GameState.reputation.duplicate(true),
        "npc_relationships": GameState.npc_relationships.duplicate(true),
        "world_flags": GameState.world_flags.duplicate(true)
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(payload))
    return OK

func load_game() -> Error:
    if not FileAccess.file_exists(SAVE_PATH):
        return ERR_FILE_NOT_FOUND
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return FileAccess.get_open_error()

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return ERR_PARSE_ERROR

    var data: Dictionary = parsed
    var version := int(data.get("version", 0))
    if version < 1 or version > SAVE_VERSION:
        return ERR_INVALID_DATA

    GameState.player_cash = maxi(0, int(data.get("player_cash", 25)))
    GameState.player_health = clampi(int(data.get("player_health", 100)), 0, 100)
    GameState.encounters_won = maxi(0, int(data.get("encounters_won", 0)))
    GameState.player_xp = maxi(0, int(data.get("player_xp", 0)))
    GameState.player_level = maxi(1, int(data.get("player_level", 1)))
    GameState.skill_points = maxi(0, int(data.get("skill_points", 0)))
    _restore_integer_dictionary(GameState.skill_levels, data.get("skill_levels", {"power": 0, "endurance": 0, "footwork": 0}), false)
    for skill_id in ["power", "endurance", "footwork"]:
        GameState.skill_levels[skill_id] = clampi(int(GameState.skill_levels.get(skill_id, 0)), 0, 3)
    _restore_combat_skill_unlocks(data.get("combat_skill_unlocks", {}))
    WorldClock.total_minutes = maxi(0, int(data.get("world_minutes", 480)))
    GameState.current_day = int(WorldClock.total_minutes / 1440) + 1
    GameState.mission_active = bool(data.get("mission_active", false))
    GameState.mission_completed = bool(data.get("mission_completed", false))
    GameState.mission_choice = str(data.get("mission_choice", ""))
    GameState.mission_outcome = str(data.get("mission_outcome", ""))

    var saved_position: Variant = data.get("previous_world_position", [480.0, 270.0])
    if saved_position is Array and saved_position.size() == 2:
        GameState.previous_world_position = Vector2(float(saved_position[0]), float(saved_position[1]))

    _restore_integer_dictionary(GameState.inventory, data.get("inventory", {}), true)
    _restore_weapon_inventory(data)
    _restore_integer_dictionary(GameState.reputation, data.get("reputation", {"locals": 0, "rivals": 0}), false)
    _restore_integer_dictionary(GameState.npc_relationships, data.get("npc_relationships", {}), false)
    var saved_flags: Variant = data.get("world_flags", {})
    if saved_flags is Dictionary:
        GameState.world_flags = saved_flags.duplicate(true)
    return OK

func _restore_integer_dictionary(target: Dictionary, source: Variant, positive_only: bool) -> void:
    target.clear()
    if not source is Dictionary:
        return
    for key in source:
        var value := int(source[key])
        if not positive_only or value > 0:
            target[str(key)] = value


func _restore_weapon_inventory(data: Dictionary) -> void:
    GameState.owned_weapons = ["sidearm"]
    var saved_owned: Variant = data.get("owned_weapons", ["sidearm"])
    if saved_owned is Array:
        for weapon_id in saved_owned:
            var id := str(weapon_id)
            if id == "sidearm" or GameState.WEAPON_SHOP.has(id):
                if id not in GameState.owned_weapons:
                    GameState.owned_weapons.append(id)
    GameState.weapon_ammo = {
        "sidearm": {"magazine": 12, "reserve": 48},
        "smg": {"magazine": 24, "reserve": 96},
        "carbine": {"magazine": 20, "reserve": 80}
    }
    var saved_ammo: Variant = data.get("weapon_ammo", {})
    if saved_ammo is Dictionary:
        for weapon_id in GameState.owned_weapons:
            var profile := FirearmCombatController.get_profile(str(weapon_id))
            var values: Variant = saved_ammo.get(weapon_id, {})
            if values is Dictionary:
                GameState.weapon_ammo[weapon_id] = {
                    "magazine": clampi(int(values.get("magazine", profile["magazine"])), 0, int(profile["magazine"])),
                    "reserve": maxi(0, int(values.get("reserve", profile["reserve_start"])))
                }
    var equipped := str(data.get("equipped_weapon_id", "sidearm"))
    GameState.equipped_weapon_id = equipped if equipped in GameState.owned_weapons else "sidearm"

func _restore_combat_skill_unlocks(source: Variant) -> void:
    GameState.combat_skill_unlocks = {"melee": [], "firearms": []}
    if not source is Dictionary:
        return
    for style in ["melee", "firearms"]:
        var tree: Dictionary = CombatSkillTrees.get_tree(style)
        var nodes: Dictionary = tree.get("nodes", {})
        var saved: Variant = source.get(style, [])
        if not saved is Array:
            continue
        for node_id in saved:
            var id := str(node_id)
            if nodes.has(id) and id not in GameState.combat_skill_unlocks[style]:
                GameState.combat_skill_unlocks[style].append(id)
