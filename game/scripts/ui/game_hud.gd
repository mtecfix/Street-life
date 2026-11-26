extends CanvasLayer

# STREET HUSTLER — PRESENTATION LAYER
# -----------------------------------------------------------------------------
# This HUD deliberately does not own gameplay state. It is a read-only view of
# the existing autoloads (GameState, WorldClock, HustleManager and EventManager).
# Keeping presentation separate means the underlying progression, mission,
# inventory, save and combat systems remain the source of truth.
#
# VISION:
# - Give the player a clear first-minute read of health, cash, level and time.
# - Keep the current objective visible without auto-starting a mission.
# - Show a compact schematic map of the existing neighborhood landmarks.
# - Preserve the existing interaction/dialogue flow in neighborhood.gd.
# - Use a restrained dark/bronze palette that complements the title artwork.
#
# This is intentionally a foundation HUD. It uses the existing prototype world
# coordinates and can be reskinned as the Bronx environment art is integrated.

const PANEL_COLOR := Color("#171c22", 0.92)
const PANEL_EDGE := Color("#a77a45", 0.95)
const TEXT_MAIN := Color("#f4ead7")
const TEXT_MUTED := Color("#b7b0a2")
const ACCENT := Color("#e0ae62")

var _stats_label: Label
var _objective_label: Label
var _location_label: Label
var _clock_label: Label
var _map: Control
var _last_snapshot := ""
var _combat_skill_ui: Control

func _ready() -> void:
    _build_interface()
    var skill_ui_script = preload("res://scripts/ui/combat_skill_tree_ui.gd")
    _combat_skill_ui = skill_ui_script.new()
    add_child(_combat_skill_ui)
    _refresh()
    # Event-driven refreshes make state changes appear immediately. A light
    # process refresh remains as a safety net for time and movement updates.
    EventBus.progression_changed.connect(_refresh)
    EventBus.reputation_changed.connect(_on_reputation_changed)
    EventBus.inventory_changed.connect(_on_inventory_changed)
    EventBus.world_time_advanced.connect(_on_time_advanced)
    EventBus.side_hustle_started.connect(_on_world_state_changed)
    EventBus.side_hustle_completed.connect(_on_hustle_completed)
    EventBus.world_event_completed.connect(_on_event_completed)

func _process(_delta: float) -> void:
    _refresh()

func _build_interface() -> void:
    # Top-left player status panel: mirrors existing GameState values only.
    var status_panel := _panel(Vector2(18, 16), Vector2(360, 82))
    _stats_label = _label(status_panel, Vector2(14, 10), Vector2(332, 60), 14)
    _stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    # Objective panel: at game start this asks the player to meet Rico. It does
    # not set mission_active; only the existing E interaction with Rico does.
    var objective_panel := _panel(Vector2(18, 108), Vector2(360, 76))
    _label(objective_panel, Vector2(12, 7), Vector2(330, 20), 11, ACCENT).text = "CURRENT OBJECTIVE"
    _objective_label = _label(objective_panel, Vector2(12, 29), Vector2(330, 40), 14)

    # Time and district marker at the upper-right.
    var district_panel := _panel(Vector2(742, 16), Vector2(200, 64))
    _location_label = _label(district_panel, Vector2(10, 7), Vector2(180, 20), 12, ACCENT)
    _location_label.text = "BRONX  /  THE BLOCK"
    _clock_label = _label(district_panel, Vector2(10, 29), Vector2(180, 25), 18)

    # Schematic minimap uses existing world landmarks from neighborhood.gd.
    # It is intentionally labeled as a schematic, not a GPS-accurate map.
    var map_panel := _panel(Vector2(742, 92), Vector2(200, 154))
    _label(map_panel, Vector2(10, 5), Vector2(180, 18), 10, ACCENT).text = "BLOCK MAP"
    _map = Control.new()
    _map.position = Vector2(10, 27)
    _map.size = Vector2(180, 116)
    _map.draw.connect(_draw_minimap)
    map_panel.add_child(_map)

    # A small control reminder is separate from gameplay logic. Existing input
    # bindings remain unchanged.
    var controls := _panel(Vector2(18, 474), Vector2(510, 48))
    var control_label := _label(controls, Vector2(12, 7), Vector2(486, 34), 11, TEXT_MUTED)
    control_label.text = "MOVE  WASD / ARROWS     INTERACT  E     INVENTORY  I     SKILLS  K     SNACK  F     MEDKIT  H"

