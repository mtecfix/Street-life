extends Node2D

const NPC_INTERACTION_RANGE := 76.0
const STORE_DOOR := Vector2(170, 174)
const APARTMENT_DOOR := Vector2(765, 174)
const JOB_SITE := Vector2(300, 220)
const RESIDENT_SHEET := preload("res://assets/sprites/residents.svg")
const INVENTORY_PANEL_SCRIPT := preload("res://scripts/ui/inventory_panel.gd")

var status_label: Label
var hint_label: Label
var dialogue_label: Label
var time_label: Label
var inventory_label: Label
var reputation_label: Label
var inventory_panel: CanvasLayer
var npcs: Array[Dictionary] = []
var _last_schedule_minute := -1
var mission_choice_pending := false
var training_menu_pending := false
var hustle_menu_pending := false

func _ready() -> void:
    _build_collision()
    _build_npcs()
    var player := get_node_or_null("Player")
    if player:
        player.global_position = GameState.previous_world_position
    _build_hud()
    inventory_panel = INVENTORY_PANEL_SCRIPT.new()
    add_child(inventory_panel)
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

    _draw_block_building(Vector2(70, 55), Vector2(205, 105), Color("#8b7660"), Color("#51443e"), Color("#b28d69"), 3)
    _draw_block_building(Vector2(650, 55), Vector2(230, 105), Color("#78838b"), Color("#424b52"), Color("#a9b4b8"), 4)
    _draw_block_building(Vector2(665, 390), Vector2(205, 95), Color("#897967"), Color("#4c4540"), Color("#b09a7d"), 3)
    _draw_storefront_facades()
    _draw_fire_escape(Vector2(842, 55))
    _draw_court_fence()
    _draw_parking_details()
    _draw_utility_poles_and_wires()
    _draw_property_boundaries()
    _draw_alley_service_area()
    _draw_loading_zone()
    _draw_building_rooftops()
    _draw_polygon([Vector2(292, 360), Vector2(342, 360), Vector2(342, 505), Vector2(292, 505)], Color("#4c5a4f"))
    _draw_polygon([Vector2(286, 350), Vector2(348, 350), Vector2(342, 363), Vector2(292, 363)], Color("#9b8a6d"))
    _draw_polygon([STORE_DOOR + Vector2(-15, -8), STORE_DOOR + Vector2(15, -8), STORE_DOOR + Vector2(19, 8), STORE_DOOR + Vector2(-19, 8)], Color("#d9b66e"))
    _draw_polygon([APARTMENT_DOOR + Vector2(-15, -8), APARTMENT_DOOR + Vector2(15, -8), APARTMENT_DOOR + Vector2(19, 8), APARTMENT_DOOR + Vector2(-19, 8)], Color("#8ec2d1"))

    # Street dressing is deliberately drawn as a replaceable visual layer.
    _draw_sidewalk_details()
    _draw_street_furniture()
    _draw_street_trees()
    _draw_utility_fixtures()
    draw_string(ThemeDB.fallback_font, Vector2(88, 92), "MAYA'S MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(88, 120), "GROCERIES  /  SUPPLIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f1d8aa"))
    draw_string(ThemeDB.fallback_font, Vector2(670, 92), "THE WALK-UPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(670, 120), "APARTMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d2e1e7"))
    draw_string(ThemeDB.fallback_font, Vector2(670, 430), "COMMUNITY COURT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

    # Traffic is simulated by the persistent autoload, not this scene.
    var signal_state := WorldSimulation.get_traffic_signal_state()
    draw_circle(Vector2(430, 185), 5.0, Color("#57c978") if signal_state == "horizontal" else Color("#bd4545"))
    draw_circle(Vector2(520, 270), 5.0, Color("#57c978") if signal_state == "vertical" else Color("#bd4545"))
    for vehicle in WorldSimulation.get_traffic_snapshot():
        var vehicle_position: Vector2 = vehicle["position"]
        var vehicle_length := float(vehicle["length"])
        var vehicle_color: Color = vehicle["color"]
        _draw_vehicle_block(vehicle_position, vehicle_length, vehicle_color, str(vehicle["axis"]))
        if bool(vehicle["stopped"]):
            draw_circle(vehicle_position + (Vector2(-vehicle_length * 0.5, 0) if str(vehicle["axis"]) == "horizontal" else Vector2(0, -vehicle_length * 0.5)), 2.0, Color("#e75d50"))

    # Morning supplier delivery is a scheduled city agent, not an instant stock reset.
    var delivery := WorldSimulation.get_business_delivery_snapshot("mayas_market")
    if bool(delivery.get("active", false)):
        var van_position: Vector2 = delivery["position"]
        _draw_delivery_van(van_position)
        draw_string(ThemeDB.fallback_font, van_position + Vector2(-17, 3), "SUPPLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#263238"))
        if bool(delivery.get("unloading", false)):
            var worker_position: Vector2 = delivery["worker_position"]
            draw_circle(worker_position, 5.0, Color("#e1b77d"))
            draw_rect(Rect2(worker_position + Vector2(-4, 4), Vector2(8, 12)), Color("#d5a34e"))
            draw_rect(Rect2(worker_position + Vector2(5, 2), Vector2(7, 8)), Color("#9b7650"))
        draw_string(ThemeDB.fallback_font, Vector2(75, 245), "MORNING DELIVERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#f1d8aa"))

    # Tasha works the market counter during the daytime shift.
    var market_state := WorldSimulation.get_business_snapshot("mayas_market")
    if bool(market_state.get("employee_on_shift", false)):
        draw_texture_rect_region(RESIDENT_SHEET, Rect2(Vector2(170, 174) - Vector2(10, 15), Vector2(20, 30)), Rect2(4 * 32, 0, 32, 40))
        draw_string(ThemeDB.fallback_font, Vector2(181, 163), "TASHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f1d8aa"))

    # Maya's Market foot traffic is part of the persistent city simulation.
    for customer in WorldSimulation.get_business_visitors():
        var customer_position: Vector2 = customer["position"]
        var customer_frame := int(customer["sprite"])
        draw_texture_rect_region(RESIDENT_SHEET, Rect2(customer_position - Vector2(9, 13), Vector2(18, 26)), Rect2(customer_frame * 32, 0, 32, 40))

    # Ambient pedestrians are independent background agents. Their route
    # positions come from persistent world time, not scene-local movement.
    for pedestrian in WorldSimulation.get_ambient_pedestrians():
        var pedestrian_position: Vector2 = pedestrian["position"]
        var pedestrian_frame := int(pedestrian["sprite"])
        draw_texture_rect_region(RESIDENT_SHEET, Rect2(pedestrian_position - Vector2(11, 16), Vector2(22, 30)), Rect2(pedestrian_frame * 32, 0, 32, 40))

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

    var active_hustle := HustleManager.get_active_hustle()
    if not active_hustle.is_empty():
        var target_position: Vector2 = active_hustle["target_position"]
        draw_circle(target_position, 20.0, Color(0.95, 0.72, 0.24, 0.22))
        draw_arc(target_position, 24.0, 0.0, TAU, 32, Color("#f5c65b"), 3.0)
        draw_string(ThemeDB.fallback_font, target_position + Vector2(-42, -30), "DROP  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffe39b"))

    draw_circle(JOB_SITE, 20, Color("#d78b43"))
    draw_circle(JOB_SITE, 9, Color("#f3d59b"))
    draw_string(ThemeDB.fallback_font, JOB_SITE + Vector2(-48, 38), "CORNER JOB  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _draw_polygon(points: PackedVector2Array, fill: Color, outline: Color = Color("#252b2d"), width: float = 2.0) -> void:
    draw_colored_polygon(points, fill)
    var closed_points := points.duplicate()
    closed_points.append(points[0])
    draw_polyline(closed_points, outline, width, true)


func _draw_block_building(origin: Vector2, size: Vector2, wall_color: Color, shadow_color: Color, trim_color: Color, window_columns: int) -> void:
    var x := origin.x
    var y := origin.y
    var w := size.x
    var h := size.y
    _draw_polygon([Vector2(x + 9, y), Vector2(x + w - 12, y), Vector2(x + w, y + 13), Vector2(x, y + 13)], shadow_color)
    _draw_polygon([Vector2(x, y + 13), Vector2(x + w, y + 13), Vector2(x + w - 5, y + h), Vector2(x + 5, y + h)], wall_color)
    draw_line(Vector2(x + 5, y + h - 3), Vector2(x + w - 5, y + h - 3), trim_color, 4.0)
    var gap := (w - 34.0) / float(maxi(1, window_columns))
    for column in range(window_columns):
        var wx := x + 17.0 + float(column) * gap
        var window_points := PackedVector2Array([
            Vector2(wx, y + 34), Vector2(wx + 24, y + 34),
            Vector2(wx + 22, y + 65), Vector2(wx + 2, y + 65)
        ])
        _draw_polygon(window_points, Color("#344d59"), trim_color, 1.5)
        draw_line(Vector2(wx + 12, y + 35), Vector2(wx + 11, y + 64), trim_color, 2.0)
    _draw_polygon([
        Vector2(x + 4, y + h - 20), Vector2(x + 30, y + h - 20),
        Vector2(x + 29, y + h), Vector2(x + 5, y + h)
    ], shadow_color, trim_color, 1.5)


func _draw_vehicle_block(center: Vector2, length: float, body_color: Color, axis: String) -> void:
    var half_length := length * 0.5
    var points := PackedVector2Array()
    var glass := PackedVector2Array()
    if axis == "horizontal":
        points = PackedVector2Array([
            center + Vector2(-half_length, -5), center + Vector2(-half_length + 7, -8),
            center + Vector2(half_length - 6, -8), center + Vector2(half_length, -4),
            center + Vector2(half_length, 5), center + Vector2(-half_length, 5)
        ])
        glass = PackedVector2Array([
            center + Vector2(-half_length + 8, -6), center + Vector2(half_length - 8, -6),
            center + Vector2(half_length - 11, 2), center + Vector2(-half_length + 10, 2)
        ])
    else:
        points = PackedVector2Array([
            center + Vector2(-5, -half_length), center + Vector2(5, -half_length),
            center + Vector2(8, -half_length + 7), center + Vector2(8, half_length - 6),
            center + Vector2(5, half_length), center + Vector2(-5, half_length),
            center + Vector2(-8, half_length - 6), center + Vector2(-8, -half_length + 7)
        ])
        glass = PackedVector2Array([
            center + Vector2(-5, -half_length + 9), center + Vector2(5, -half_length + 9),
            center + Vector2(5, half_length - 9), center + Vector2(-5, half_length - 9)
        ])
    _draw_polygon(points, body_color, Color("#202629"), 1.5)
    draw_colored_polygon(glass, Color("#b9c9cc"))
    draw_line(glass[0], glass[1], Color("#e0e7df"), 1.0)


func _draw_delivery_van(center: Vector2) -> void:
    _draw_polygon([
        center + Vector2(-22, -7), center + Vector2(12, -10),
        center + Vector2(22, -5), center + Vector2(22, 8),
        center + Vector2(-22, 8)
    ], Color("#b7b8ad"), Color("#252a2b"), 2.0)
    _draw_polygon([
        center + Vector2(7, -8), center + Vector2(17, -6),
        center + Vector2(19, 5), center + Vector2(7, 5)
    ], Color("#71818a"), Color("#39474c"), 1.0)
    draw_circle(center + Vector2(-13, 9), 4.0, Color("#252a2b"))
    draw_circle(center + Vector2(14, 9), 4.0, Color("#252a2b"))
    draw_line(center + Vector2(-19, -4), center + Vector2(5, -6), Color("#e0dfd2"), 2.0)


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
    reputation_label = _make_label(Vector2(18, 96), 12, Color("#d6c69a"))
    dialogue_label = _make_label(Vector2(18, 485), 14, Color("#f3d59b"))
    var bag_button := Button.new()
    bag_button.text = "BAG  [I]"
    bag_button.position = Vector2(820, 48)
    bag_button.custom_minimum_size = Vector2(112, 34)
    bag_button.pressed.connect(_toggle_inventory)
    add_child(bag_button)

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
    if hustle_menu_pending:
        if event.keycode == KEY_1:
            _start_hustle("market_delivery")
        elif event.keycode == KEY_2:
            _start_hustle("apartment_drop")
        elif event.keycode == KEY_ESCAPE:
            hustle_menu_pending = false
            dialogue_label.text = "Nia: Let me know when you're ready to run a package."
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
            _toggle_inventory()
        KEY_ESCAPE:
            dialogue_label.text = ""

func _interact() -> void:
    var player := get_node_or_null("Player")
    if player == null:
        return
    var player_position: Vector2 = player.global_position

    var active_hustle := HustleManager.get_active_hustle()
    if not active_hustle.is_empty() and player_position.distance_to(active_hustle["target_position"]) <= NPC_INTERACTION_RANGE:
        if HustleManager.complete_active_hustle():
            dialogue_label.text = HustleManager.get_completion_message()
            queue_redraw()
        else:
            dialogue_label.text = "That delivery is no longer active."
        return

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
            var local_standing := FactionManager.get_standing_label("locals")
            if local_standing == "UNWELCOME":
                dialogue_label.text = "Maya: The block has not forgotten your choices. Show us you can do better."
            elif local_standing in ["TRUSTED", "PILLAR"]:
                dialogue_label.text = "Maya: You have earned real trust around here. Supplies are inside."
            else:
                dialogue_label.text = "Maya: Keep the storefront safe and the neighbors will remember. Supplies are inside."
        "dre":
            if GameState.mission_completed and not bool(GameState.world_flags.get("alley_encounter_completed", false)):
                GameState.current_encounter_id = "alley_ambush"
                GameState.previous_world_position = player_position
                EventBus.encounter_started.emit("alley_ambush")
                dialogue_label.text = "Dre: Two guys are cutting through the alley. Don't let them corner you."
                SaveManager.save_game()
                SceneManager.change_to("res://scenes/combat/CombatAlley.tscn")
                return
            GameState.adjust_relationship("dre", 1)
            dialogue_label.text = "Dre: The court gets busy after work. Watch their feet before they swing."
        "nia":
            GameState.adjust_relationship("nia", 2)
            GameState.adjust_reputation("locals", 1)
            if HustleManager.can_start_hustle():
                hustle_menu_pending = true
                dialogue_label.text = _hustle_menu_text()
            elif not HustleManager.get_active_hustle().is_empty():
                var active := HustleManager.get_active_hustle()
                dialogue_label.text = "Nia: Finish the %s. The drop is marked in gold." % str(active["title"])
            else:
                dialogue_label.text = "Nia: You already ran a package today. Come back tomorrow for another route."
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
    var combat_scene := "res://scenes/combat/CombatShopfront.tscn" if encounter_id == "shop_guard" else "res://scenes/combat/CombatArena.tscn"
    SceneManager.change_to(combat_scene)

func _sync_npc_schedules() -> void:
    for index in range(npcs.size()):
        var npc: Dictionary = npcs[index]
        var snapshot: Dictionary = WorldSimulation.get_resident_snapshot(str(npc["id"]))
        if snapshot.is_empty():
            npc["active"] = false
            continue
        npc["active"] = bool(snapshot["active"])
        npc["position"] = snapshot["position"]
        npc["activity"] = str(snapshot["activity"])
        npcs[index] = npc
    queue_redraw()

func _use_consumable(item_id: String) -> void:
    if GameState.use_item(item_id):
        dialogue_label.text = "Used %s. Health is now %d/100." % [str(GameState.ITEM_DEFINITIONS[item_id]["name"]), GameState.player_health]
        SaveManager.save_game()
    else:
        dialogue_label.text = "No usable %s in your bag, or your health is already full." % item_id

func _toggle_inventory() -> void:
    if inventory_panel:
        inventory_panel.toggle()

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
    reputation_label.text = "LOCALS: %s (%+d)  |  RIVALS: %s (%+d)" % [FactionManager.get_standing_label("locals"), int(GameState.reputation.get("locals", 0)), FactionManager.get_standing_label("rivals"), int(GameState.reputation.get("rivals", 0))]
    var active_hustle := HustleManager.get_active_hustle()
    if not active_hustle.is_empty():
        hint_label.text = "COURIER RUN: %s — deliver to the gold marker with E." % str(active_hustle["title"])
    else:
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


func _hustle_menu_text() -> String:
    var bonus := FactionManager.get_side_hustle_cash_bonus()
    return "NIA'S COURIER BOARD  |  1 MARKET +$%d / 30 XP  |  2 APARTMENT +$%d / 35 XP  |  ESC CLOSE" % [30 + bonus, 35 + bonus]

func _start_hustle(hustle_id: String) -> void:
    hustle_menu_pending = false
    if HustleManager.start_hustle(hustle_id):
        var active := HustleManager.get_active_hustle()
        dialogue_label.text = "Nia: Package is ready. Take it to %s — follow the gold marker." % str(active["destination"])
        queue_redraw()
    else:
        dialogue_label.text = "Nia: No more routes today. Come back tomorrow."

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


func _draw_sidewalk_details() -> void:
    # Concrete joints and curb breaks give the block readable scale.
    for x in range(18, 345, 42):
        draw_line(Vector2(x, 198), Vector2(x + 18, 198), Color("#a5a39a"), 2.0)
        draw_line(Vector2(x, 347), Vector2(x + 18, 347), Color("#a5a39a"), 2.0)
    for y in range(18, 535, 42):
        draw_line(Vector2(352, y), Vector2(352, y + 18), Color("#a5a39a"), 2.0)
        draw_line(Vector2(518, y), Vector2(518, y + 18), Color("#a5a39a"), 2.0)
    # Storm drains and curb ramps.
    _draw_polygon([
        Vector2(548, 337), Vector2(590, 337), Vector2(590, 344), Vector2(548, 344)
    ], Color("#30383a"), Color("#171e20"), 1.0)
    for x in range(553, 588, 7):
        draw_line(Vector2(x, 338), Vector2(x, 343), Color("#778184"), 1.0)
    _draw_polygon([
        Vector2(330, 335), Vector2(350, 335), Vector2(350, 352), Vector2(337, 352)
    ], Color("#aaa69a"), Color("#565c5d"), 1.0)


func _draw_street_furniture() -> void:
    # Public bench on the lower sidewalk.
    _draw_polygon([
        Vector2(555, 390), Vector2(603, 390), Vector2(608, 397), Vector2(550, 397)
    ], Color("#76563f"))
    draw_line(Vector2(557, 399), Vector2(555, 410), Color("#303638"), 3.0)
    draw_line(Vector2(602, 399), Vector2(605, 410), Color("#303638"), 3.0)
    draw_line(Vector2(554, 385), Vector2(604, 385), Color("#9c7958"), 3.0)

    # Sidewalk litter bin with a visible lid and front plane.
    _draw_polygon([
        Vector2(625, 368), Vector2(646, 368), Vector2(643, 400), Vector2(628, 400)
    ], Color("#52635d"), Color("#252d2d"), 1.5)
    _draw_polygon([
        Vector2(622, 365), Vector2(648, 365), Vector2(646, 370), Vector2(624, 370)
    ], Color("#84918a"), Color("#252d2d"), 1.0)
    draw_line(Vector2(633, 375), Vector2(632, 394), Color("#a7b2a9"), 1.0)

    # Fire hydrant beside the curb.
    _draw_polygon([
        Vector2(326, 374), Vector2(337, 374), Vector2(340, 382),
        Vector2(338, 396), Vector2(325, 396), Vector2(323, 382)
    ], Color("#bd5145"), Color("#472b2a"), 1.5)
    draw_rect(Rect2(322, 379, 19, 5), Color("#d4775d"))
    draw_circle(Vector2(331, 374), 6.0, Color("#d4775d"))


func _draw_street_trees() -> void:
    _draw_tree(Vector2(60, 385), 0.9)
    _draw_tree(Vector2(900, 350), 1.0)
    _draw_tree(Vector2(920, 150), 0.78)


func _draw_tree(base: Vector2, scale_factor: float) -> void:
    var s := scale_factor
    _draw_polygon([
        base + Vector2(-5, 0) * s, base + Vector2(7, 0) * s,
        base + Vector2(9, -38) * s, base + Vector2(-3, -38) * s
    ], Color("#66513e"), Color("#2b302b"), 1.5)
    _draw_polygon([
        base + Vector2(-25, -35) * s, base + Vector2(-20, -56) * s,
        base + Vector2(-7, -66) * s, base + Vector2(12, -62) * s,
        base + Vector2(26, -45) * s, base + Vector2(19, -28) * s,
        base + Vector2(-2, -24) * s
    ], Color("#49684f"), Color("#263b32"), 2.0)
    _draw_polygon([
        base + Vector2(-13, -49) * s, base + Vector2(-5, -62) * s,
        base + Vector2(10, -57) * s, base + Vector2(16, -43) * s,
        base + Vector2(2, -34) * s, base + Vector2(-12, -37) * s
    ], Color("#66845b"), Color("#344c3b"), 1.0)
    _draw_polygon([
        base + Vector2(-13, 2) * s, base + Vector2(15, 2) * s,
        base + Vector2(12, 8) * s, base + Vector2(-10, 8) * s
    ], Color("#81735e"), Color("#383b36"), 1.0)


func _draw_utility_fixtures() -> void:
    # Streetlight: pole, arm, housing, and restrained glow.
    draw_line(Vector2(55, 190), Vector2(55, 112), Color("#30383b"), 4.0)
    draw_line(Vector2(55, 113), Vector2(76, 105), Color("#30383b"), 3.0)
    _draw_polygon([
        Vector2(72, 101), Vector2(88, 100), Vector2(92, 106),
        Vector2(75, 109)
    ], Color("#d0bd86"), Color("#343a39"), 1.0)
    draw_circle(Vector2(83, 111), 8.0, Color(1.0, 0.82, 0.48, 0.12))

    # Utility cabinet and wall-mounted service box.
    _draw_polygon([
        Vector2(890, 265), Vector2(914, 265), Vector2(914, 303), Vector2(890, 303)
    ], Color("#59645e"), Color("#252d2d"), 1.5)
    draw_line(Vector2(895, 272), Vector2(909, 272), Color("#aab0a2"), 1.0)
    draw_circle(Vector2(907, 296), 2.0, Color("#d6bd75"))

    # Short metal railing protecting the corner approach.
    for x in range(690, 747, 14):
        draw_line(Vector2(x, 346), Vector2(x, 372), Color("#465255"), 2.0)
    draw_line(Vector2(686, 348), Vector2(751, 348), Color("#7e8987"), 3.0)


func _draw_storefront_facades() -> void:
    # Market signboard, projecting awning, and recessed service trim.
    _draw_polygon([
        Vector2(82, 61), Vector2(258, 61), Vector2(263, 76), Vector2(82, 76)
    ], Color("#3b4947"), Color("#202829"), 2.0)
    draw_line(Vector2(88, 79), Vector2(258, 79), Color("#c5a875"), 2.0)
    _draw_polygon([
        Vector2(78, 133), Vector2(263, 133), Vector2(270, 145), Vector2(78, 145)
    ], Color("#8e4f42"), Color("#332b2b"), 1.5)
    for x in range(83, 263, 30):
        _draw_polygon([
            Vector2(x, 134), Vector2(x + 14, 134),
            Vector2(x + 14, 144), Vector2(x, 144)
        ], Color("#d2b17c"), Color("#59443b"), 0.8)
    # Apartment cornice, sill bands, and drainpipe.
    draw_line(Vector2(657, 68), Vector2(873, 68), Color("#c1c7c4"), 3.0)
    draw_line(Vector2(656, 151), Vector2(876, 151), Color("#5a6265"), 3.0)
    draw_line(Vector2(868, 75), Vector2(868, 158), Color("#303b40"), 3.0)
    for y in [82, 108, 134]:
        draw_line(Vector2(859, y), Vector2(875, y), Color("#aeb7b5"), 1.5)
    # Lower building gets a parapet cap and basement vent.
    draw_line(Vector2(670, 404), Vector2(866, 404), Color("#c1ad91"), 4.0)
    _draw_polygon([
        Vector2(690, 454), Vector2(724, 454), Vector2(724, 470), Vector2(690, 470)
    ], Color("#34444a"), Color("#252b2d"), 1.0)
    for x in range(695, 723, 6):
        draw_line(Vector2(x, 456), Vector2(x, 468), Color("#91a0a0"), 1.0)


func _draw_fire_escape(origin: Vector2) -> void:
    var x := origin.x
    var y := origin.y
    # Vertical ladder and two landings on the apartment facade.
    draw_line(Vector2(x, y + 12), Vector2(x, y + 102), Color("#30383b"), 3.0)
    draw_line(Vector2(x + 17, y + 12), Vector2(x + 17, y + 102), Color("#30383b"), 3.0)
    for rung in range(0, 9):
        var rung_y := y + 18 + rung * 10
        draw_line(Vector2(x, rung_y), Vector2(x + 17, rung_y), Color("#7d8988"), 1.5)
    for landing_y in [y + 45, y + 91]:
        _draw_polygon([
            Vector2(x - 18, landing_y), Vector2(x + 29, landing_y),
            Vector2(x + 24, landing_y + 6), Vector2(x - 22, landing_y + 6)
        ], Color("#687477"), Color("#252d30"), 1.2)
        draw_line(Vector2(x - 17, landing_y - 13), Vector2(x + 27, landing_y - 13), Color("#9aa4a0"), 1.5)
        for rail_x in range(int(x - 16), int(x + 28), 11):
            draw_line(Vector2(rail_x, landing_y - 13), Vector2(rail_x, landing_y), Color("#596568"), 1.0)


func _draw_court_fence() -> void:
    # Chain-link fence is simplified into a readable modular metal frame.
    draw_line(Vector2(670, 476), Vector2(925, 476), Color("#596765"), 3.0)
    draw_line(Vector2(670, 516), Vector2(925, 516), Color("#596765"), 3.0)
    for x in range(674, 926, 24):
        draw_line(Vector2(x, 476), Vector2(x, 516), Color("#82908a"), 1.2)
    for y in [486, 498, 510]:
        draw_line(Vector2(670, y), Vector2(925, y), Color("#687773"), 0.8)
    for x in [670, 798, 925]:
        draw_line(Vector2(x, 470), Vector2(x, 521), Color("#3c4847"), 3.0)
    # Gate opening and latch.
    draw_line(Vector2(795, 479), Vector2(795, 514), Color("#a0aaa2"), 2.0)
    draw_circle(Vector2(791, 495), 2.0, Color("#d0bd86"))


func _draw_parking_details() -> void:
    # Marked curbside parking bay and wheel stop.
    draw_line(Vector2(28, 454), Vector2(245, 454), Color("#c6c4ad"), 2.0)
    draw_line(Vector2(28, 454), Vector2(28, 491), Color("#c6c4ad"), 2.0)
    draw_line(Vector2(245, 454), Vector2(245, 491), Color("#c6c4ad"), 2.0)
    _draw_polygon([
        Vector2(80, 485), Vector2(150, 485), Vector2(147, 491), Vector2(83, 491)
    ], Color("#9a9a89"), Color("#4b5250"), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(39, 447), "PARKING", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#d9d4bd"))


func _draw_utility_poles_and_wires() -> void:
    # Pole silhouettes and overhead service lines sit above the roofline.
    _draw_polygon([
        Vector2(604, 32), Vector2(611, 32), Vector2(613, 177), Vector2(606, 177)
    ], Color("#594b3d"), Color("#292e2d"), 1.2)
    draw_line(Vector2(582, 48), Vector2(635, 48), Color("#6f6251"), 3.0)
    for x in [588, 601, 615, 629]:
        draw_line(Vector2(x, 43), Vector2(x, 54), Color("#343b3b"), 1.5)
    draw_line(Vector2(611, 48), Vector2(650, 24), Color("#252e32"), 1.2)
    draw_line(Vector2(635, 48), Vector2(890, 28), Color("#252e32"), 1.0)
    draw_line(Vector2(635, 54), Vector2(890, 43), Color("#3c4546"), 1.0)
    # Small transformer canister and insulators.
    _draw_polygon([
        Vector2(615, 61), Vector2(630, 61), Vector2(632, 78), Vector2(613, 78)
    ], Color("#69736d"), Color("#303938"), 1.0)
    draw_line(Vector2(617, 65), Vector2(628, 65), Color("#aab0a2"), 1.0)



func _draw_property_boundaries() -> void:
    # Low masonry boundary and a hinged service gate along the rear lot.
    draw_line(Vector2(28, 414), Vector2(252, 414), Color("#5a5148"), 5.0)
    draw_line(Vector2(28, 414), Vector2(28, 440), Color("#857a68"), 4.0)
    draw_line(Vector2(252, 414), Vector2(252, 440), Color("#857a68"), 4.0)
    for x in range(34, 250, 28):
        draw_line(Vector2(x, 410), Vector2(x, 419), Color("#b09b7d"), 2.0)
    # Gate is visibly separate from the wall so the lot reads as accessible.
    draw_line(Vector2(196, 414), Vector2(242, 435), Color("#596765"), 3.0)
    draw_line(Vector2(242, 435), Vector2(242, 414), Color("#596765"), 3.0)
    draw_line(Vector2(202, 416), Vector2(236, 431), Color("#9aa49d"), 1.0)
    draw_circle(Vector2(199, 416), 2.0, Color("#d0bd86"))


func _draw_alley_service_area() -> void:
    # Recessed alley mouth, wall-mounted security light, and service door.
    _draw_polygon([
        Vector2(286, 354), Vector2(348, 354), Vector2(348, 365), Vector2(286, 365)
    ], Color("#303a38"), Color("#1f2928"), 1.5)
    _draw_polygon([
        Vector2(296, 367), Vector2(338, 367), Vector2(338, 415), Vector2(296, 415)
    ], Color("#34433d"), Color("#1f2928"), 1.5)
    draw_line(Vector2(302, 373), Vector2(302, 409), Color("#778078"), 1.0)
    draw_circle(Vector2(333, 392), 2.0, Color("#d0bd86"))
    draw_line(Vector2(280, 360), Vector2(280, 349), Color("#353d3d"), 2.0)
    _draw_polygon([
        Vector2(274, 347), Vector2(286, 347), Vector2(288, 351), Vector2(273, 351)
    ], Color("#d1b879"), Color("#343a39"), 1.0)
    draw_circle(Vector2(280, 354), 9.0, Color(1.0, 0.78, 0.42, 0.10))


func _draw_loading_zone() -> void:
    # Market receiving area: painted boundary, pallet, and stacked cartons.
    draw_line(Vector2(72, 181), Vector2(264, 181), Color("#d0c6a7"), 2.0)
    draw_line(Vector2(72, 181), Vector2(72, 193), Color("#d0c6a7"), 2.0)
    draw_line(Vector2(264, 181), Vector2(264, 193), Color("#d0c6a7"), 2.0)
    _draw_polygon([
        Vector2(212, 164), Vector2(253, 164), Vector2(257, 174), Vector2(216, 174)
    ], Color("#795c42"), Color("#302c27"), 1.2)
    draw_line(Vector2(219, 169), Vector2(251, 169), Color("#c09a67"), 1.0)
    _draw_polygon([
        Vector2(220, 146), Vector2(237, 146), Vector2(237, 164), Vector2(220, 164)
    ], Color("#b18a58"), Color("#45372b"), 1.0)
    _draw_polygon([
        Vector2(239, 150), Vector2(255, 150), Vector2(255, 164), Vector2(239, 164)
    ], Color("#92734d"), Color("#45372b"), 1.0)
    draw_line(Vector2(228, 148), Vector2(228, 162), Color("#e0c18c"), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(77, 177), "RECEIVING", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#d8cfb4"))


func _draw_building_rooftops() -> void:
    # Roof access housings, vents, and water tank silhouette add a skyline layer.
    _draw_polygon([
        Vector2(102, 39), Vector2(144, 39), Vector2(148, 55), Vector2(98, 55)
    ], Color("#66584b"), Color("#2e3331"), 1.5)
    _draw_polygon([
        Vector2(108, 31), Vector2(139, 31), Vector2(144, 39), Vector2(103, 39)
    ], Color("#93816b"), Color("#3b3c36"), 1.0)
    for x in [177, 194, 211]:
        _draw_polygon([
            Vector2(x, 43), Vector2(x + 10, 43), Vector2(x + 12, 53), Vector2(x - 2, 53)
        ], Color("#59615d"), Color("#2c3332"), 1.0)
        draw_line(Vector2(x + 2, 45), Vector2(x + 8, 45), Color("#a5aaa0"), 1.0)
    # Elevated rooftop water tank on the apartment block.
    draw_line(Vector2(715, 50), Vector2(715, 26), Color("#343c3e"), 2.0)
    draw_line(Vector2(755, 50), Vector2(755, 26), Color("#343c3e"), 2.0)
    _draw_polygon([
        Vector2(710, 24), Vector2(760, 24), Vector2(756, 43), Vector2(714, 43)
    ], Color("#765d4d"), Color("#2d3333"), 1.5)
    draw_line(Vector2(715, 29), Vector2(756, 29), Color("#b18b68"), 1.0)
    _draw_polygon([
        Vector2(705, 22), Vector2(765, 22), Vector2(760, 26), Vector2(710, 26)
    ], Color("#a17d5e"), Color("#343b39"), 1.0)
