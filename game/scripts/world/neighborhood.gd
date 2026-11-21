extends Node2D

const NPC_INTERACTION_RANGE := 76.0
const STORE_DOOR := Vector2(170, 174)
const APARTMENT_DOOR := Vector2(765, 174)
const JOB_SITE := Vector2(745, 270)

var status_label: Label
var hint_label: Label
var dialogue_label: Label
var time_label: Label
var inventory_label: Label
var npcs: Array[Dictionary] = []
var _last_schedule_minute := -1

func _ready() -> void:
    _build_collision()
    _build_npcs()
    var player := get_node_or_null("Player")
    if player:
        player.global_position = GameState.previous_world_position
    _build_hud()
    _sync_npc_schedules()
    _refresh_hud()
    if GameState.player_health <= 0:
        GameState.player_health = 35
        dialogue_label.text = "You got patched up at the clinic. Take it easy out there."

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("#202c2b"))
    # Main road and cross street.
    draw_rect(Rect2(0, 205, 960, 130), Color("#45494c"))
    draw_rect(Rect2(360, 0, 150, 540), Color("#45494c"))
    draw_rect(Rect2(0, 195, 960, 10), Color("#777b78"))
    draw_rect(Rect2(0, 335, 960, 10), Color("#777b78"))
    draw_rect(Rect2(350, 0, 10, 540), Color("#777b78"))
    draw_rect(Rect2(510, 0, 10, 540), Color("#777b78"))
    for i in range(7):
        draw_rect(Rect2(380 + i * 18, 210, 9, 28), Color("#d7d0b3"))
        draw_rect(Rect2(380 + i * 18, 302, 9, 28), Color("#d7d0b3"))

    # First authored block: storefront, apartments, homes and alley.
    draw_rect(Rect2(70, 55, 205, 105), Color("#6c594d"))
    draw_rect(Rect2(78, 64, 189, 82), Color("#8b7660"))
    draw_rect(Rect2(650, 55, 230, 105), Color("#5b646b"))
    draw_rect(Rect2(660, 64, 210, 82), Color("#78838b"))
    draw_rect(Rect2(665, 390, 205, 95), Color("#665b50"))
    draw_rect(Rect2(680, 405, 175, 65), Color("#897967"))
    draw_rect(Rect2(292, 360, 50, 145), Color("#4c5a4f"))
    draw_rect(Rect2(290, 350, 54, 12), Color("#9b8a6d"))
    draw_rect(Rect2(STORE_DOOR - Vector2(15, 8), Vector2(30, 16)), Color("#d9b66e"))
    draw_rect(Rect2(APARTMENT_DOOR - Vector2(15, 8), Vector2(30, 16)), Color("#8ec2d1"))
    draw_string(ThemeDB.fallback_font, Vector2(88, 92), "MAYA'S MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(88, 120), "GROCERIES  /  SUPPLIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f1d8aa"))
    draw_string(ThemeDB.fallback_font, Vector2(670, 92), "THE WALK-UPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(670, 120), "APARTMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d2e1e7"))
    draw_string(ThemeDB.fallback_font, Vector2(670, 430), "COMMUNITY COURT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

    # Active scheduled residents.
    for npc in npcs:
        if not bool(npc["active"]):
            continue
        var npc_position: Vector2 = npc["position"]
        draw_circle(npc_position, 14, npc["color"])
        draw_circle(npc_position + Vector2(0, -5), 6, Color("#f0d8b2"))
        draw_string(ThemeDB.fallback_font, npc_position + Vector2(-25, 31), str(npc["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

    draw_circle(JOB_SITE, 20, Color("#d78b43"))
    draw_circle(JOB_SITE, 9, Color("#f3d59b"))
    draw_string(ThemeDB.fallback_font, Vector2(690, 310), "JOB SITE  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _build_collision() -> void:
    _add_wall(Vector2(480, 8), Vector2(960, 16))
    _add_wall(Vector2(480, 532), Vector2(960, 16))
    _add_wall(Vector2(8, 270), Vector2(16, 540))
    _add_wall(Vector2(952, 270), Vector2(16, 540))
    _add_wall(Vector2(172, 160), Vector2(205, 12))
    _add_wall(Vector2(172, 55), Vector2(205, 12))
    _add_wall(Vector2(70, 107), Vector2(12, 105))
    _add_wall(Vector2(275, 107), Vector2(12, 105))
    _add_wall(Vector2(765, 160), Vector2(230, 12))
    _add_wall(Vector2(765, 55), Vector2(230, 12))
    _add_wall(Vector2(650, 107), Vector2(12, 105))
    _add_wall(Vector2(880, 107), Vector2(12, 105))

func _build_npcs() -> void:
    npcs = [
        {"id": "rico", "name": "RICO", "role": "Fixer", "position": Vector2(590, 270), "color": Color("#d8b45d"), "windows": [[8, 22]], "active": false},
        {"id": "maya", "name": "MAYA", "role": "Neighbor", "position": Vector2(565, 390), "color": Color("#d88baf"), "windows": [[6, 9], [17, 23]], "active": false},
        {"id": "dre", "name": "DRE", "role": "Local", "position": Vector2(700, 370), "color": Color("#78b89a"), "windows": [[14, 23]], "active": false}
    ]

func _build_hud() -> void:
    status_label = _make_label(Vector2(18, 14), 17, Color("#f0e7d2"))
    hint_label = _make_label(Vector2(18, 43), 13, Color("#c2ced1"))
    time_label = _make_label(Vector2(790, 14), 15, Color("#f0e7d2"))
    inventory_label = _make_label(Vector2(18, 72), 12, Color("#a9c8c9"))
    dialogue_label = _make_label(Vector2(18, 485), 14, Color("#f3d59b"))

func _make_label(label_position: Vector2, font_size: int, font_color: Color) -> Label:
    var label := Label.new()
    label.position = label_position
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", font_color)
    add_child(label)
    return label

func _process(_delta: float) -> void:
    var minute_stamp := WorldClock.total_minutes
    if minute_stamp != _last_schedule_minute:
        _last_schedule_minute = minute_stamp
        _sync_npc_schedules()
    _refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        _interact()
        return
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_F:
            _use_consumable("snack")
        KEY_H:
            _use_consumable("medkit")
        KEY_I:
            _show_inventory()
        KEY_ESCAPE:
            dialogue_label.text = ""

func _interact() -> void:
    var player := get_node_or_null("Player")
    if player == null:
        return
    var player_position: Vector2 = player.global_position

    if player_position.distance_to(STORE_DOOR) <= NPC_INTERACTION_RANGE:
        GameState.previous_world_position = player_position
        SceneManager.change_to("res://scenes/interiors/ShopInterior.tscn")
        return
    if player_position.distance_to(APARTMENT_DOOR) <= NPC_INTERACTION_RANGE:
        GameState.previous_world_position = player_position
        SceneManager.change_to("res://scenes/interiors/ApartmentInterior.tscn")
        return

    if GameState.mission_active and player_position.distance_to(JOB_SITE) <= NPC_INTERACTION_RANGE:
        GameState.previous_world_position = player_position
        GameState.last_combat_won = false
        EventBus.encounter_started.emit("corner_dispute")
        SceneManager.change_to("res://scenes/combat/CombatArena.tscn")
        return

    var nearest: Dictionary = {}
    var nearest_distance := NPC_INTERACTION_RANGE
    for npc in npcs:
        if not bool(npc["active"]):
            continue
        var distance: float = player_position.distance_to(npc["position"])
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = npc

    if nearest.is_empty():
        dialogue_label.text = "Nothing to interact with here. Check the shop, apartments, or find a local."
        return

    var npc_id := str(nearest["id"])
    EventBus.npc_interacted.emit(npc_id)
    if npc_id == "rico":
        if not GameState.mission_active and not GameState.mission_completed:
            GameState.mission_active = true
            GameState.adjust_relationship("rico", 5)
            dialogue_label.text = "Rico: A dispute is brewing at the corner. Handle it and come back. The job site is marked."
        elif GameState.mission_active:
            dialogue_label.text = "Rico: The corner is still waiting. Keep your guard up and come back after."
        else:
            dialogue_label.text = "Rico: Solid work. You got paid, and people noticed. I'll look for another opportunity."
    elif npc_id == "maya":
        GameState.adjust_relationship("maya", 2)
        GameState.adjust_reputation("locals", 1)
        dialogue_label.text = "Maya: Market's open. Keep some cash for supplies — and don't start trouble near the homes."
    else:
        GameState.adjust_relationship("dre", 1)
        dialogue_label.text = "Dre: The court gets busy after work. If Rico sends you out, watch the wind-up before you swing."
    SaveManager.save_game()

func _sync_npc_schedules() -> void:
    var hour := WorldClock.get_hour()
    for npc in npcs:
        var active := false
        for window in npc["windows"]:
            if hour >= int(window[0]) and hour < int(window[1]):
                active = true
                break
        npc["active"] = active
    queue_redraw()

func _use_consumable(item_id: String) -> void:
    if GameState.use_item(item_id):
        dialogue_label.text = "Used %s. Health is now %d/100." % [str(GameState.ITEM_DEFINITIONS[item_id]["name"]), GameState.player_health]
        SaveManager.save_game()
    else:
        dialogue_label.text = "No usable %s in your bag, or your health is already full." % item_id

func _show_inventory() -> void:
    var lines: Array[String] = []
    for item_id in GameState.ITEM_DEFINITIONS:
        lines.append("%s x%d" % [str(GameState.ITEM_DEFINITIONS[item_id]["name"]), int(GameState.inventory.get(item_id, 0))])
    dialogue_label.text = "BAG: %s" % "  |  ".join(lines)

func _refresh_hud() -> void:
    if status_label == null:
        return
    status_label.text = "STREET HUSTLER  |  $%d  |  HEALTH %d/100  |  DAY %d" % [GameState.player_cash, GameState.player_health, GameState.current_day]
    time_label.text = WorldClock.get_time_string()
    inventory_label.text = "BAG %d/%d  |  I: INVENTORY  F: SNACK  H: MEDKIT  |  E: INTERACT" % [GameState.get_inventory_count(), GameState.INVENTORY_CAPACITY]
    if GameState.mission_completed:
        hint_label.text = "JOB COMPLETE: Return to Rico for the next lead. Store and apartment doors are marked."
    elif GameState.mission_active:
        hint_label.text = "ACTIVE JOB: Head to the orange corner marker. Visit Maya's Market for supplies."
    else:
        hint_label.text = "Explore the block. Find Rico during the day, or enter Maya's Market and the walk-ups."
        
func _add_wall(center: Vector2, dimensions: Vector2) -> void:
    var wall := StaticBody2D.new()
    wall.position = center
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = dimensions
    collision.shape = rectangle
    wall.add_child(collision)
    add_child(wall)
