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
# Each encounter gets a readable AI archetype rather than identical chase-and-swing logic.
var enemy_style := "pressure"
var enemy_decision_timer := 0.0
var enemy_orbit_direction := 1.0
var enemy_attack_cooldown_timer := 0.0
var enemy_attack_sequence := 0
var enemy_attack_kind := "quick"
var enemy_feint_active := false
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
var enemy_hitstun_timer := 0.0
var enemy_knockback_velocity := Vector2.ZERO
var player_knockback_velocity := Vector2.ZERO
var hit_flash_timer := 0.0
var player_hit_flash_timer := 0.0
var player_swing_timer := 0.0
var player_swing_duration := 0.18
var enemy_swing_timer := 0.0
var enemy_swing_duration := 0.24
var enemy_recoil_timer := 0.0
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
            enemy_style = "guard"
            enemy_attack_cooldown_timer = 0.35
        "alley_ambush":
            enemy_name = "Alley runner"
            enemy_health = 125.0
            enemy_speed = 138.0
            enemy_attack_range = 82.0
            enemy_damage = 22.0
            enemy_windup = 0.58
            enemy_color = Color("#9e6bb0")
            encounter_reward = 35
            enemy_style = "runner"
            enemy_attack_cooldown_timer = 0.1
        _:
            enemy_name = "Corner challenger"
            enemy_health = 100.0
            enemy_speed = 92.0
            enemy_attack_range = 76.0
            enemy_damage = 18.0
            enemy_windup = 0.78
            enemy_color = Color("#d66a55")
            encounter_reward = 50
            enemy_style = "pressure"
            enemy_attack_cooldown_timer = 0.65

func _process(delta: float) -> void:
    if finished:
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    combo_window_timer = maxf(0.0, combo_window_timer - delta)
    if combo_window_timer <= 0.0:
        combo_step = 0
    enemy_recovery = maxf(0.0, enemy_recovery - delta)
    enemy_attack_cooldown_timer = maxf(0.0, enemy_attack_cooldown_timer - delta)
    enemy_decision_timer -= delta
    if enemy_decision_timer <= 0.0:
        enemy_orbit_direction *= -1.0
        enemy_decision_timer = 1.4
    enemy_hitstun_timer = maxf(0.0, enemy_hitstun_timer - delta)
    hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
    player_hit_flash_timer = maxf(0.0, player_hit_flash_timer - delta)
    player_swing_timer = maxf(0.0, player_swing_timer - delta)
    enemy_swing_timer = maxf(0.0, enemy_swing_timer - delta)
    enemy_recoil_timer = maxf(0.0, enemy_recoil_timer - delta)
    invulnerability_timer = maxf(0.0, invulnerability_timer - delta)
    stamina = minf(stamina_max, stamina + GameState.get_stamina_regen() * delta)

    if dodge_timer > 0.0:
        dodge_timer = maxf(0.0, dodge_timer - delta)
        player.position += dodge_direction * 510.0 * delta
    else:
        var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        player.position += direction * GameState.get_player_speed() * delta
    player.position += player_knockback_velocity * delta
    player_knockback_velocity = player_knockback_velocity.move_toward(Vector2.ZERO, 720.0 * delta)

    var horizontal_margin := 210.0 if environment_kind == "alley" else 38.0
    player.position.x = clampf(player.position.x, horizontal_margin, ARENA_SIZE.x - horizontal_margin)
    player.position.y = clampf(player.position.y, 205.0, 445.0)

    var distance := enemy.position.distance_to(player.position)
    enemy.position += enemy_knockback_velocity * delta
    enemy_knockback_velocity = enemy_knockback_velocity.move_toward(Vector2.ZERO, 620.0 * delta)
    if enemy_hitstun_timer <= 0.0:
        _update_enemy_positioning(delta, distance)

    if telegraph_timer >= 0.0:
        telegraph_timer -= delta
        telegraph.position = enemy.position
        telegraph.visible = true
        if telegraph_timer <= 0.0:
            if enemy_feint_active:
                _resolve_enemy_feint()
            else:
                _resolve_enemy_attack()
    elif enemy_recovery <= 0.0 and enemy_attack_cooldown_timer <= 0.0 and distance <= enemy_attack_range:
        telegraph_timer = enemy_windup
        telegraph.position = enemy.position
        _start_enemy_telegraph()
    else:
        telegraph.visible = false

    _update_combat_animation()
    _refresh()

