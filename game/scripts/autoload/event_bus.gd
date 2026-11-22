extends Node

signal world_time_advanced(day: int, hour: int, minute: int)
signal new_day_started(day: int)
signal encounter_started(encounter_id: String)
signal encounter_finished(encounter_id: String, outcome: String)
signal reputation_changed(faction_id: String, new_value: int)
signal inventory_changed(item_id: String, new_count: int)
signal npc_interacted(npc_id: String)
signal progression_changed(level: int, xp: int, skill_points: int)
signal world_event_completed(event_id: String, day: int)
