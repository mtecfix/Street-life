extends RefCounted
class_name CloudSaveProvider

## Future cloud adapter contract. Networking/authentication are intentionally deferred.
func upload_save(_payload: Dictionary) -> Error:
    return ERR_UNAVAILABLE

func download_save() -> Dictionary:
    return {}
