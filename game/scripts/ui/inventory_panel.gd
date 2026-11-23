extends CanvasLayer

# InventoryPanel is a presentation-only layer. GameState remains the authority
# for item counts, cash, health, and item effects; this panel only requests actions.
const PANEL_SIZE := Vector2(440, 310)

var panel: PanelContainer
var title_label: Label
var summary_label: Label
var rows_container: VBoxContainer
var message_label: Label
var _item_labels: Dictionary = {}
var _use_buttons: Dictionary = {}

func _ready() -> void:
    layer = 20
    _build_interface()
    EventBus.inventory_changed.connect(_on_inventory_changed)
    EventBus.progression_changed.connect(_on_progression_changed)
    hide_panel()
    refresh()

func _exit_tree() -> void:
    if EventBus.inventory_changed.is_connected(_on_inventory_changed):
        EventBus.inventory_changed.disconnect(_on_inventory_changed)
    if EventBus.progression_changed.is_connected(_on_progression_changed):
        EventBus.progression_changed.disconnect(_on_progression_changed)

func toggle() -> void:
    if panel.visible:
        hide_panel()
    else:
        show_panel()

func show_panel() -> void:
    refresh()
    panel.visible = true

func hide_panel() -> void:
    if panel:
        panel.visible = false

func _build_interface() -> void:
    # Center the inventory card in the fixed 960x540 game viewport. Anchors keep
    # the panel centered when the browser window changes aspect ratio.
    panel = PanelContainer.new()
    panel.name = "InventoryPanel"
    panel.custom_minimum_size = PANEL_SIZE
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = -PANEL_SIZE * 0.5
    panel.add_theme_stylebox_override("panel", _make_panel_style())
    add_child(panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    panel.add_child(content)

    var header := HBoxContainer.new()
    content.add_child(header)
    title_label = Label.new()
    title_label.text = "YOUR BAG"
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size", 22)
    title_label.add_theme_color_override("font_color", Color("#f2e8d5"))
    header.add_child(title_label)

    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.pressed.connect(hide_panel)
    header.add_child(close_button)

    summary_label = Label.new()
    summary_label.add_theme_color_override("font_color", Color("#c4d2d4"))
    content.add_child(summary_label)

    var separator := HSeparator.new()
    content.add_child(separator)

    rows_container = VBoxContainer.new()
    rows_container.add_theme_constant_override("separation", 8)
    content.add_child(rows_container)

    message_label = Label.new()
    message_label.custom_minimum_size.y = 28
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_color_override("font_color", Color("#f0d28e"))
    content.add_child(message_label)

    var footer := Label.new()
    footer.text = "Items are consumed only when you choose USE."
    footer.add_theme_font_size_override("font_size", 11)
    footer.add_theme_color_override("font_color", Color("#91a3a5"))
    content.add_child(footer)

    _rebuild_item_rows()

func _rebuild_item_rows() -> void:
    for child in rows_container.get_children():
        child.queue_free()
    _item_labels.clear()
    _use_buttons.clear()

    for item_id in GameState.ITEM_DEFINITIONS:
        var definition: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        rows_container.add_child(row)

        var item_label := Label.new()
        item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        item_label.add_theme_color_override("font_color", Color("#f2e8d5"))
        item_label.add_theme_font_size_override("font_size", 14)
        row.add_child(item_label)
        _item_labels[item_id] = item_label

        var use_button := Button.new()
        use_button.text = "USE"
        use_button.custom_minimum_size.x = 76
        use_button.pressed.connect(_use_item.bind(item_id))
        row.add_child(use_button)
        _use_buttons[item_id] = use_button

func refresh() -> void:
    if not is_instance_valid(summary_label):
        return
    summary_label.text = "CASH  $%d     HEALTH  %d/100     CAPACITY  %d/%d" % [
        GameState.player_cash,
        GameState.player_health,
        GameState.get_inventory_count(),
        GameState.INVENTORY_CAPACITY
    ]
    for item_id in _item_labels:
        var definition: Dictionary = GameState.ITEM_DEFINITIONS[item_id]
        var count := int(GameState.inventory.get(item_id, 0))
        _item_labels[item_id].text = "%s   x%d   ·   +%d HP" % [
            str(definition["name"]), count, int(definition["heal"])
        ]
        _use_buttons[item_id].disabled = count <= 0 or GameState.player_health >= 100

func _use_item(item_id: String) -> void:
    if GameState.use_item(item_id):
        message_label.text = "Used %s. Health: %d/100." % [
            str(GameState.ITEM_DEFINITIONS[item_id]["name"]),
            GameState.player_health
        ]
        SaveManager.save_game()
    else:
        message_label.text = "That item cannot be used right now."
    refresh()

func _on_inventory_changed(_item_id: String, _new_count: int) -> void:
    refresh()

func _on_progression_changed(_level: int, _xp: int, _skill_points: int) -> void:
    refresh()

func _make_panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#182126")
    style.border_color = Color("#b78d55")
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    style.set_content_margin_all(18)
    return style
