extends Node2D

const ARENA_SIZE := Vector2(960, 540)
const PLAYER_SPEED := 225.0
const PLAYER_ATTACK_RANGE := 82.0
const ATTACK_DAMAGE := 25
const DODGE_COST := 30.0
const ATTACK_COST := 18.0
const HEAVY_ATTACK_COST := 36.0

@export_enum("corner", "shopfront", "alley") var environment_kind: String = "corner"

var enemy_speed := 92.0
var enemy_attack_range := 76.0
var enemy_damage := 18.0
var enemy_windup := 0.78
var enemy_name := "Corner challenger"
var enemy_color := Color("#d66a55")
var enemy_health := 100.0
var encounter_reward := 50
var player_health := 100.0
var stamina := 100.0
var stamina_max := 100.0
var attack_cooldown := 0.0
var combo_step := 0
var combo_window_timer := 0.0
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
# Breakable props anchor combat to the environment instead of a generic arena.
var environment_props: Array[Dictionary] = []

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), Color("#171d29"))
    draw_rect(Rect2(0, 170, 960, 290), Color("#3d4144"))
    draw_rect(Rect2(0, 170, 960, 18), Color("#777b78"))
    draw_rect(Rect2(0, 442, 960, 18), Color("#777b78"))

    match environment_kind:
        "shopfront":
            draw_rect(Rect2(0, 0, 960, 170), Color("#493c38"))
            draw_rect(Rect2(78, 24, 804, 128), Color("#806554"))
            draw_rect(Rect2(110, 55, 230, 75), Color("#29434d"))
            draw_rect(Rect2(620, 55, 230, 75), Color("#29434d"))
            draw_rect(Rect2(360, 18, 240, 38), Color("#c18e55"))
            draw_string(ThemeDB.fallback_font, Vector2(385, 44), "MAYA'S MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#fff0ce"))
            draw_rect(Rect2(62, 214, 86, 72), Color("#59665d"))
            draw_rect(Rect2(72, 202, 66, 14), Color("#87928a"))
            draw_rect(Rect2(790, 330, 92, 58), Color("#8b6847"))
            draw_rect(Rect2(805, 312, 62, 18), Color("#bd9667"))
            draw_string(ThemeDB.fallback_font, Vector2(28, 495), "STORE FRONT  /  SIDEWALK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e7c99d"))
        "alley":
            draw_rect(Rect2(0, 0, 190, 540), Color("#493b3a"))
            draw_rect(Rect2(770, 0, 190, 540), Color("#493b3a"))
            draw_rect(Rect2(18, 20, 154, 500), Color("#654b45"))
            draw_rect(Rect2(788, 20, 154, 500), Color("#654b45"))
            for y in range(45, 500, 34):
                draw_line(Vector2(20, y), Vector2(170, y), Color("#80645a"), 2.0)
                draw_line(Vector2(790, y), Vector2(940, y), Color("#80645a"), 2.0)
            draw_rect(Rect2(34, 220, 126, 112), Color("#46564f"))
            draw_rect(Rect2(44, 204, 106, 18), Color("#77867b"))
            draw_rect(Rect2(806, 330, 112, 70), Color("#896744"))
            draw_rect(Rect2(824, 310, 76, 20), Color("#b18a5b"))
            draw_line(Vector2(190, 170), Vector2(770, 170), Color("#9b8070"), 5.0)
            draw_line(Vector2(190, 460), Vector2(770, 460), Color("#9b8070"), 5.0)
            draw_string(ThemeDB.fallback_font, Vector2(360, 34), "SERVICE ALLEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e5c8a8"))
        _:
            draw_rect(Rect2(0, 0, 960, 170), Color("#45413c"))
            draw_rect(Rect2(60, 35, 840, 118), Color("#65584d"))
            draw_rect(Rect2(110, 58, 160, 72), Color("#304650"))
            draw_rect(Rect2(690, 58, 160, 72), Color("#304650"))
            draw_rect(Rect2(360, 40, 240, 18), Color("#c18e55"))
            draw_string(ThemeDB.fallback_font, Vector2(390, 31), "THE CORNER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f0d7ad"))
            for x in range(90, 900, 150):
                draw_rect(Rect2(x, 194, 54, 12), Color("#d6cba8"))
            draw_rect(Rect2(72, 300, 28, 58), Color("#b64e3d"))
            draw_rect(Rect2(66, 292, 40, 10), Color("#d98a68"))
            draw_string(ThemeDB.fallback_font, Vector2(28, 495), "NEIGHBORHOOD STREET CORNER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e7c99d"))

    # Draw the location-specific props after the fixed environment art.
    for prop in environment_props:
        if int(prop["health"]) <= 0:
            continue
        var prop_position: Vector2 = prop["position"]
        match str(prop["kind"]):
            "crate", "boxes":
                draw_rect(Rect2(prop_position - Vector2(22, 18), Vector2(44, 36)), Color("#9b7048"))
                draw_line(prop_position + Vector2(-18, -14), prop_position + Vector2(18, 14), Color("#d1a16a"), 3.0)
                draw_line(prop_position + Vector2(18, -14), prop_position + Vector2(-18, 14), Color("#d1a16a"), 3.0)
            "trash":
                draw_circle(prop_position, 20, Color("#4c6255"))
                draw_circle(prop_position + Vector2(9, -8), 11, Color("#667968"))
            "pallet":
                draw_rect(Rect2(prop_position - Vector2(25, 12), Vector2(50, 24)), Color("#98734d"))
                for plank in range(3):
                    draw_line(prop_position + Vector2(-20 + plank * 20, -10), prop_position + Vector2(-20 + plank * 20, 10), Color("#d0a878"), 2.0)
            "hydrant":
                draw_rect(Rect2(prop_position - Vector2(9, 14), Vector2(18, 28)), Color("#b64e3d"))
                draw_circle(prop_position + Vector2(0, -14), 10, Color("#d98a68"))
            "bin":
                draw_rect(Rect2(prop_position - Vector2(16, 20), Vector2(32, 40)), Color("#526a63"))
                draw_rect(Rect2(prop_position + Vector2(-19, -22), Vector2(38, 5)), Color("#91a49a"))

