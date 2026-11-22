extends Node

## Read-only state publisher for automated browser tests.
## Inert unless the web build is opened with ?debug=1. It never changes game state,
## so the test run observes exactly what a player would experience.

const PUBLISH_INTERVAL_SECONDS := 0.2

var _elapsed: float = 0.0

func _ready() -> void:
    set_process(false)
    if not OS.has_feature("web"):
        return
    var flag: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('debug') || ''", true)
    if str(flag) == "1":
        set_process(true)

func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed < PUBLISH_INTERVAL_SECONDS:
        return
    _elapsed = 0.0
    # Stringify twice so the snapshot becomes a quoted, fully escaped JS string
    # literal; the page parses it back with JSON.parse().
    var literal := JSON.stringify(JSON.stringify(_snapshot()))
    JavaScriptBridge.eval("window.__streetLifeState = %s;" % literal, true)

func _snapshot() -> Dictionary:
    var scene := get_tree().current_scene
    var data := {
        "scene": scene.scene_file_path if scene else "",
        "cash": GameState.player_cash,
        "health": GameState.player_health,
        "day": GameState.current_day,
        "total_minutes": WorldClock.total_minutes,
        "clock": WorldClock.get_time_string(),
        "encounters_won": GameState.encounters_won,
        "level": GameState.player_level,
        "xp": GameState.player_xp,
        "skill_points": GameState.skill_points,
        "skill_levels": GameState.skill_levels.duplicate(true),
        "encounter_id": GameState.current_encounter_id,
        "mission_active": GameState.mission_active,
        "mission_completed": GameState.mission_completed,
        "mission_choice": GameState.mission_choice,
        "mission_outcome": GameState.mission_outcome,
        "inventory": GameState.inventory.duplicate(true),
        "reputation": GameState.reputation.duplicate(true),
        "relationships": GameState.npc_relationships.duplicate(true),
        "flags": GameState.world_flags.duplicate(true),
        "previous_position": _vector_to_array(GameState.previous_world_position)
    }
    if scene:
        data["details"] = _scene_details(scene)
    return data

func _scene_details(scene: Node) -> Dictionary:
    var details := {}
    var actor: Variant = scene.get("player")
    if not actor is Node2D:
        actor = scene.get_node_or_null("Player")
    if actor is Node2D:
        details["player_position"] = _vector_to_array(actor.global_position)

    for label_name in ["status_label", "dialogue_label", "hint_label", "detail_label", "status"]:
        var label: Variant = scene.get(label_name)
        if label is Label:
            details[label_name] = label.text

    var enemy_node: Variant = scene.get("enemy")
    if enemy_node is Node2D:
        details["enemy_position"] = _vector_to_array(enemy_node.global_position)
    for key in ["enemy_health", "player_health", "stamina", "finished", "enemy_name", "mission_choice_pending"]:
        var value: Variant = scene.get(key)
        if value != null:
            details[key] = value

    var residents: Variant = scene.get("npcs")
    if residents is Array:
        var summary: Array = []
        for resident in residents:
            summary.append({
                "id": str(resident["id"]),
                "active": bool(resident["active"]),
                "position": _vector_to_array(resident["position"])
            })
        details["npcs"] = summary
    return details

func _vector_to_array(value: Vector2) -> Array:
    return [snappedf(value.x, 0.1), snappedf(value.y, 0.1)]
