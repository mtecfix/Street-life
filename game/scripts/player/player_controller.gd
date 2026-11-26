extends CharacterBody2D

func get_current_move_speed() -> float:
    # Keep exploration movement in sync with skill progression and combat stats.
    return GameState.get_player_speed()

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * get_current_move_speed()
    move_and_slide()
