extends Node2D

var status_label: Label

func _ready() -> void:
    queue_redraw()
    # Invisible collision boundaries and building footprints for the blockout.
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
    status_label = Label.new()
    status_label.position = Vector2(18, 14)
    status_label.text = "STREET HUSTLER  |  NEIGHBORHOOD  |  WASD / ARROWS: MOVE"
    status_label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.78))
    add_child(status_label)

    var hint := Label.new()
    hint.position = Vector2(18, 42)
    hint.text = "Walk to the marked encounter and press E to enter the arena."
    hint.add_theme_color_override("font_color", Color(0.72, 0.78, 0.82))
    add_child(hint)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("#202c2b"))
    # Roads and sidewalks: temporary blockout geometry.
    draw_rect(Rect2(0, 205, 960, 130), Color("#45494c"))
    draw_rect(Rect2(360, 0, 150, 540), Color("#45494c"))
    draw_rect(Rect2(0, 195, 960, 10), Color("#777b78"))
    draw_rect(Rect2(0, 335, 960, 10), Color("#777b78"))
    draw_rect(Rect2(350, 0, 10, 540), Color("#777b78"))
    draw_rect(Rect2(510, 0, 10, 540), Color("#777b78"))
    # Crosswalk markings.
    for i in range(7):
        draw_rect(Rect2(380 + i * 18, 210, 9, 28), Color("#d7d0b3"))
        draw_rect(Rect2(380 + i * 18, 302, 9, 28), Color("#d7d0b3"))
    # Buildings and a highlighted encounter marker.
    draw_rect(Rect2(70, 55, 205, 105), Color("#6c594d"))
    draw_rect(Rect2(650, 55, 230, 105), Color("#5b646b"))
    draw_rect(Rect2(665, 390, 205, 95), Color("#665b50"))
    draw_circle(Vector2(745, 270), 20, Color("#d78b43"))
    draw_circle(Vector2(745, 270), 9, Color("#f3d59b"))
    draw_string(ThemeDB.fallback_font, Vector2(685, 310), "ENCOUNTER  [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        var player := get_node_or_null("Player")
        if player and player.global_position.distance_to(Vector2(745, 270)) < 90:
            GameState.previous_world_position = player.global_position
            SceneManager.change_to("res://scenes/combat/CombatArena.tscn")


func _add_wall(center: Vector2, dimensions: Vector2) -> void:
    var wall := StaticBody2D.new()
    wall.position = center
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = dimensions
    collision.shape = rectangle
    wall.add_child(collision)
    add_child(wall)