func _update_combat_animation() -> void:
    # Lightweight procedural poses keep combat readable before final sprite
    # sheets arrive. Timers are gameplay-driven, not decorative random motion.
    if player_swing_timer > 0.0:
        var swing_progress := 1.0 - player_swing_timer / player_swing_duration
        player.rotation = lerpf(-0.34, 0.48, swing_progress)
        player.scale = Vector2(1.12, 0.88) if swing_progress < 0.5 else Vector2(0.92, 1.12)
    elif player_hit_flash_timer > 0.0:
        player.rotation = 0.22 * sin(player_hit_flash_timer * 42.0)
        player.scale = Vector2(0.88, 1.14)
    elif dodge_timer > 0.0:
        player.rotation = dodge_direction.x * 0.28
        player.scale = Vector2(0.82, 1.12)
    else:
        player.rotation = 0.0
        player.scale = Vector2.ONE

    if enemy_swing_timer > 0.0:
        var attack_progress := 1.0 - enemy_swing_timer / enemy_swing_duration
        enemy.rotation = lerpf(-0.24, 0.42, attack_progress)
        enemy.scale = Vector2(1.16, 0.86) if attack_progress < 0.55 else Vector2(0.9, 1.14)
    elif enemy_recoil_timer > 0.0:
        enemy.rotation = -0.3 * signf(enemy_knockback_velocity.x if enemy_knockback_velocity.x != 0.0 else 1.0)
        enemy.scale = Vector2(0.86, 1.16)
    elif telegraph_timer >= 0.0:
        var windup_ratio := clampf(telegraph_timer / maxf(enemy_windup, 0.01), 0.0, 1.0)
        enemy.rotation = -0.12 * (1.0 - windup_ratio)
        enemy.scale = Vector2(1.0 + (0.12 if enemy_attack_kind == "heavy" else 0.05) * (1.0 - windup_ratio), 1.0)
    else:
        enemy.rotation = 0.0
        enemy.scale = Vector2.ONE

    var invulnerable_alpha := 0.45 if invulnerability_timer > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
    player.modulate = Color(1.0, 0.45, 0.4, invulnerable_alpha) if player_hit_flash_timer > 0.0 else Color(1.0, 1.0, 1.0, invulnerable_alpha)
    enemy.modulate = Color("#fff0c2") if hit_flash_timer > 0.0 else enemy_color
    if telegraph.visible:
        var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.018)
        telegraph.scale = Vector2.ONE * pulse

func _update_enemy_positioning(delta: float, distance: float) -> void:
    # Pressure fighters close distance relentlessly. Guards try to hold a
    # preferred range and circle. Runners retreat when crowded, then re-enter.
    var to_player := (player.position - enemy.position).normalized()
    var perpendicular := Vector2(-to_player.y, to_player.x) * enemy_orbit_direction
    var movement := Vector2.ZERO
    match enemy_style:
        "guard":
            if distance > enemy_attack_range * 0.88:
                movement = to_player * 0.72 + perpendicular * 0.28
            elif distance < enemy_attack_range * 0.62:
                movement = -to_player * 0.48 + perpendicular * 0.52
            else:
                movement = perpendicular * 0.42
        "runner":
            if distance < 118.0:
                movement = -to_player * 0.82 + perpendicular * 0.18
            elif distance > enemy_attack_range * 1.45:
                movement = to_player
            else:
                movement = perpendicular * 0.62
        _:
            movement = to_player
    if movement != Vector2.ZERO:
        enemy.position += movement.normalized() * enemy_speed * delta

