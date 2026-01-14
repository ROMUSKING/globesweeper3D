class_name SoundVFXEventManager
extends Node

# Event types enum
enum EventType {
	TILE_REVEAL,
	TILE_FLAG,
	MINE_EXPLOSION,
	GAME_WIN,
	GAME_LOSE,
	GAME_START,
	GAME_PAUSE,
	GAME_RESUME,
	DIFFICULTY_CHANGE,
	STREAK_UPDATE,
	CHORD_REVEAL,
	FIRST_CLICK,
	GLOBE_ROTATION,
	ZOOM_CHANGE
}

# Event priority enum
enum EventPriority {
	LOW = 0, # Background events, UI sounds
	MEDIUM = 1, # Standard gameplay events
	HIGH = 2, # Critical events (explosions, win/lose)
	IMMEDIATE = 3 # System-critical events
}

# Configuration parameters
@export var sound_enabled: bool = true
@export var vfx_enabled: bool = true
@export var master_volume: float = 1.0
@export var sfx_volume: float = 0.8
@export var vfx_intensity: float = 1.0

# References to other systems
var audio_manager: AudioManager
var vfx_system: VFXSystem
var game_state_machine: Node
var scoring_system: Dictionary
var interaction_manager: InteractionManager

# Event queue for processing
var event_queue: Array = []

# Signals
signal event_triggered(event_type: EventType, data: Dictionary)
signal vfx_played(vfx_type: String, position: Vector3)
signal sound_played(sound_type: String)

func initialize(systems: Dictionary):
	# Set up references to other systems
	audio_manager = systems.get("audio_manager", null)
	vfx_system = systems.get("vfx_system", null)
	game_state_machine = systems.get("game_state_machine", null)
	scoring_system = systems.get("scoring_system", {})
	interaction_manager = systems.get("interaction_manager", null)

