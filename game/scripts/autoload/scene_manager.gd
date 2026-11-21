extends Node

var _transitioning: bool = false

func change_to(scene_path: String) -> void:
    if _transitioning:
        return
    _transitioning = true
    # Callers often run inside _ready() or an input handler, while the tree is
    # still adding or removing children. Swapping the scene synchronously there
    # makes the engine call remove_child() on a busy parent and log an error, so
    # the swap is deferred until the current frame's tree changes are finished.
    _swap_scene.call_deferred(scene_path)

func _swap_scene(scene_path: String) -> void:
    var error := get_tree().change_scene_to_file(scene_path)
    if error != OK:
        push_error("Unable to change scene: %s (error %s)" % [scene_path, error])
    # change_scene_to_file() finishes the swap on the next frame. Keep the guard
    # set until then so a second change_to() call cannot start a competing swap.
    await get_tree().process_frame
    _transitioning = false