func _start_enemy_telegraph() -> void:
    enemy_attack_sequence += 1
    enemy_feint_active = enemy_style == "runner" and enemy_attack_sequence % 3 == 0
    var heavy_interval := 3 if enemy_style == "guard" else 4
    enemy_attack_kind = "heavy" if not enemy_feint_active and enemy_attack_sequence % heavy_interval == 0 else "quick"
    var windup_scale := 1.35 if enemy_attack_kind == "heavy" else 1.0
    if enemy_feint_active:
        windup_scale = 0.62
    telegraph_timer = enemy_windup * windup_scale
    telegraph.position = enemy.position
    telegraph.color = Color(1.0, 0.55, 0.12, 0.32) if enemy_attack_kind == "heavy" else Color(0.95, 0.22, 0.18, 0.25)
    telegraph.visible = true
    if enemy_feint_active:
        _set_status("%s shows a rush — don't dodge too early!" % enemy_name)
    elif enemy_attack_kind == "heavy":
        _set_status("%s loads a HEAVY strike — create distance!" % enemy_name)
    else:
        _set_status(_enemy_telegraph_message())

func _resolve_enemy_feint() -> void:
    # The runner sells an attack, then pulls out. The tell is intentionally
    # shorter than a real attack and deals no damage; punish the recovery.
    telegraph_timer = -1.0
    enemy_feint_active = false
    telegraph.visible = false
    enemy_attack_cooldown_timer = 0.45
    enemy_recovery = 0.42
    enemy.position += (enemy.position - player.position).normalized() * 34.0
    _set_status("%s pulled the feint. Stay ready and close the gap!" % enemy_name)

func _enemy_telegraph_message() -> String:
    match enemy_style:
        "guard":
            return "%s sets their feet — watch the counter!" % enemy_name
        "runner":
            return "%s darts in — DODGE THE RUSH!" % enemy_name
        _:
            return "%s winds up — DODGE NOW!" % enemy_name

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
    player_swing_timer = player_swing_duration
    _apply_enemy_hit(damage, 135.0, 0.16)
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
    player_swing_duration = 0.28
    player_swing_timer = player_swing_duration
    _apply_enemy_hit(damage, 220.0, 0.26)

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

func _apply_enemy_hit(damage: int, knockback_strength: float, stun_duration: float) -> void:
    # Hit reaction is separated from damage math so light/heavy attacks and
    # future enemy types share one consistent impact response.
    enemy_health = maxf(0.0, enemy_health - damage)
    var away_direction := (enemy.position - player.position).normalized()
    if away_direction == Vector2.ZERO:
        away_direction = Vector2.RIGHT
    enemy_knockback_velocity = away_direction * knockback_strength
    enemy_hitstun_timer = maxf(enemy_hitstun_timer, stun_duration)
    enemy_recoil_timer = maxf(enemy_recoil_timer, stun_duration + 0.08)
    enemy_swing_timer = 0.0
    hit_flash_timer = 0.12

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
    enemy_feint_active = false
    enemy_attack_cooldown_timer = 1.0 if enemy_style == "runner" else 1.35
    enemy_recovery = 0.85 if enemy_style == "pressure" else 1.1
    var to_player := (player.position - enemy.position).normalized()
    if enemy_style == "runner":
        # The alley runner commits to a short rush at the end of its warning.
        enemy.position += to_player * 42.0
    var is_heavy := enemy_attack_kind == "heavy"
    var effective_range := enemy_attack_range + (38.0 if enemy_style == "runner" else 20.0) + (18.0 if is_heavy else 0.0)
    var attack_damage := enemy_damage * (1.55 if is_heavy else 1.0)
    var knockback := 225.0 if is_heavy else (190.0 if enemy_style == "runner" else 155.0)
    enemy_swing_duration = 0.34 if is_heavy else 0.24
    enemy_swing_timer = enemy_swing_duration
    if player.position.distance_to(enemy.position) <= effective_range and invulnerability_timer <= 0.0:
        player_hit_flash_timer = 0.16
        player_health = maxf(0.0, player_health - attack_damage)
        player_knockback_velocity = (player.position - enemy.position).normalized() * knockback
        GameState.player_health = int(player_health)
        _set_status("HEAVY STRIKE LANDED — %d damage!" % roundi(attack_damage) if is_heavy else "You took a hit. Use SHIFT to dodge the next warning.")
        if player_health <= 0.0:
            _lose_encounter()
    else:
        _set_status("Opponent missed. Counter while there is an opening.")
    enemy_attack_kind = "quick"

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
                {"name": "Trash bags", "position": Vector2(360, 350), "health": 1, "kind": "trash"},
                {"name": "Loose pallet", "position": Vector2(620, 350), "health": 2, "kind": "pallet"}
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
