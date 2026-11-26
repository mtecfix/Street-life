extends Control
## Two-branch combat training menu. GameState remains the source of truth.

const PANEL := Color("#171d29")
const EDGE := Color("#bd8c52")
const TEXT := Color("#f2eadc")
const MUTED := Color("#b9c0cb")
const ACCENT := Color("#e6b56d")

var _active_style := "melee"
var _points_label: Label
var _tree_title: Label
var _node_list: VBoxContainer
var _confirm_respec: ConfirmationDialog

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build()
    EventBus.progression_changed.connect(_refresh)
    _refresh()

func toggle() -> void:
    visible = not visible
    if visible:
        _refresh()

func _build() -> void:
    var shade := ColorRect.new()
    shade.color = Color(0.02, 0.025, 0.04, 0.84)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(760, 470)
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = EDGE
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", style)
    center.add_child(panel)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 10)
    panel.add_child(layout)

    var header := HBoxContainer.new()
    layout.add_child(header)
    var heading := Label.new()
    heading.text = "COMBAT TRAINING"
    heading.add_theme_font_size_override("font_size", 22)
    heading.add_theme_color_override("font_color", ACCENT)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(heading)
    _points_label = Label.new()
    _points_label.add_theme_color_override("font_color", TEXT)
    header.add_child(_points_label)
    var close := Button.new()
    close.text = "CLOSE  [K]"
    close.pressed.connect(func(): visible = false)
    header.add_child(close)

    var tabs := HBoxContainer.new()
    layout.add_child(tabs)
    var melee_tab := Button.new()
    melee_tab.text = "FIST FIGHTING"
    melee_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    melee_tab.pressed.connect(func(): _select_style("melee"))
    tabs.add_child(melee_tab)
    var firearms_tab := Button.new()
    firearms_tab.text = "FIREARMS"
    firearms_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    firearms_tab.pressed.connect(func(): _select_style("firearms"))
    tabs.add_child(firearms_tab)

    _tree_title = Label.new()
    _tree_title.add_theme_font_size_override("font_size", 16)
    _tree_title.add_theme_color_override("font_color", ACCENT)
    layout.add_child(_tree_title)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    layout.add_child(scroll)
    _node_list = VBoxContainer.new()
    _node_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _node_list.add_theme_constant_override("separation", 5)
    scroll.add_child(_node_list)

    var footer := HBoxContainer.new()
    layout.add_child(footer)
    var hint := Label.new()
    hint.text = "Earn skill points by leveling up. Unlocks are permanent until you respec."
    hint.add_theme_color_override("font_color", MUTED)
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(hint)
    var reset := Button.new()
    reset.text = "RESET TREE"
    reset.pressed.connect(_ask_respec)
    footer.add_child(reset)

    _confirm_respec = ConfirmationDialog.new()
    _confirm_respec.title = "Reset combat training?"
    _confirm_respec.dialog_text = "Refund every point spent in this tree?"
    _confirm_respec.confirmed.connect(_respec)
    add_child(_confirm_respec)

func _select_style(style: String) -> void:
    _active_style = style
    _refresh()

func _refresh(_level: int = 0, _xp: int = 0, _points: int = 0) -> void:
    if not is_instance_valid(_node_list):
        return
    _points_label.text = "AVAILABLE POINTS: %d" % GameState.skill_points
    var tree: Dictionary = CombatSkillTrees.get_tree(_active_style)
    _tree_title.text = "%s  —  %s" % [str(tree.get("display_name", "Combat")), str(tree.get("description", ""))]
    for child in _node_list.get_children():
        child.queue_free()
    var nodes: Dictionary = tree.get("nodes", {})
    var ids: Array = nodes.keys()
    ids.sort_custom(func(a, b): return int(nodes[a].get("tier", 0)) < int(nodes[b].get("tier", 0)))
    var unlocked: Array = GameState.combat_skill_unlocks.get(_active_style, [])
    for node_id in ids:
        var node: Dictionary = nodes[node_id]
        var owned := node_id in unlocked
        var available := CombatSkillTrees.can_purchase(_active_style, str(node_id), unlocked, GameState.skill_points)
        var state_text := "UNLOCKED" if owned else ("AVAILABLE" if available else "LOCKED")
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 54)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.text = "%s  ·  %s  ·  %d SP\n%s" % [str(node.get("name", node_id)), state_text, int(node.get("cost", 1)), str(node.get("description", ""))]
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.disabled = owned or not available
        button.tooltip_text = "Prerequisites: %s" % ", ".join(node.get("requires", []))
        button.pressed.connect(_purchase.bind(str(node_id)))
        _node_list.add_child(button)

func _purchase(node_id: String) -> void:
    if GameState.purchase_combat_skill(_active_style, node_id):
        _refresh()

func _ask_respec() -> void:
    _confirm_respec.dialog_text = "Refund all points spent in %s? This removes its unlocks." % str(CombatSkillTrees.get_tree(_active_style).get("display_name", _active_style))
    _confirm_respec.popup_centered()

func _respec() -> void:
    GameState.respec_combat_skills(_active_style)
    _refresh()
