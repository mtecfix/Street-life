extends Node2D

const ARENA_SIZE := Vector2(960, 540)
const PLAYER_SPEED := 225.0
const ENEMY_SPEED := 92.0
const PLAYER_ATTACK_RANGE := 82.0
const ENEMY_ATTACK_RANGE := 76.0
const ATTACK_DAMAGE := 25
const ENEMY_DAMAGE := 18
const DODGE_COST := 30.0
const ATTACK_COST := 18.0

var player_health := 100.0
var enemy_health := 100.0
var stamina := 100.0
var attack_cooldown := 0.0
var enemy_recovery := 0.0
var telegraph_timer := -1.0
var dodge_timer := 0.0
var invulnerability_timer := 0.0
var dodge_direction := Vector2.ZERO
var finished := false

var player: Polygon2D
var enemy: Polygon2D
var telegraph: Polygon2D
var stats: Label
var status: Label
var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var stamina_bar: ProgressBar

func _ready() -> void:
    player_health = clampf(float(GameState.player_health), 1.0, 100.0)
    var bg := ColorRect.new()
    bg.color = Color("#171d29")
    bg.size = ARENA_SIZE
    add_child(bg)

    var floor_marks := Node2D.new()
    add_child(floor_marks)
    floor_marks.draw.connect(func() -> void:
        for x in range(80, 960, 80):
            floor_marks.draw_line(Vector2(x, 125), Vector2(x, 420), Color(0.25, 0.31, 0.39, 0.35), 1.0)
        floor_marks.draw_arc(Vector2(480, 270), 115.0, 0.0, TAU, 64, Color(0.32, 0.39, 0.48, 0.6), 2.0)
    )
    floor_marks.queue_redraw()

    player = Polygon2D.new()
    player.polygon = PackedVector2Array([-15,-20, 15,-20, 18,10, 0,20, -18,10])
    player.color = Color("#63b9d1")
    player.position = Vector2(260, 270)
    add_child(player)

    enemy = Polygon2D.new()
    enemy.polygon = PackedVector2Array([-18,-22, 18,-22, 24,12, 0,25, -24,12])
    enemy.color = Color("#d66a55")
    enemy.position = Vector2(690, 270)
    add_child(enemy)

    telegraph = Polygon2D.new()
    telegraph.polygon = _make_circle(54.0, 40)
    telegraph.color = Color(0.95, 0.22, 0.18, 0.25)
    telegraph.visible = false
    add_child(telegraph)

    stats = Label.new()
    stats.position = Vector2(24, 18)
    stats.add_theme_font_size_override("font_size", 18)
    add_child(stats)

    _add_bar("YOUR HEALTH", Vector2(24, 54), player_health, "player")
    _add_bar("OPPONENT", Vector2(24, 91), enemy_health, "enemy")
    _add_bar("STAMINA", Vector2(24, 128), stamina, "stamina")

    var heading := Label.new()
    heading.position = Vector2(24, 166)
    heading.text = "WASD: MOVE   SPACE: ATTACK   SHIFT: DODGE   ESC: RETREAT"
    heading.add_theme_color_override("font_color", Color("#d6dce7"))
    add_child(heading)

    status = Label.new()
    status.position = Vector2(24, 490)
    status.add_theme_font_size_override("font_size", 16)
    add_child(status)
    _set_status("Close the distance. Watch for the red attack warning.")
    _refresh()

func _process(delta: float) -> void:
    if finished:
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    enemy_recovery = maxf(0.0, enemy_recovery - delta)
    invulnerability_timer = maxf(0.0, invulnerability_timer - delta)
    stamina = minf(100.0, stamina + 14.0 * delta)

    if dodge_timer > 0.0:
        dodge_timer = maxf(0.0, dodge_timer - delta)
        player.position += dodge_direction * 510.0 * delta
    else:
        var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        player.position += direction * PLAYER_SPEED * delta

    player.position.x = clampf(player.position.x, 38.0, ARENA_SIZE.x - 38.0)
    player.position.y = clampf(player.position.y, 205.0, 445.0)

    var distance := enemy.position.distance_to(player.position)
    if distance > 61.0:
        enemy.position = enemy.position.move_toward(player.position, ENEMY_SPEED * delta)

    if telegraph_timer >= 0.0:
        telegraph_timer -= delta
        telegraph.position = enemy.position
        telegraph.visible = true
        if telegraph_timer <= 0.0:
            _resolve_enemy_attack()
    elif enemy_recovery <= 0.0 and distance <= ENEMY_ATTACK_RANGE:
        telegraph_timer = 0.78
        telegraph.position = enemy.position
        telegraph.visible = true
        _set_status("OPPONENT WINDING UP — DODGE NOW!")
    else:
        telegraph.visible = false

    player.modulate = Color(1.0, 1.0, 1.0, 0.45 if invulnerability_timer > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0)
    _refresh()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _return_to_neighborhood()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            _attack()
        elif event.keycode == KEY_SHIFT:
            _dodge()

