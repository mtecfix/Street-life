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
var combat_style := "melee"
var ammo_in_magazine := 8
var reserve_ammo := 32
var reload_timer := 0.0
var reload_duration := 1.45
var guard_timer := 0.0
var flank_followup_ready := false
var last_shot_timer := 0.0

var player: Polygon2D
var enemy: Polygon2D
var telegraph: Polygon2D
var stats: Label
var status: Label
var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var stamina_bar: ProgressBar

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
    _set_status("Face %s. TAB switches combat style; K opens training." % enemy_name)
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
    guard_timer = maxf(0.0, guard_timer - delta)
    last_shot_timer = maxf(0.0, last_shot_timer - delta)
    if reload_timer > 0.0:
        reload_timer -= delta
        if reload_timer <= 0.0:
            var loaded := mini(8 - ammo_in_magazine, reserve_ammo)
            ammo_in_magazine += loaded
            reserve_ammo -= loaded
            _set_status("Reload complete — %d / %d rounds." % [ammo_in_magazine, reserve_ammo])
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
        var move_speed := GameState.get_player_speed()
        if combat_style == "firearms" and GameState.has_combat_skill("firearms", "mobile_operator"):
            move_speed *= 1.08
        player.position += direction * move_speed * delta

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
        if event.keycode == KEY_TAB:
            _toggle_combat_style()
        elif event.keycode == KEY_F:
            if combat_style == "firearms":
                _firearm_attack()
        elif event.keycode == KEY_R:
            if combat_style == "firearms":
                _reload_firearm()
            else:
                _body_shot()
        elif event.keycode == KEY_C:
            _guard()
        elif event.keycode == KEY_SPACE:
            _attack()
        elif event.keycode == KEY_Q:
            _heavy_attack()
        elif event.keycode == KEY_SHIFT:
            _dodge()

func _attack() -> void:
    if combat_style != "melee" or finished or attack_cooldown > 0.0 or stamina < ATTACK_COST:
        return
    if player.position.distance_to(enemy.position) > PLAYER_ATTACK_RANGE:
        _set_status("Too far away. Move closer before attacking.")
        return

    var damage := get_combo_damage(GameState.get_attack_damage(), combo_step)
    if combo_step == 2 and GameState.has_combat_skill("melee", "pressure_fighter"):
        damage = roundi(float(damage) * 1.18)
    if flank_followup_ready:
        damage = roundi(float(damage) * 1.20)
        flank_followup_ready = false
    stamina -= ATTACK_COST
    attack_cooldown = 0.42
    combo_step = (combo_step + 1) % 3
    combo_window_timer = 0.85 * (1.15 if GameState.has_combat_skill("melee", "combination_flow") else 1.0)
    enemy_health = maxf(0.0, enemy_health - damage)
    enemy.modulate = Color("#ffffff")
    if enemy_health <= 0.0:
        _win_encounter()
    else:
        var combo_label := "3-HIT COMBO!" if combo_step == 0 else "COMBO %d/3" % combo_step
        _set_status("%s — %d damage. Press Q for a heavy strike." % [combo_label, damage])

func _heavy_attack() -> void:
    if combat_style != "melee" or finished or attack_cooldown > 0.0 or stamina < HEAVY_ATTACK_COST:
        return
    if player.position.distance_to(enemy.position) > PLAYER_ATTACK_RANGE:
        _set_status("Heavy strike out of range. Move closer.")
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
    var dodge_cost := GameState.get_dodge_cost() * (0.88 if GameState.has_combat_skill("melee", "quick_step") else 1.0)
    if finished or dodge_timer > 0.0 or stamina < dodge_cost:
        return
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction == Vector2.ZERO:
        direction = (player.position - enemy.position).normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.LEFT
    dodge_direction = direction.normalized()
    stamina -= dodge_cost
    dodge_timer = 0.24 if GameState.has_combat_skill("melee", "quick_step") else 0.20
    if telegraph_timer >= 0.0 and GameState.has_combat_skill("melee", "angle_change"):
        flank_followup_ready = true
    invulnerability_timer = 0.42
    if telegraph_timer >= 0.0:
        _set_status("Dodge! Create space before the opponent's next move.")

func _resolve_enemy_attack() -> void:
    telegraph_timer = -1.0
    telegraph.visible = false
    enemy_recovery = 1.05
    if guard_timer > 0.0 and combat_style == "melee":
        guard_timer = 0.0
        if GameState.has_combat_skill("melee", "counter_window"):
            var counter_damage := 20.0 * (1.30 if GameState.has_combat_skill("melee", "counter_specialist") else 1.0)
            enemy_health = maxf(0.0, enemy_health - counter_damage)
            _set_status("PERFECT BLOCK — counter for %d damage!" % roundi(counter_damage))
            if enemy_health <= 0.0:
                _win_encounter()
        else:
            _set_status("BLOCKED! You absorbed the incoming strike.")
    elif player.position.distance_to(enemy.position) <= enemy_attack_range + 20.0 and invulnerability_timer <= 0.0:
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
        if combat_style == "firearms":
            stats.text = "CASH: $%d   FIREARMS   AMMO: %d / %d%s" % [GameState.player_cash, ammo_in_magazine, reserve_ammo, "   RELOADING" if reload_timer > 0.0 else ""]
        else:
            stats.text = "CASH: $%d   FIST FIGHTING   SP: %d" % [GameState.player_cash, GameState.skill_points]
    if player_hp_bar:
        player_hp_bar.value = player_health
    if enemy_hp_bar:
        enemy_hp_bar.value = enemy_health
    if stamina_bar:
        stamina_bar.value = stamina


