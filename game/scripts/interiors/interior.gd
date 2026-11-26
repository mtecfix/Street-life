extends Node2D

@export_enum("shop", "apartment") var interior_kind: String = "shop"

const SHOP_ITEMS := ["snack", "medkit", "soda"]
const BED_POSITION := Vector2(480, 235)
const EXIT_POSITION := Vector2(480, 490)

var player: CharacterBody2D
var status_label: Label
var detail_label: Label

func _ready() -> void:
    player = get_node_or_null("Player")
    if player:
        player.position = Vector2(480, 390)
    status_label = _make_label(Vector2(28, 24), 18, Color("#f2e8d5"))
    detail_label = _make_label(Vector2(28, 58), 13, Color("#c4d2d4"))
    _refresh_text()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("#222b30"))
    if interior_kind == "shop":
        draw_rect(Rect2(40, 95, 880, 355), Color("#53635f"))
        draw_rect(Rect2(70, 120, 820, 285), Color("#718079"))
        draw_rect(Rect2(110, 170, 740, 22), Color("#d4b77b"))
        draw_rect(Rect2(110, 300, 740, 18), Color("#d4b77b"))
        for i in range(8):
            draw_rect(Rect2(125 + i * 88, 135, 45, 30), Color("#bd8b5c"))
            draw_rect(Rect2(125 + i * 88, 260, 45, 30), Color("#7ca6a0"))
        draw_rect(Rect2(390, 350, 180, 48), Color("#594a40"))
        draw_string(ThemeDB.fallback_font, Vector2(410, 380), "CHECKOUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(420, 100), "MAYA'S MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(420, 490), "EXIT  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f0d28e"))
    else:
        draw_rect(Rect2(55, 90, 850, 365), Color("#675b52"))
        draw_rect(Rect2(75, 110, 810, 325), Color("#938070"))
        draw_rect(Rect2(125, 155, 260, 135), Color("#526c79"))
        draw_rect(Rect2(145, 175, 220, 95), Color("#9db6bc"))
        draw_rect(Rect2(600, 160, 190, 125), Color("#644b45"))
        draw_rect(Rect2(615, 175, 160, 95), Color("#b38b77"))
        draw_rect(Rect2(395, 185, 170, 100), Color("#4b5260"))
        draw_rect(Rect2(410, 200, 140, 70), Color("#8c9da0"))
        draw_string(ThemeDB.fallback_font, Vector2(430, 175), "REST", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(420, 490), "EXIT  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f0d28e"))

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
            KEY_4:
                _purchase_weapon("smg")
            KEY_5:
                _purchase_weapon("carbine")
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
    if GameState.purchase_item(item_id):
        var item: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
        status_label.text = "Purchased %s for $%d." % [str(item["name"]), int(item["price"])]
        # GameState.purchase_item() emits the authoritative inventory update.
        # Do not emit here as well, or HUD listeners receive duplicate events.
        SaveManager.save_game()
    else:
        status_label.text = "Can't buy that. Check your cash and bag capacity."

func _purchase_weapon(weapon_id: String) -> void:
    if weapon_id in GameState.owned_weapons:
        GameState.equip_weapon(weapon_id)
        var profile := FirearmCombatController.get_profile(weapon_id)
        status_label.text = "%s is already yours. Equipped for your next encounter." % str(profile["name"])
        return
    if GameState.purchase_weapon(weapon_id):
        var profile := FirearmCombatController.get_profile(weapon_id)
        status_label.text = "Purchased %s. It is now in your permanent loadout." % str(profile["name"])
    else:
        var offer: Dictionary = GameState.WEAPON_SHOP.get(weapon_id, {})
        status_label.text = "Cannot purchase %s. You need $%d and it is not already owned." % [str(offer.get("name", weapon_id)), int(offer.get("price", 0))]
    SaveManager.save_game()
    _refresh_text()

func _exit_interior() -> void:
    SceneManager.change_to("res://scenes/world/Neighborhood.tscn")

func _refresh_text() -> void:
    if interior_kind == "shop":
        var smg_state := "OWNED" if "smg" in GameState.owned_weapons else "$180"
        var carbine_state := "OWNED" if "carbine" in GameState.owned_weapons else "$320"
        detail_label.text = "1 SNACK $5  |  2 FIRST-AID $18  |  3 SODA $8\n4 COMPACT SMG %s  |  5 STREET CARBINE %s  |  ESC: EXIT" % [smg_state, carbine_state]
    else:
        detail_label.text = "Move to the bed and press E to rest for eight hours. Health is fully restored. Move to the bottom door and press E to leave."

func _make_label(label_position: Vector2, font_size: int, font_color: Color) -> Label:
    var label := Label.new()
    label.position = label_position
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", font_color)
    add_child(label)
    return label
