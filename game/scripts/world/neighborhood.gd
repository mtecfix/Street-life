extends Node2D

const NPC_POSITION := Vector2(590, 270)
const ENCOUNTER_POSITION := Vector2(745, 270)
const INTERACTION_RANGE := 76.0

var status_label: Label
var hint_label: Label
var dialogue_label: Label

func _ready() -> void:
    queue_redraw()
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

    var player := get_node_or_null("Player")
    if player:
        player.global_position = GameState.previous_world_position

    status_label = Label.new()
    status_label.position = Vector2(18, 14)
    status_label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.78))
    add_child(status_label)

    hint_label = Label.new()
    hint_label.position = Vector2(18, 42)
    hint_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.82))
    add_child(hint_label)

    dialogue_label = Label.new()
    dialogue_label.position = Vector2(18, 485)
    dialogue_label.add_theme_color_override("font_color", Color("#f3d59b"))
    dialogue_label.add_theme_font_size_override("font_size", 16)
    add_child(dialogue_label)

    _refresh_hud()

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
    draw_rect(Rect2(650, 55, 230, 105), Color("#5b646b"))
    draw_rect(Rect2(665, 390, 205, 95), Color("#665b50"))

    # NPC contact: Rico.
    draw_circle(NPC_POSITION, 15, Color("#d8b45d"))
    draw_circle(NPC_POSITION + Vector2(0, -5), 6, Color("#f0d8b2"))
    draw_string(ThemeDB.fallback_font, NPC_POSITION + Vector2(-20, 32), "RICO  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

    draw_circle(ENCOUNTER_POSITION, 20, Color("#d78b43"))
    draw_circle(ENCOUNTER_POSITION, 9, Color("#f3d59b"))
    draw_string(ThemeDB.fallback_font, Vector2(685, 310), "JOB SITE  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("interact"):
        return

    var player := get_node_or_null("Player")
    if player == null:
        return

    var npc_distance: float = player.global_position.distance_to(NPC_POSITION)
    var job_distance: float = player.global_position.distance_to(ENCOUNTER_POSITION)

    if npc_distance <= INTERACTION_RANGE and not GameState.mission_active and not GameState.mission_completed:
        GameState.mission_active = true
        dialogue_label.text = "Rico: I need you to handle a problem at the corner. Head to the marked job site."
        _refresh_hud()
    elif job_distance <= INTERACTION_RANGE and GameState.mission_active:
        GameState.previous_world_position = player.global_position
        GameState.last_combat_won = false
        SceneManager.change_to("res://scenes/combat/CombatArena.tscn")
    elif npc_distance <= INTERACTION_RANGE and GameState.mission_completed:
        dialogue_label.text = "Rico: Good work. You earned that payout. I'll keep you in mind."
    elif npc_distance <= INTERACTION_RANGE and GameState.mission_active:
        dialogue_label.text = "Rico: The job site is marked. Handle the situation and come back."
    elif job_distance <= INTERACTION_RANGE and not GameState.mission_active:
        dialogue_label.text = "No job is active. Talk to Rico first."

func _process(_delta: float) -> void:
    _refresh_hud()

func _refresh_hud() -> void:
    if status_label == null:
        return
    status_label.text = "STREET HUSTLER  |  CASH: $%d  |  DAY %d" % [GameState.player_cash, GameState.current_day]
    if GameState.mission_completed:
        hint_label.text = "MISSION COMPLETE: Corner dispute resolved. Find Rico for your next lead."
    elif GameState.mission_active:
        hint_label.text = "ACTIVE JOB: Go to the marked corner and press E to enter the encounter."
    else:
        hint_label.text = "Find Rico near the center of the block and press E to get your first job."

func _add_wall(center: Vector2, dimensions: Vector2) -> void:
    var wall := StaticBody2D.new()
    wall.position = center
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = dimensions
    collision.shape = rectangle
    wall.add_child(collision)
    add_child(wall)