func _toggle_combat_style() -> void:
    if finished:
        return
    combat_style = "firearms" if combat_style == "melee" else "melee"
    attack_cooldown = 0.0
    reload_timer = 0.0
    _set_status("Combat style: %s. %s" % ["FIREARMS" if combat_style == "firearms" else "FIST FIGHTING", "F fires, R reloads." if combat_style == "firearms" else "SPACE combo, Q heavy, C guard."])
    _refresh()

func _firearm_attack() -> void:
    if finished or combat_style != "firearms" or attack_cooldown > 0.0 or reload_timer > 0.0:
        return
    if ammo_in_magazine <= 0:
        _set_status("Magazine empty — press R to reload.")
        return
    var distance := player.position.distance_to(enemy.position)
    if distance > 520.0:
        _set_status("Target out of range. Close the distance.")
        return
    ammo_in_magazine -= 1
    var damage := 18.0
    var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO
    if not moving and GameState.has_combat_skill("firearms", "steady_hands"):
        damage *= 1.10
    if GameState.has_combat_skill("firearms", "controlled_burst") and last_shot_timer > 0.0:
        damage *= 1.12
    if ammo_in_magazine <= 2 and GameState.has_combat_skill("firearms", "last_round_focus"):
        damage *= 1.08
    if GameState.has_combat_skill("firearms", "precision_specialist"):
        damage *= 1.15
    if GameState.has_combat_skill("firearms", "mobile_operator"):
        attack_cooldown = 0.36
    elif GameState.has_combat_skill("firearms", "snap_aim"):
        attack_cooldown = 0.38
    else:
        attack_cooldown = 0.48
    if GameState.has_combat_skill("firearms", "precision_specialist"):
        attack_cooldown += 0.04
    last_shot_timer = 0.72
    enemy_health = maxf(0.0, enemy_health - damage)
    enemy.modulate = Color("#fff2c9")
    if enemy_health <= 0.0:
        _win_encounter()
    else:
        _set_status("HIT CONFIRMED — %d damage. %d rounds remain." % [roundi(damage), ammo_in_magazine])
    _refresh()

func _reload_firearm() -> void:
    if finished or combat_style != "firearms" or reload_timer > 0.0:
        return
    if ammo_in_magazine >= 8 or reserve_ammo <= 0:
        _set_status("Reload unavailable — magazine full or reserve empty.")
        return
    var duration := reload_duration
    if GameState.has_combat_skill("firearms", "fast_hands"):
        duration *= 0.92
    if GameState.has_combat_skill("firearms", "quick_reload"):
        duration *= 0.84
    if ammo_in_magazine > 0 and GameState.has_combat_skill("firearms", "ammo_discipline"):
        duration *= 0.88
    reload_timer = duration
    attack_cooldown = maxf(attack_cooldown, duration)
    _set_status("Reloading — create space. %0.1f seconds." % duration)

func _body_shot() -> void:
    if finished or not GameState.has_combat_skill("melee", "body_shot"):
        _set_status("Body Shot is locked. Unlock it in Combat Training (K).")
        return
    if attack_cooldown > 0.0 or stamina < 28.0:
        _set_status("Not ready — recover stamina before a body shot.")
        return
    if player.position.distance_to(enemy.position) > PLAYER_ATTACK_RANGE:
        _set_status("Body shot out of range.")
        return
    stamina -= 28.0
    attack_cooldown = 0.72
    combo_step = 0
    var interrupted := telegraph_timer >= 0.0
    enemy_health = maxf(0.0, enemy_health - 34.0)
    if interrupted:
        telegraph_timer = -1.0
        telegraph.visible = false
        enemy_recovery = 1.0
    if enemy_health <= 0.0:
        _win_encounter()
    else:
        _set_status("BODY SHOT — 34 damage%s." % ("; attack interrupted" if interrupted else ""))

func _guard() -> void:
    if finished or combat_style != "melee":
        return
    if not GameState.has_combat_skill("melee", "guard_up"):
        _set_status("Guard Up is locked. Unlock it in Combat Training (K).")
        return
    if stamina < 8.0 or guard_timer > 0.0:
        return
    stamina -= 8.0
    guard_timer = 0.52
    _set_status("GUARD UP — hold your ground for the incoming strike.")
