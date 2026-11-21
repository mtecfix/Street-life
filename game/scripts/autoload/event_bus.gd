extends Node

signal world_time_advanced(day: int, hour: int, minute: int)
signal encounter_started(encounter_id: String)
signal encounter_finished(encounter_id: String, outcome: String)
signal reputation_changed(faction_id: String, new_value: int)
