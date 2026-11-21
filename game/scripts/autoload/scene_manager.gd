extends Node

var _transitioning: bool = false

func change_to(scene_path: String) -> void:
    if _transitioning:
        return
    _transitioning = true
    var error := get_tree().change_scene_to_file(scene_path)
    if error != OK:
        push_error("Unable to change scene: %s (error %s)" % [scene_path, error])
    _transitioning = false