func _environment_label() -> String:
    match environment_kind:
        "shopfront":
            return "MAYA'S MARKET FRONT"
        "alley":
            return "BACK ALLEY"
        _:
            return "STREET CORNER"

func _ready() -> void:
    _configure_encounter()
    _build_environment_props()
    player_health = clampf(float(GameState.player_health), 1.0, 100.0)
    stamina_max = GameState.get_max_stamina()
    stamina = stamina_max
    queue_redraw()

    player = Polygon2D.new()
    player.polygon = PackedVector2Array([-15,-20, 15,-20, 18,10, 0,20, -18,10])
    player.color = Color("#63b9d1")
    player.position = Vector2(260, 270)
    add_child(player)

    enemy = Polygon2D.new()
    enemy.polygon = PackedVector2Array([-18,-22, 18,-22, 24,12, 0,25, -24,12])
    enemy.color = enemy_color
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
    _add_bar(enemy_name.to_upper(), Vector2(24, 91), enemy_health, "enemy")
    _add_bar("STAMINA", Vector2(24, 128), stamina, "stamina")

    var heading := Label.new()
    heading.position = Vector2(24, 166)
    heading.text = "%s  |  WASD: MOVE   SPACE: COMBO   Q: HEAVY   SHIFT: DODGE   ESC: RETREAT" % _environment_label()
    heading.add_theme_color_override("font_color", Color("#d6dce7"))
    add_child(heading)

    status = Label.new()
    status.position = Vector2(24, 490)
    status.add_theme_font_size_override("font_size", 16)
    add_child(status)
    _set_status("Face %s. Watch for the red attack warning." % enemy_name)
    _refresh()

func _configure_encounter() -> void:
    match GameState.current_encounter_id:
        "shop_guard":
            enemy_name = "Shopfront agitator"
            enemy_health = 82.0
            enemy_speed = 118.0
            enemy_attack_range = 70.0
            enemy_damage = 14.0
            enemy_windup = 0.64
            enemy_color = Color("#c58c4e")
            encounter_reward = 40
        "alley_ambush":
            enemy_name = "Alley runner"
            enemy_health = 125.0
            enemy_speed = 138.0
            enemy_attack_range = 82.0
            enemy_damage = 22.0
            enemy_windup = 0.58
            enemy_color = Color("#9e6bb0")
            encounter_reward = 35
        _:
            enemy_name = "Corner challenger"
            enemy_health = 100.0
            enemy_speed = 92.0
            enemy_attack_range = 76.0
            enemy_damage = 18.0
            enemy_windup = 0.78
            enemy_color = Color("#d66a55")
            encounter_reward = 50