func trigger_event(event_type: EventType, data: Dictionary = {}, priority: EventPriority = EventPriority.MEDIUM):
	# Add event to queue for processing
	event_queue.append({
		"type": event_type,
		"data": data,
		"priority": priority,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Sort queue by priority and timestamp
	event_queue.sort_custom(_sort_events_by_priority)

func process_events(delta: float):
	# Process events in queue with priority
	while event_queue.size() > 0:
		var event = event_queue.pop_front()
		var event_type = event["type"]
		var event_data = event["data"]
		
		# Process based on event type
		match event_type:
			EventType.TILE_REVEAL:
				_process_tile_reveal(event_data)
			EventType.TILE_FLAG:
				_process_tile_flag(event_data)
			EventType.MINE_EXPLOSION:
				_process_mine_explosion(event_data)
			EventType.GAME_WIN:
				_process_game_win(event_data)
			EventType.GAME_LOSE:
				_process_game_lose(event_data)
			EventType.GAME_START:
				_process_game_start(event_data)
			EventType.GAME_PAUSE:
				_process_game_pause(event_data)
			EventType.GAME_RESUME:
				_process_game_resume(event_data)
			EventType.DIFFICULTY_CHANGE:
				_process_difficulty_change(event_data)
			EventType.STREAK_UPDATE:
				_process_streak_update(event_data)
			EventType.CHORD_REVEAL:
				_process_chord_reveal(event_data)
			EventType.FIRST_CLICK:
				_process_first_click(event_data)
			EventType.GLOBE_ROTATION:
				_process_globe_rotation(event_data)
			EventType.ZOOM_CHANGE:
				_process_zoom_change(event_data)
		
		# Emit signal for processed event
		event_triggered.emit(event_type, event_data)

func _sort_events_by_priority(a: Dictionary, b: Dictionary) -> bool:
	# Sort by priority (higher first), then by timestamp (older first)
	if a["priority"] == b["priority"]:
		return a["timestamp"] < b["timestamp"]
	return a["priority"] > b["priority"]

func play_sound_effect(sound_type: String, volume: float = 1.0):
	# Play specific sound effect through audio manager
	if audio_manager and sound_enabled:
		audio_manager.play_sound(sound_type, volume * sfx_volume * master_volume)
		sound_played.emit(sound_type)

func play_visual_effect(vfx_type: String, position: Vector3 = Vector3.ZERO, scale: float = 1.0):
	# Play specific visual effect through VFX system
	if vfx_system and vfx_enabled:
		vfx_system.play_vfx(vfx_type, position, scale * vfx_intensity)
		vfx_played.emit(vfx_type, position)

func _process_tile_reveal(data: Dictionary):
	# Handle tile reveal event
	var position = data.get("position", Vector3.ZERO)
	var has_mine = data.get("has_mine", false)
	var neighbor_mines = data.get("neighbor_mines", 0)
	
	if has_mine:
		play_sound_effect("mine_reveal")
		play_visual_effect("tile_reveal_mine", position)
	else:
		play_sound_effect("tile_reveal")
		play_visual_effect("tile_reveal", position)
		
		# Different sound for numbered tiles
		if neighbor_mines > 0:
			play_sound_effect("tile_reveal_numbered")

func _process_tile_flag(data: Dictionary):
	# Handle tile flag event
	var position = data.get("position", Vector3.ZERO)
	var is_flagged = data.get("is_flagged", false)
	
	if is_flagged:
		play_sound_effect("flag_placed")
		play_visual_effect("flag_placed", position)
	else:
		play_sound_effect("flag_removed")
		play_visual_effect("flag_removed", position)

func _process_mine_explosion(data: Dictionary):
	# Handle mine explosion event
	var position = data.get("position", Vector3.ZERO)
	
	play_sound_effect("mine_explosion", 1.5)
	play_visual_effect("mine_explosion", position, 1.5)

func _process_game_win(data: Dictionary):
	# Handle game win event
	var current_streak = data.get("current_streak", 1)
	var current_difficulty = data.get("current_difficulty", 1.0)
	
	# Play enhanced effects for high streaks or difficulty
	if current_streak >= 5:
		play_visual_effect("mega_fireworks", Vector3.ZERO, 2.0)
		play_sound_effect("win_epic", 1.2)
	elif current_difficulty >= 3.0:
		play_visual_effect("advanced_fireworks", Vector3.ZERO, 1.5)
		play_sound_effect("win_hard", 1.1)
	else:
		play_visual_effect("standard_fireworks")
		play_sound_effect("win_standard")

func _process_game_lose(data: Dictionary):
	# Handle game lose event
	play_sound_effect("game_lose")
	play_visual_effect("game_lose_effect", Vector3.ZERO)

func _process_game_start(data: Dictionary):
	# Handle game start event
	play_sound_effect("game_start")

func _process_game_pause(data: Dictionary):
	# Handle game pause event
	play_sound_effect("game_pause")

func _process_game_resume(data: Dictionary):
	# Handle game resume event
	play_sound_effect("game_resume")

func _process_difficulty_change(data: Dictionary):
	# Handle difficulty change event
	var new_difficulty = data.get("new_difficulty", 1.0)
	var old_difficulty = data.get("old_difficulty", 1.0)
	
	if new_difficulty > old_difficulty:
		play_sound_effect("difficulty_increase")
		play_visual_effect("difficulty_increase", Vector3.ZERO)
	else:
		play_sound_effect("difficulty_decrease")
		play_visual_effect("difficulty_decrease", Vector3.ZERO)

func _process_streak_update(data: Dictionary):
	# Handle streak update event
	var new_streak = data.get("new_streak", 0)
	var best_streak = data.get("best_streak", 0)
	
	play_sound_effect("streak_update")
	
	# Enhanced effects for milestone streaks
	if new_streak % 5 == 0:
		play_visual_effect("streak_milestone", Vector3.ZERO, 1.5)
		play_sound_effect("streak_milestone", 1.2)

func _process_chord_reveal(data: Dictionary):
	# Handle chord reveal event
	var position = data.get("position", Vector3.ZERO)
	var tile_count = data.get("tile_count", 1)
	
	play_sound_effect("chord_reveal")
	play_visual_effect("chord_reveal", position)
	
	# Scale effect based on number of tiles revealed
	if tile_count > 3:
		play_visual_effect("chord_reveal_large", position, 1.5)

func _process_first_click(data: Dictionary):
	# Handle first click event
	var position = data.get("position", Vector3.ZERO)
	
	play_sound_effect("first_click")
	play_visual_effect("first_click", position)

func _process_globe_rotation(data: Dictionary):
	# Handle globe rotation event
	var rotation_speed = data.get("rotation_speed", 0.0)
	
	# Play sound based on rotation speed
	if rotation_speed > 0.5:
		play_sound_effect("globe_rotate_fast")
	elif rotation_speed > 0.1:
		play_sound_effect("globe_rotate_slow")

func _process_zoom_change(data: Dictionary):
	# Handle zoom change event
	var zoom_level = data.get("zoom_level", 1.0)
	
	if zoom_level > 1.0:
		play_sound_effect("zoom_in")
	else:
		play_sound_effect("zoom_out")

func update_settings(new_settings: Dictionary):
	# Update sound/VFX settings
	if new_settings.has("sound_enabled"):
		sound_enabled = new_settings["sound_enabled"]
	if new_settings.has("vfx_enabled"):
		vfx_enabled = new_settings["vfx_enabled"]
	if new_settings.has("master_volume"):
		master_volume = new_settings["master_volume"]
	if new_settings.has("sfx_volume"):
		sfx_volume = new_settings["sfx_volume"]
	if new_settings.has("vfx_intensity"):
		vfx_intensity = new_settings["vfx_intensity"]
