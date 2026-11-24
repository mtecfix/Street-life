extends Node2D

@export_enum("shop", "apartment") var interior_kind: String = "shop"

const SHOP_ITEMS := ["snack", "medkit", "soda"]
const BED_POSITION := Vector2(480, 235)
const EXIT_POSITION := Vector2(480, 490)

var player: CharacterBody2D
var status_label: Label
var detail_label: Label
var shop_panel: PanelContainer
var shop_summary: Label
var shop_buttons: Dictionary = {}

func _ready() -> void:
    player = get_node_or_null("Player")
    if player:
        player.position = Vector2(480, 390)
    status_label = _make_label(Vector2(28, 24), 18, Color("#f2e8d5"))
    detail_label = _make_label(Vector2(28, 58), 13, Color("#c4d2d4"))
    _refresh_text()
    if interior_kind == "shop":
        _build_shop_interface()
        _refresh_shop_interface()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("#222b30"))
    if interior_kind == "shop":
        _draw_poly([Vector2(40, 112), Vector2(920, 112), Vector2(900, 450), Vector2(60, 450)], Color("#53635f"))
        _draw_poly([Vector2(70, 132), Vector2(890, 132), Vector2(875, 405), Vector2(85, 405)], Color("#718079"))
        # Two deep, chamfered shelf runs with visible front fascia.
        _draw_poly([Vector2(105, 165), Vector2(855, 165), Vector2(850, 193), Vector2(110, 193)], Color("#d4b77b"))
        _draw_poly([Vector2(110, 295), Vector2(850, 295), Vector2(845, 320), Vector2(115, 320)], Color("#d4b77b"))
        for i in range(8):
            var shelf_x := 125.0 + float(i) * 88.0
            _draw_poly([Vector2(shelf_x, 139), Vector2(shelf_x + 43, 139), Vector2(shelf_x + 40, 163), Vector2(shelf_x + 3, 163)], Color("#bd8b5c"))
            _draw_poly([Vector2(shelf_x + 2, 265), Vector2(shelf_x + 45, 265), Vector2(shelf_x + 42, 292), Vector2(shelf_x + 4, 292)], Color("#7ca6a0"))
            draw_line(Vector2(shelf_x + 8, 145), Vector2(shelf_x + 8, 157), Color("#e5c18e"), 2.0)
            draw_line(Vector2(shelf_x + 25, 143), Vector2(shelf_x + 25, 157), Color("#e5c18e"), 2.0)
        _draw_poly([Vector2(390, 354), Vector2(570, 354), Vector2(564, 400), Vector2(396, 400)], Color("#594a40"))
        _draw_poly([Vector2(398, 350), Vector2(562, 350), Vector2(570, 357), Vector2(390, 357)], Color("#92735b"))
        draw_string(ThemeDB.fallback_font, Vector2(410, 380), "CHECKOUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(420, 100), "MAYA'S MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(420, 490), "EXIT  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f0d28e"))
    else:
        _draw_poly([Vector2(55, 105), Vector2(905, 105), Vector2(890, 455), Vector2(70, 455)], Color("#675b52"))
        _draw_poly([Vector2(75, 125), Vector2(885, 125), Vector2(870, 435), Vector2(90, 435)], Color("#938070"))
        _draw_poly([Vector2(125, 165), Vector2(385, 165), Vector2(378, 292), Vector2(132, 292)], Color("#526c79"))
        _draw_poly([Vector2(145, 184), Vector2(365, 184), Vector2(360, 272), Vector2(150, 272)], Color("#9db6bc"))
        draw_line(Vector2(255, 185), Vector2(252, 271), Color("#526c79"), 4.0)
        _draw_poly([Vector2(600, 170), Vector2(790, 170), Vector2(782, 285), Vector2(608, 285)], Color("#644b45"))
        _draw_poly([Vector2(615, 185), Vector2(775, 185), Vector2(770, 270), Vector2(620, 270)], Color("#b38b77"))
        _draw_poly([Vector2(395, 195), Vector2(565, 195), Vector2(558, 290), Vector2(402, 290)], Color("#4b5260"))
        _draw_poly([Vector2(410, 209), Vector2(550, 209), Vector2(545, 272), Vector2(415, 272)], Color("#8c9da0"))
        _draw_poly([Vector2(388, 185), Vector2(572, 185), Vector2(565, 197), Vector2(395, 197)], Color("#b29a78"))
        draw_string(ThemeDB.fallback_font, Vector2(430, 175), "REST", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(420, 490), "EXIT  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f0d28e"))