func _process(delta: float) -> void:
    if finished:
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    combo_window_timer = maxf(0.0, combo_window_timer - delta)
    if combo_window_timer <= 0.0:
        combo_step = 0
    enemy_recovery = maxf(0.0, enemy_recovery - delta)
    invulnerability_timer = maxf(0.0, invulnerability_timer - delta)
    stamina = minf(stamina_max, stamina + GameState.get_stamina_regen() * delta)

    if dodge_timer > 0.0:
        dodge_timer = maxf(0.0, dodge_timer - delta)
        player.position += dodge_direction * 510.0 * delta
    else:
        var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        player.position += direction * GameState.get_player_speed() * delta

    var horizontal_margin := 210.0 if environment_kind == "alley" else 38.0
    player.position.x = clampf(player.position.x, horizontal_margin, ARENA_SIZE.x - horizontal_margin)
    player.position.y = clampf(player.position.y, 205.0, 445.0)

    var distance := enemy.position.distance_to(player.position)
    if distance > 61.0:
        enemy.position = enemy.position.move_toward(player.position, enemy_speed * delta)

    if telegraph_timer >= 0.0:
        telegraph_timer -= delta
        telegraph.position = enemy.position
        telegraph.visible = true
        if telegraph_timer <= 0.0:
            _resolve_enemy_attack()
    elif enemy_recovery <= 0.0 and distance <= enemy_attack_range:
        telegraph_timer = enemy_windup
        telegraph.position = enemy.position
        telegraph.visible = true
        _set_status("%s winding up — DODGE NOW!" % enemy_name)
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
        elif event.keycode == KEY_Q:
            _heavy_attack()
        elif event.keycode == KEY_SHIFT:
            _dodge()

func _attack() -> void:
    if finished or attack_cooldown > 0.0 or stamina < ATTACK_COST:
        return
    if player.position.distance_to(enemy.position) > PLAYER_ATTACK_RANGE:
        _set_status("Too far away. Move closer before attacking.")
        return

    if _try_attack_environment_prop(get_combo_damage(GameState.get_attack_damage(), combo_step)):
        stamina -= ATTACK_COST
        attack_cooldown = 0.42
        combo_step = 0
        combo_window_timer = 0.0
        _refresh()
        return

    var damage := get_combo_damage(GameState.get_attack_damage(), combo_step)
    stamina -= ATTACK_COST
    attack_cooldown = 0.42
    combo_step = (combo_step + 1) % 3
    combo_window_timer = 0.85
    enemy_health = maxf(0.0, enemy_health - damage)
    enemy.modulate = Color("#ffffff")
    if enemy_health <= 0.0:
        _win_encounter()
    else:
        var combo_label := "3-HIT COMBO!" if combo_step == 0 else "COMBO %d/3" % combo_step
        _set_status("%s — %d damage. Press Q for a heavy strike." % [combo_label, damage])

func _heavy_attack() -> void:
    if finished or attack_cooldown > 0.0 or stamina < HEAVY_ATTACK_COST:
        return
    if player.position.distance_to(enemy.position) > PLAYER_ATTACK_RANGE:
        _set_status("Heavy strike out of range. Move closer.")
        return

    if _try_attack_environment_prop(get_heavy_attack_damage(GameState.get_attack_damage())):
        stamina -= HEAVY_ATTACK_COST
        attack_cooldown = 0.78
        combo_step = 0
        combo_window_timer = 0.0
        _refresh()
        return

    stamina -= HEAVY_ATTACK_COST
    attack_cooldown = 0.78
    combo_step = 0
    combo_window_timer = 0.0
    var damage := get_heavy_attack_damage(GameState.get_attack_damage())
    enemy_health = maxf(0.0, enemy_health - damage)
    enemy.modulate = Color("#ffffff")

    var interrupted := telegraph_timer >= 0.0
    if interrupted:
        telegraph_timer = -1.0
        telegraph.visible = false
        enemy_recovery = 0.85

    if enemy_health <= 0.0:
        _win_encounter()
    elif interrupted:
        _set_status("HEAVY HIT — %d damage. You interrupted the incoming strike!" % damage)
    else:
        _set_status("HEAVY HIT — %d damage. Recover your stamina." % damage)

func get_combo_damage(base_damage: int, combo_index: int) -> int:
    var multipliers := [1.0, 1.15, 1.35]
    return roundi(float(base_damage) * float(multipliers[clampi(combo_index, 0, 2)]))

func get_heavy_attack_damage(base_damage: int) -> int:
    return roundi(float(base_damage) * 1.8)

func _dodge() -> void:
    if finished or dodge_timer > 0.0 or stamina < GameState.get_dodge_cost():
        return
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction == Vector2.ZERO:
        direction = (player.position - enemy.position).normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.LEFT
    dodge_direction = direction.normalized()
    stamina -= GameState.get_dodge_cost()
    dodge_timer = 0.20
    invulnerability_timer = 0.42
    if telegraph_timer >= 0.0:
        _set_status("Dodge! Create space before the opponent's next move.")

func _resolve_enemy_attack() -> void:
    telegraph_timer = -1.0
    telegraph.visible = false
    enemy_recovery = 1.05
    if player.position.distance_to(enemy.position) <= enemy_attack_range + 20.0 and invulnerability_timer <= 0.0:
        player_health = maxf(0.0, player_health - enemy_damage)
        GameState.player_health = int(player_health)
        _set_status("You took a hit. Use SHIFT to dodge the next warning.")
        if player_health <= 0.0:
            _lose_encounter()
    else:
        _set_status("Opponent missed. Counter while there is an opening.")

