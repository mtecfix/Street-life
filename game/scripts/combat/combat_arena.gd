extends Node2D

var enemy_health := 3
var player_health := 5
var cooldown := 0.0
var status: Label
var stats: Label

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#171d29")
    bg.size = Vector2(960, 540)
    add_child(bg)

    stats = Label.new()
    stats.position = Vector2(24, 24)
    add_child(stats)

    var player := Polygon2D.new()
    player.polygon = PackedVector2Array([-15,-20, 15,-20, 18,10, 0,20, -18,10])
    player.color = Color("#63b9d1")
    player.position = Vector2(260, 270)
    add_child(player)

    var enemy := Polygon2D.new()
    enemy.polygon = PackedVector2Array([-18,-22, 18,-22, 24,12, 0,25, -24,12])
    enemy.color = Color("#d66a55")
    enemy.position = Vector2(690, 270)
    add_child(enemy)

    var heading := Label.new()
    heading.position = Vector2(24, 70)
    heading.text = "COMBAT ARENA  |  SPACE: ATTACK  |  ESC: RETREAT"
    add_child(heading)

    status = Label.new()
    status.position = Vector2(24, 485)
    add_child(status)
    _refresh()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        SceneManager.change_to("res://scenes/world/Neighborhood.tscn")
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
        _attack()

func _attack() -> void:
    if cooldown > 0.0 or enemy_health <= 0 or player_health <= 0:
        return
    cooldown = 0.45
    enemy_health -= 1
    if enemy_health > 0:
        player_health -= 1
        status.text = "You strike. The opponent counters."
    else:
        GameState.encounters_won += 1
        status.text = "Encounter cleared. Press ESC to return."
    _refresh()

func _refresh() -> void:
    stats.text = "PLAYER HP: %d    OPPONENT HP: %d" % [player_health, enemy_health]
    if enemy_health <= 0:
        status.text = "Encounter cleared. Press ESC to return."
    elif player_health <= 0:
        status.text = "You are exhausted. Press ESC to retreat."
