extends Node2D

const NPC_INTERACTION_RANGE := 76.0
const STORE_DOOR := Vector2(170, 174)
const APARTMENT_DOOR := Vector2(765, 174)
const JOB_SITE := Vector2(745, 270)
const RESIDENT_SHEET := preload("res://assets/sprites/residents.svg")

var status_label: Label
var hint_label: Label
var dialogue_label: Label
var time_label: Label
var inventory_label: Label
var npcs: Array[Dictionary] = []
var _last_schedule_minute := -1
var mission_choice_pending := false
var training_menu_pending := false

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
    draw_rect(Rect2(0, 205, 960, 130), Color("#45494c"))
    draw_rect(Rect2(360, 0, 150, 540), Color("#45494c"))
    draw_rect(Rect2(0, 195, 960, 10), Color("#777b78"))
    draw_rect(Rect2(0, 335, 960, 10), Color("#777b78"))
    draw_rect(Rect2(350, 0, 10, 540), Color("#777b78"))
    draw_rect(Rect2(510, 0, 10, 540), Color("#777b78"))
    for i in range(7):
        draw_rect(Rect2(380 + i * 18, 210, 9, 28), Color("#d7d0b3"))
        draw_rect(Rect2(380 + i * 18, 302, 9, 28), Color("#d7d0b3"))

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

    for npc in npcs:
        if not bool(npc["active"]):
            continue
        var npc_position: Vector2 = npc["position"]
        var frame := int(npc["sprite"])
        draw_texture_rect_region(RESIDENT_SHEET, Rect2(npc_position - Vector2(16, 22), Vector2(32, 40)), Rect2(frame * 32, 0, 32, 40))
        draw_string(ThemeDB.fallback_font, npc_position + Vector2(-28, 30), str(npc["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

    var active_event := EventManager.get_active_event()
    if not active_event.is_empty():
        var event_position: Vector2 = active_event["position"]
        draw_circle(event_position, 22.0, Color(0.18, 0.78, 0.82, 0.25))
        draw_arc(event_position, 25.0, 0.0, TAU, 32, Color("#8ee8e6"), 3.0)
        draw_string(ThemeDB.fallback_font, event_position + Vector2(-50, -31), "EVENT  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#b8f4ec"))

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
        {"id": "rico", "name": "RICO", "role": "Fixer", "position": Vector2(590, 270), "color": Color("#d8b45d"), "sprite": 0, "windows": [[8, 22]], "active": false},
        {"id": "maya", "name": "MAYA", "role": "Neighbor", "position": Vector2(565, 390), "color": Color("#d88baf"), "sprite": 1, "windows": [[6, 9], [17, 23]], "active": false},
        {"id": "dre", "name": "DRE", "role": "Local", "position": Vector2(700, 370), "color": Color("#78b89a"), "sprite": 2, "windows": [[14, 23]], "active": false},
        {"id": "nia", "name": "NIA", "role": "Courier", "position": Vector2(320, 390), "color": Color("#c88b61"), "sprite": 3, "windows": [[7, 16]], "active": false},
        {"id": "coach", "name": "COACH", "role": "Mentor", "position": Vector2(825, 350), "color": Color("#9a9bd0"), "sprite": 4, "windows": [[6, 11], [16, 20]], "active": false}
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
    if training_menu_pending:
        if event.keycode == KEY_1:
            _purchase_training("power")
        elif event.keycode == KEY_2:
            _purchase_training("endurance")
        elif event.keycode == KEY_3:
            _purchase_training("footwork")
        elif event.keycode == KEY_ESCAPE:
            training_menu_pending = false
            dialogue_label.text = "Coach: Keep at it. We'll work when you're ready."
        return
    if mission_choice_pending:
        if event.keycode == KEY_1:
            _start_mission_encounter("corner_brawler")
        elif event.keycode == KEY_2:
            _start_mission_encounter("shop_guard")
        elif event.keycode == KEY_ESCAPE:
            mission_choice_pending = false
            dialogue_label.text = "Rico's job is still waiting at the corner."
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

    var active_event := EventManager.get_active_event()
    if not active_event.is_empty() and player_position.distance_to(active_event["position"]) <= NPC_INTERACTION_RANGE:
        var event_id := str(active_event["id"])
        if EventManager.complete_active_event(event_id):
            dialogue_label.text = EventManager.get_completion_message(event_id)
            queue_redraw()
        else:
            dialogue_label.text = "That neighborhood event has already passed."
        return

    if player_position.distance_to(STORE_DOOR) <= NPC_INTERACTION_RANGE:
        GameState.previous_world_position = player_position
        SceneManager.change_to("res://scenes/interiors/ShopInterior.tscn")
        return
    if player_position.distance_to(APARTMENT_DOOR) <= NPC_INTERACTION_RANGE:
        GameState.previous_world_position = player_position
        SceneManager.change_to("res://scenes/interiors/ApartmentInterior.tscn")
        return

    if GameState.mission_active and player_position.distance_to(JOB_SITE) <= NPC_INTERACTION_RANGE:
        if GameState.mission_choice.is_empty():
            mission_choice_pending = true
            dialogue_label.text = "Choose your approach: 1 STAND YOUR GROUND  |  2 PROTECT THE SHOP  |  ESC CANCEL"
        else:
            _start_mission_encounter("corner_brawler" if GameState.mission_choice == "confront" else "shop_guard")
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
        dialogue_label.text = "Nothing nearby. Check the market, apartments, or look for a resident."
        return

    var npc_id := str(nearest["id"])
    EventBus.npc_interacted.emit(npc_id)
    match npc_id:
        "rico":
            if not GameState.mission_active and not GameState.mission_completed:
                GameState.mission_active = true
                GameState.mission_choice = ""
                GameState.mission_outcome = ""
                GameState.adjust_relationship("rico", 5)
                dialogue_label.text = "Rico: Trouble at the corner. Settle it without forgetting who lives here. The site is marked."
            elif GameState.mission_active:
                dialogue_label.text = "Rico: Your call. Go to the orange marker and choose how to handle it."
            else:
                dialogue_label.text = "Rico: You handled that corner. Dre says there's movement in the alley after dark."
        "maya":
            GameState.adjust_relationship("maya", 2)
            GameState.adjust_reputation("locals", 1)
            dialogue_label.text = "Maya: Keep the storefront safe and the neighbors will remember. Supplies are inside."
        "dre":
            if GameState.mission_completed and not bool(GameState.world_flags.get("alley_encounter_completed", false)):
                GameState.current_encounter_id = "alley_ambush"
                GameState.previous_world_position = player_position
                EventBus.encounter_started.emit("alley_ambush")
                dialogue_label.text = "Dre: Two guys are cutting through the alley. Don't let them corner you."
                SaveManager.save_game()
                SceneManager.change_to("res://scenes/combat/CombatArena.tscn")
                return
            GameState.adjust_relationship("dre", 1)
            dialogue_label.text = "Dre: The court gets busy after work. Watch their feet before they swing."
        "nia":
            GameState.adjust_relationship("nia", 2)
            GameState.adjust_reputation("locals", 1)
            dialogue_label.text = "Nia: I run packages all over this block. The back alley gets sketchy after sunset."
        "coach":
            GameState.adjust_relationship("coach", 2)
            training_menu_pending = true
            dialogue_label.text = _training_menu_text()
    SaveManager.save_game()

func _start_mission_encounter(encounter_id: String) -> void:
    mission_choice_pending = false
    GameState.mission_choice = "confront" if encounter_id == "corner_brawler" else "protect"
    GameState.current_encounter_id = encounter_id
    GameState.previous_world_position = get_node("Player").global_position
    GameState.last_combat_won = false
    EventBus.encounter_started.emit(encounter_id)
    SaveManager.save_game()
    SceneManager.change_to("res://scenes/combat/CombatArena.tscn")

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
    status_label.text = "STREET HUSTLER  |  LV %d XP %d/%d SP %d  |  $%d  |  HEALTH %d/100  |  DAY %d" % [GameState.player_level, GameState.player_xp, GameState.xp_required_for_next_level(), GameState.skill_points, GameState.player_cash, GameState.player_health, GameState.current_day]
    time_label.text = WorldClock.get_time_string()
    inventory_label.text = "BAG %d/%d  |  I: INVENTORY  F: SNACK  H: MEDKIT  |  E: INTERACT" % [GameState.get_inventory_count(), GameState.INVENTORY_CAPACITY]
    var active_event := EventManager.get_active_event()
    if not active_event.is_empty():
        hint_label.text = "EVENT: %s — %s" % [str(active_event["title"]), str(active_event["hours"])]
    elif GameState.mission_completed and not bool(GameState.world_flags.get("alley_encounter_completed", false)):
        hint_label.text = "JOB COMPLETE: Talk to Dre after 2 PM to investigate the alley."
    elif GameState.mission_completed:
        hint_label.text = "BLOCK SECURED: Residents know your name. Explore the neighborhood."
    elif GameState.mission_active:
        hint_label.text = "ACTIVE JOB: Visit the orange marker and choose your approach."
    else:
        hint_label.text = "Meet Rico, Maya, Dre, Nia and Coach. Their schedules change through the day."

func _add_wall(center: Vector2, dimensions: Vector2) -> void:
    var wall := StaticBody2D.new()
    wall.position = center
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = dimensions
    collision.shape = rectangle
    wall.add_child(collision)
    add_child(wall)


func _training_menu_text() -> String:
    return "COACH — SKILL POINTS: %d  |  1 POWER %d/3  |  2 ENDURANCE %d/3  |  3 FOOTWORK %d/3  |  ESC CLOSE" % [
        GameState.skill_points,
        int(GameState.skill_levels.get("power", 0)),
        int(GameState.skill_levels.get("endurance", 0)),
        int(GameState.skill_levels.get("footwork", 0))
    ]

func _purchase_training(skill_id: String) -> void:
    var skill_names := {"power": "POWER", "endurance": "ENDURANCE", "footwork": "FOOTWORK"}
    if GameState.train_skill(skill_id):
        dialogue_label.text = "Coach: %s upgraded. Your training is saved." % str(skill_names[skill_id])
        SaveManager.save_game()
    else:
        dialogue_label.text = "Coach: You need a skill point, and each discipline tops out at rank 3."
    if GameState.skill_points > 0:
        dialogue_label.text += "  " + _training_menu_text()
    else:
        training_menu_pending = false