func _win_encounter() -> void:
    finished = true
    GameState.encounters_won += 1
    var xp_reward := 50 if GameState.current_encounter_id == "corner_brawler" else (45 if GameState.current_encounter_id == "shop_guard" else 65)
    var levels_gained := GameState.award_experience(xp_reward)
    GameState.last_combat_won = true
    GameState.player_health = maxi(1, int(player_health))
    GameState.player_cash += encounter_reward
    if GameState.current_encounter_id == "alley_ambush":
        GameState.world_flags["alley_encounter_completed"] = true
        GameState.adjust_reputation("locals", 3)
        GameState.mission_outcome = "alley_secured"
    elif GameState.current_encounter_id == "shop_guard":
        GameState.mission_active = false
        GameState.mission_completed = true
        GameState.mission_outcome = "protected_shop"
        GameState.adjust_reputation("locals", 7)
        GameState.adjust_relationship("maya", 3)
    else:
        GameState.mission_active = false
        GameState.mission_completed = true
        GameState.mission_outcome = "stood_ground"
        GameState.adjust_reputation("locals", 2)
        GameState.adjust_reputation("rivals", -2)
    EventBus.encounter_finished.emit(GameState.current_encounter_id, "victory")
    SaveManager.save_game()
    var progression_message := "  LEVEL UP! +%d skill point(s)." % levels_gained if levels_gained > 0 else ""
    _set_status("VICTORY — +$%d  +%d XP.%s Press ESC to return." % [encounter_reward, xp_reward, progression_message])
    _refresh()

func _lose_encounter() -> void:
    finished = true
    GameState.last_combat_won = false
    GameState.player_health = 0
    if GameState.current_encounter_id != "alley_ambush":
        GameState.mission_active = false
        GameState.mission_completed = false
        GameState.mission_choice = ""
        GameState.mission_outcome = "failed"
    GameState.adjust_reputation("locals", -3)
    EventBus.encounter_finished.emit(GameState.current_encounter_id, "defeat")
    SaveManager.save_game()
    _set_status("DEFEATED — no payout. Press ESC to return to the clinic.")
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
    bar.max_value = 140 if kind == "enemy" and initial_value > 100.0 else (stamina_max if kind == "stamina" else 100)
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


func _build_environment_props() -> void:
    environment_props.clear()
    match environment_kind:
        "shopfront":
            environment_props = [
                {"name": "Produce crate", "position": Vector2(112, 252), "health": 2, "kind": "crate"},
                {"name": "Delivery boxes", "position": Vector2(842, 356), "health": 2, "kind": "boxes"}
            ]
        "alley":
            environment_props = [
                {"name": "Trash bags", "position": Vector2(242, 278), "health": 1, "kind": "trash"},
                {"name": "Loose pallet", "position": Vector2(718, 365), "health": 2, "kind": "pallet"}
            ]
        _:
            environment_props = [
                {"name": "Fire hydrant", "position": Vector2(86, 328), "health": 2, "kind": "hydrant"},
                {"name": "Street bin", "position": Vector2(862, 350), "health": 2, "kind": "bin"}
            ]
    queue_redraw()

func _try_attack_environment_prop(damage: int) -> bool:
    # Props become melee targets only when closer than the opponent. This avoids
    # stealing attacks intended for the enemy when both are in striking range.
    var nearest_index := -1
    var nearest_distance := PLAYER_ATTACK_RANGE
    var enemy_distance: float = player.position.distance_to(enemy.position)
    for index in range(environment_props.size()):
        var prop: Dictionary = environment_props[index]
        if int(prop["health"]) <= 0:
            continue
        var distance: float = player.position.distance_to(prop["position"])
        if distance < nearest_distance and distance < enemy_distance:
            nearest_distance = distance
            nearest_index = index
    if nearest_index < 0:
        return false

    var prop: Dictionary = environment_props[nearest_index]
    prop["health"] = maxi(0, int(prop["health"]) - maxi(1, floori(float(damage) / 25.0)))
    environment_props[nearest_index] = prop
    if int(prop["health"]) == 0:
        enemy_recovery = maxf(enemy_recovery, 0.35)
        _set_status("%s cleared. You opened up room to move." % str(prop["name"]))
    else:
        _set_status("%s damaged. Keep striking to clear it." % str(prop["name"]))
    queue_redraw()
    return true

func get_environment_prop_count() -> int:
    var remaining := 0
    for prop in environment_props:
        if int(prop["health"]) > 0:
            remaining += 1
    return remaining