func _draw_poly(points: PackedVector2Array, fill: Color, outline: Color = Color("#292e30"), width: float = 2.0) -> void:
    draw_colored_polygon(points, fill)
    var outline_points := points.duplicate()
    outline_points.append(points[0])
    draw_polyline(outline_points, outline, width, true)


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if interior_kind == "shop":
        match event.keycode:
            KEY_1:
                _purchase("snack")
            KEY_2:
                _purchase("medkit")
            KEY_3:
                _purchase("soda")
    elif event.keycode == KEY_E:
        if player and player.position.distance_to(BED_POSITION) <= 110.0:
            GameState.player_health = 100
            WorldClock.advance_minutes(8 * 60)
            GameState.world_flags["rested_today"] = GameState.current_day
            status_label.text = "You got some rest. Health restored and eight hours passed."
            SaveManager.save_game()
        elif player and player.position.distance_to(EXIT_POSITION) <= 100.0:
            _exit_interior()

    if event.keycode == KEY_ESCAPE:
        _exit_interior()

func _purchase(item_id: String) -> void:
    if not WorldSimulation.has_business_stock("mayas_market", item_id):
        status_label.text = "Tasha: We're sold out of that item. Check back after the morning restock."
    elif GameState.purchase_item(item_id):
        WorldSimulation.record_business_sale("mayas_market", item_id)
        var item: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
        status_label.text = "Purchased %s for $%d." % [str(item["name"]), int(item["price"])]
        # GameState.purchase_item() emits the authoritative inventory update.
        # Do not emit here as well, or HUD listeners receive duplicate events.
        SaveManager.save_game()
    else:
        status_label.text = _purchase_failure_reason(item_id)
    _refresh_shop_interface()

func _exit_interior() -> void:
    SceneManager.change_to("res://scenes/world/Neighborhood.tscn")

func _refresh_text() -> void:
    if interior_kind == "shop":
        detail_label.text = "Choose an item below or press 1, 2, or 3. ESC: EXIT"
    else:
        detail_label.text = "Move to the bed and press E to rest for eight hours. Health is fully restored. Move to the bottom door and press E to leave."

func _make_label(label_position: Vector2, font_size: int, font_color: Color) -> Label:
    var label := Label.new()
    label.position = label_position
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", font_color)
    add_child(label)
    return label

func _build_shop_interface() -> void:
    # A Control-based checkout keeps the shop usable with mouse, touch, and
    # keyboard. The same _purchase path is used by buttons and legacy hotkeys.
    shop_panel = PanelContainer.new()
    shop_panel.name = "ShopCheckout"
    shop_panel.position = Vector2(245, 185)
    shop_panel.custom_minimum_size = Vector2(470, 150)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#182126")
    panel_style.border_color = Color("#d4b77b")
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(8)
    panel_style.set_content_margin_all(14)
    shop_panel.add_theme_stylebox_override("panel", panel_style)
    add_child(shop_panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 8)
    shop_panel.add_child(content)

    shop_summary = Label.new()
    shop_summary.add_theme_color_override("font_color", Color("#f2e8d5"))
    shop_summary.add_theme_font_size_override("font_size", 14)
    content.add_child(shop_summary)

    for item_id in SHOP_ITEMS:
        var item: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        content.add_child(row)

        var description := Label.new()
        description.text = "%s  —  $%d  —  +%d HP" % [
            str(item["name"]), int(item["price"]), int(item["heal"])
        ]
        description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        description.add_theme_color_override("font_color", Color("#d7e0dc"))
        row.add_child(description)

        var buy_button := Button.new()
        buy_button.text = "BUY"
        buy_button.custom_minimum_size.x = 82
        buy_button.pressed.connect(_purchase.bind(item_id))
        row.add_child(buy_button)
        shop_buttons[item_id] = buy_button

func _refresh_shop_interface() -> void:
    if not is_instance_valid(shop_summary):
        return
    var market := WorldSimulation.get_business_snapshot("mayas_market")
    var stock: Dictionary = market.get("stock", {})
    shop_summary.text = "CASH  $%d     BAG  %d/%d     STOCK: SNACK %d / MEDKIT %d / SODA %d" % [
        GameState.player_cash,
        GameState.get_inventory_count(),
        GameState.INVENTORY_CAPACITY,
        int(stock.get("snack", 0)),
        int(stock.get("medkit", 0)),
        int(stock.get("soda", 0))
    ]
    for item_id in shop_buttons:
        var item: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
        var can_afford := GameState.player_cash >= int(item["price"])
        var has_space := GameState.get_inventory_count() < GameState.INVENTORY_CAPACITY
        var in_stock := int(stock.get(item_id, 0)) > 0
        shop_buttons[item_id].disabled = not can_afford or not has_space or not in_stock

func _purchase_failure_reason(item_id: String) -> String:
    var item: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
    if GameState.get_inventory_count() >= GameState.INVENTORY_CAPACITY:
        return "Your bag is full. Use an item or make room before buying."
    if GameState.player_cash < int(item["price"]):
        return "Not enough cash for %s. You need $%d." % [
            str(item["name"]), int(item["price"])
        ]
    return "That purchase could not be completed."