func _panel(at: Vector2, dimensions: Vector2) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.position = at
    panel.size = dimensions
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL_COLOR
    style.border_color = PANEL_EDGE
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 4
    style.content_margin_right = 4
    style.content_margin_top = 3
    style.content_margin_bottom = 3
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    return panel

func _label(parent: Control, at: Vector2, dimensions: Vector2, font_size: int, color: Color = TEXT_MAIN) -> Label:
    var label := Label.new()
    label.position = at
    label.size = dimensions
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _refresh() -> void:
    if not is_instance_valid(_stats_label):
        return
    _stats_label.text = "STREET HUSTLER   LV %d   XP %d/%d\n$%d   HEALTH %d/100   SP %d   BAG %d/%d" % [
        GameState.player_level,
        GameState.player_xp,
        GameState.xp_required_for_next_level(),
        GameState.player_cash,
        GameState.player_health,
        GameState.skill_points,
        GameState.get_inventory_count(),
        GameState.INVENTORY_CAPACITY
    ]
    _clock_label.text = "DAY %d   %s" % [GameState.current_day, WorldClock.get_time_string()]
    _objective_label.text = _get_objective_text()
    if is_instance_valid(_map):
        _map.queue_redraw()

func _get_objective_text() -> String:
    # The opening objective is a presentation hint only. Rico's existing
    # interaction code remains responsible for activating the actual mission.
    if not GameState.mission_active and not GameState.mission_completed:
        return "Meet Rico near the corner and press E."
    if GameState.mission_active:
        if GameState.mission_choice.is_empty():
            return "Head to the orange corner marker. Choose your approach."
        return "Resolve the corner encounter."
    if GameState.mission_completed and not bool(GameState.world_flags.get("alley_encounter_completed", false)):
        return "Talk to Dre after 2 PM about the alley."
    return "The block is secured. Explore and help the neighborhood."

func _draw_minimap() -> void:
    var bounds := Rect2(Vector2.ZERO, _map.size)
    _map.draw_rect(bounds, Color("#273238"))
    # Existing Neighborhood.gd landmarks mapped from its 960x540 prototype.
    _map.draw_rect(Rect2(0, 44, 190, 28), Color("#596066"))
    _map.draw_rect(Rect2(70, 0, 34, 116), Color("#596066"))
    _map.draw_rect(Rect2(9, 9, 43, 25), Color("#a27a57")) # Maya's Market
    _map.draw_rect(Rect2(128, 9, 48, 25), Color("#697d86")) # Walk-Ups
    _map.draw_rect(Rect2(133, 84, 43, 24), Color("#71836b")) # Community Court
    _map.draw_string(ThemeDB.fallback_font, Vector2(7, 42), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT_MAIN)
    _map.draw_string(ThemeDB.fallback_font, Vector2(128, 42), "APT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT_MAIN)
    _map.draw_string(ThemeDB.fallback_font, Vector2(134, 81), "COURT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT_MAIN)
    var player := get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null
    if player:
        var p := Vector2(player.global_position.x / 960.0 * _map.size.x, player.global_position.y / 540.0 * _map.size.y)
        _map.draw_circle(p, 4.5, Color("#f4d06f"))
        _map.draw_arc(p, 7.0, 0.0, TAU, 20, Color("#fff0b5"), 1.2)

func _on_reputation_changed(_faction_id: String, _new_value: int) -> void:
    _refresh()

func _on_inventory_changed(_item_id: String, _new_count: int) -> void:
    _refresh()

func _on_time_advanced(_day: int, _hour: int, _minute: int) -> void:
    _refresh()

func _on_world_state_changed(_hustle_id: String, _day: int) -> void:
    _refresh()

func _on_hustle_completed(_hustle_id: String, _day: int, _cash: int, _xp: int) -> void:
    _refresh()

func _on_event_completed(_event_id: String, _day: int) -> void:
    _refresh()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
        if is_instance_valid(_combat_skill_ui):
            _combat_skill_ui.toggle()
            get_viewport().set_input_as_handled()