func _attack() -> void:
    if finished or attack_cooldown > 0.0 or stamina < ATTACK_COST:
        return
    if player.position.distance_to(enemy.position) > PLAYER_ATTACK_RANGE:
        _set_status("Too far away. Move closer before attacking.")
        return
    stamina -= ATTACK_COST
    attack_cooldown = 0.42
    enemy_health = maxf(0.0, enemy_health - ATTACK_DAMAGE)
    enemy.modulate = Color("#ffffff")
    if enemy_health <= 0.0:
        _win_encounter()
    else:
        _set_status("Clean hit. Keep pressure on the opponent.")

func _dodge() -> void:
    if finished or dodge_timer > 0.0 or stamina < DODGE_COST:
        return
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction == Vector2.ZERO:
        direction = (player.position - enemy.position).normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.LEFT
    dodge_direction = direction.normalized()
    stamina -= DODGE_COST
    dodge_timer = 0.20
    invulnerability_timer = 0.42
    if telegraph_timer >= 0.0:
        _set_status("Dodge! Create space before the opponent's next move.")

func _resolve_enemy_attack() -> void:
    telegraph_timer = -1.0
    telegraph.visible = false
    enemy_recovery = 1.05
    if player.position.distance_to(enemy.position) <= ENEMY_ATTACK_RANGE + 20.0 and invulnerability_timer <= 0.0:
        player_health = maxf(0.0, player_health - ENEMY_DAMAGE)
        GameState.player_health = int(player_health)
        _set_status("You took a hit. Use SHIFT to dodge the next warning.")
        if player_health <= 0.0:
            _lose_encounter()
    else:
        _set_status("Opponent missed. Counter while there is an opening.")

func _win_encounter() -> void:
    finished = true
    GameState.encounters_won += 1
    GameState.last_combat_won = true
    GameState.mission_active = false
    GameState.mission_completed = true
    GameState.player_health = maxi(1, int(player_health))
    GameState.player_cash += GameState.mission_reward
    GameState.adjust_reputation("locals", 5)
    EventBus.encounter_finished.emit("corner_dispute", "victory")
    SaveManager.save_game()
    _set_status("VICTORY — +$%d earned. Press ESC to return." % GameState.mission_reward)
    _refresh()

func _lose_encounter() -> void:
    finished = true
    GameState.last_combat_won = false
    GameState.mission_active = false
    GameState.player_health = 0
    EventBus.encounter_finished.emit("corner_dispute", "defeat")
    SaveManager.save_game()
    _set_status("DEFEATED — retreat with no payout. Press ESC to return.")
    _refresh()

func _return_to_neighborhood() -> void:
    SceneManager.change_to("res://scenes/world/Neighborhood.tscn")

func _add_bar(caption: String, bar_position: Vector2, initial_value: float, kind: String) -> void:
    var label := Label.new()
    label.position = bar_position
    label.text = caption
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Color("#b9c5d6"))
    add_child(label)

    var bar := ProgressBar.new()
    bar.position = bar_position + Vector2(110, 1)
    bar.size = Vector2(220, 15)
    bar.min_value = 0
    bar.max_value = 100
    bar.value = initial_value
    bar.show_percentage = false
    add_child(bar)

    if kind == "player":
        player_hp_bar = bar
    elif kind == "enemy":
        enemy_hp_bar = bar
    else:
        stamina_bar = bar

func _make_circle(radius: float, segments: int) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(segments):
        var angle := TAU * float(i) / float(segments)
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    return points

func _set_status(message: String) -> void:
    if status:
        status.text = message

func _refresh() -> void:
    if stats:
        stats.text = "CASH: $%d" % GameState.player_cash
    if player_hp_bar:
        player_hp_bar.value = player_health
    if enemy_hp_bar:
        enemy_hp_bar.value = enemy_health
    if stamina_bar:
        stamina_bar.value = stamina
