class_name AudioManager
extends Node

# Audio player configuration: [node_name, buffer_length]
const AUDIO_PLAYERS = {
	"background_player": ["BackgroundMusic", 10.0],
	"reveal_player": ["RevealSound", 0.1],
	"explosion_player": ["ExplosionSound", 0.3],
	"win_player": ["WinSound", 0.8],
	"lose_player": ["LoseSound", 0.8],
	"click_player": ["ClickSound", 0.05],
	"chord_player": ["ChordSound", 0.2],
	"flag_player": ["FlagSound", 0.1],
	"game_start_player": ["GameStartSound", 0.5],
	"game_pause_player": ["GamePauseSound", 0.2],
	"game_resume_player": ["GameResumeSound", 0.2],
	"difficulty_change_player": ["DifficultyChangeSound", 0.3],
	"streak_player": ["StreakSound", 0.2],
	"globe_rotate_player": ["GlobeRotateSound", 0.1],
	"zoom_player": ["ZoomSound", 0.15],
}

# Audio players (dynamically created)
var _players: Dictionary = {}

# Constants
const SAMPLE_RATE = 22050

func _ready():
	_setup_audio_nodes()

func _setup_audio_nodes():
	"""Create all audio players dynamically from configuration"""
	for var_name in AUDIO_PLAYERS.keys():
		var config = AUDIO_PLAYERS[var_name]
		var node_name = config[0]
		var buffer_length = config[1]
		
		# Create player
		var player = AudioStreamPlayer.new()
		player.name = node_name
		add_child(player)
		
		# Setup stream
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = SAMPLE_RATE
		stream.buffer_length = buffer_length
		player.stream = stream
		
		# Store reference
		_players[var_name] = player

# Dynamic accessor for players (backward compatibility)
func _get(property: StringName) -> Variant:
	if _players.has(property):
		return _players[property]
	return null

# Backward compatibility properties
var background_player: AudioStreamPlayer:
	get: return _players.get("background_player", null)
var reveal_player: AudioStreamPlayer:
	get: return _players.get("reveal_player", null)
var explosion_player: AudioStreamPlayer:
	get: return _players.get("explosion_player", null)
var win_player: AudioStreamPlayer:
	get: return _players.get("win_player", null)
var lose_player: AudioStreamPlayer:
	get: return _players.get("lose_player", null)
var click_player: AudioStreamPlayer:
	get: return _players.get("click_player", null)
var chord_player: AudioStreamPlayer:
	get: return _players.get("chord_player", null)
var flag_player: AudioStreamPlayer:
	get: return _players.get("flag_player", null)
var game_start_player: AudioStreamPlayer:
	get: return _players.get("game_start_player", null)
var game_pause_player: AudioStreamPlayer:
	get: return _players.get("game_pause_player", null)
var game_resume_player: AudioStreamPlayer:
	get: return _players.get("game_resume_player", null)
var difficulty_change_player: AudioStreamPlayer:
	get: return _players.get("difficulty_change_player", null)
var streak_player: AudioStreamPlayer:
	get: return _players.get("streak_player", null)
var globe_rotate_player: AudioStreamPlayer:
	get: return _players.get("globe_rotate_player", null)
var zoom_player: AudioStreamPlayer:
	get: return _players.get("zoom_player", null)

func play_reveal_sound():
	if not reveal_player.stream:
		return
	
	reveal_player.play()
	var playback = reveal_player.get_stream_playback()
	var duration = 0.1
	var samples = int(SAMPLE_RATE * duration)
	
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1000 - (t * 500) # Descending frequency
		var sample = sin(t * freq * 2 * PI) * (1.0 - t / duration) * 0.3
		playback.push_frame(Vector2(sample, sample))

func play_explosion_sound():
	if not explosion_player.stream:
		return
	
	explosion_player.play()
	var playback = explosion_player.get_stream_playback()
	var duration = 0.3
	var samples = int(SAMPLE_RATE * duration)
	
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var noise = randf() * 2.0 - 1.0
		var envelope = sin(t * PI / duration) * exp(-t * 2.0)
		var sample = noise * envelope * 0.4
		playback.push_frame(Vector2(sample, sample))

func play_win_sound():
	if not win_player.stream:
		return
	
	win_player.play()
	var playback = win_player.get_stream_playback()
	var duration = 0.8
	var samples = int(SAMPLE_RATE * duration)
	
	var notes = [523.25, 659.25, 783.99, 1046.50] # C, E, G, C
	
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var note_index = int(t * 4) % 4
		var freq = notes[note_index]
		var envelope = sin(t * PI / duration)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_lose_sound():
	if not lose_player.stream:
		return
	
	lose_player.play()
	var playback = lose_player.get_stream_playback()
	var duration = 0.8
	var samples = int(SAMPLE_RATE * duration)
	
	var notes = [392.00, 329.63, 261.63, 196.00] # G, E, C, G
	
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var note_index = int(t * 4) % 4
		var freq = notes[note_index]
		var envelope = sin(t * PI / duration)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.15
		playback.push_frame(Vector2(sample, sample))

func play_click_sound():
	if not click_player.stream:
		return

	click_player.play()
	var playback = click_player.get_stream_playback()
	var duration = 0.05
	var samples = int(SAMPLE_RATE * duration)

	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 2000.0 # High pitch click
		var envelope = exp(-t * 100.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.1
		playback.push_frame(Vector2(sample, sample))

func play_chord_sound():
	if not chord_player.stream:
		return

	chord_player.play()
	var playback = chord_player.get_stream_playback()
	var duration = 0.2
	var samples = int(SAMPLE_RATE * duration)

	# Create a pleasant chord sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq1 = 800.0 # Base frequency
		var freq2 = 1200.0 # Higher harmonic
		var envelope = sin(t * PI / duration) * exp(-t * 5.0)
		var sample = (sin(t * freq1 * 2 * PI) + sin(t * freq2 * 2 * PI) * 0.7) * envelope * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_powerup_sound():
	if not chord_player.stream:
		return

	chord_player.play()
	var playback = chord_player.get_stream_playback()
	var duration = 0.3
	var samples = int(SAMPLE_RATE * duration)

	# Create a magical powerup sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1200.0 + sin(t * 10.0) * 200.0 # Wobbling frequency
		var envelope = sin(t * PI / duration) * exp(-t * 3.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.3
		playback.push_frame(Vector2(sample, sample))

# New sound functions for additional event types
func play_flag_sound():
	if not flag_player.stream:
		return

	flag_player.play()
	var playback = flag_player.get_stream_playback()
	var duration = 0.1
	var samples = int(SAMPLE_RATE * duration)

	# Create a flag placement sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1500.0 - (t * 1000.0) # Descending frequency
		var envelope = sin(t * PI / duration) * exp(-t * 10.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_game_start_sound():
	if not game_start_player.stream:
		return

	game_start_player.play()
	var playback = game_start_player.get_stream_playback()
	var duration = 0.5
	var samples = int(SAMPLE_RATE * duration)

	# Create a game start sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 800.0 + (t * 400.0) # Rising frequency
		var envelope = sin(t * PI / duration) * exp(-t * 3.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.25
		playback.push_frame(Vector2(sample, sample))

func play_game_pause_sound():
	if not game_pause_player.stream:
		return

	game_pause_player.play()
	var playback = game_pause_player.get_stream_playback()
	var duration = 0.2
	var samples = int(SAMPLE_RATE * duration)

	# Create a pause sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1000.0
		var envelope = sin(t * PI / duration) * exp(-t * 5.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.15
		playback.push_frame(Vector2(sample, sample))

func play_game_resume_sound():
	if not game_resume_player.stream:
		return

	game_resume_player.play()
	var playback = game_resume_player.get_stream_playback()
	var duration = 0.2
	var samples = int(SAMPLE_RATE * duration)

	# Create a resume sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1200.0
		var envelope = sin(t * PI / duration) * exp(-t * 5.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.15
		playback.push_frame(Vector2(sample, sample))

func play_difficulty_change_sound(is_increase: bool):
	if not difficulty_change_player.stream:
		return

	difficulty_change_player.play()
	var playback = difficulty_change_player.get_stream_playback()
	var duration = 0.3
	var samples = int(SAMPLE_RATE * duration)

	# Create a difficulty change sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 600.0 if is_increase else 400.0
		var freq_change = 400.0 if is_increase else -200.0
		var current_freq = freq + (t * freq_change)
		var envelope = sin(t * PI / duration) * exp(-t * 4.0)
		var sample = sin(t * current_freq * 2 * PI) * envelope * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_streak_sound():
	if not streak_player.stream:
		return

	streak_player.play()
	var playback = streak_player.get_stream_playback()
	var duration = 0.2
	var samples = int(SAMPLE_RATE * duration)

	# Create a streak sound
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1800.0 - (t * 800.0) # Descending frequency
		var envelope = sin(t * PI / duration) * exp(-t * 6.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_globe_rotate_sound(is_fast: bool):
	if not globe_rotate_player.stream:
		return

	globe_rotate_player.play()
	var playback = globe_rotate_player.get_stream_playback()
	var duration = 0.1
	var samples = int(SAMPLE_RATE * duration)

	# Create a globe rotation sound
	var freq = 1000.0 if is_fast else 600.0
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var envelope = sin(t * PI / duration) * exp(-t * 8.0)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.1
		playback.push_frame(Vector2(sample, sample))

func play_zoom_sound(is_zoom_in: bool):
	if not zoom_player.stream:
		return

	zoom_player.play()
	var playback = zoom_player.get_stream_playback()
	var duration = 0.15
	var samples = int(SAMPLE_RATE * duration)

	# Create a zoom sound
	var freq_start = 800.0 if is_zoom_in else 1200.0
	var freq_end = 1200.0 if is_zoom_in else 800.0
	for i in range(samples):
		var t = float(i) / SAMPLE_RATE
		var current_freq = freq_start + (t * (freq_end - freq_start))
		var envelope = sin(t * PI / duration) * exp(-t * 5.0)
		var sample = sin(t * current_freq * 2 * PI) * envelope * 0.15
		playback.push_frame(Vector2(sample, sample))

# Generic play_sound function for SoundVFXEventManager
func play_sound(sound_type: String, volume: float = 1.0):
	match sound_type:
		"tile_reveal":
			play_reveal_sound()
		"mine_explosion":
			play_explosion_sound()
		"game_win":
			play_win_sound()
		"game_lose":
			play_lose_sound()
		"click":
			play_click_sound()
		"chord_reveal":
			play_chord_sound()
		"powerup":
			play_powerup_sound()
		"flag_placed":
			play_flag_sound()
		"flag_removed":
			play_flag_sound()
		"game_start":
			play_game_start_sound()
		"game_pause":
			play_game_pause_sound()
		"game_resume":
			play_game_resume_sound()
		"difficulty_increase":
			play_difficulty_change_sound(true)
		"difficulty_decrease":
			play_difficulty_change_sound(false)
		"streak_update":
			play_streak_sound()
		"streak_milestone":
			play_streak_sound()
		"globe_rotate_fast":
			play_globe_rotate_sound(true)
		"globe_rotate_slow":
			play_globe_rotate_sound(false)
		"zoom_in":
			play_zoom_sound(true)
		"zoom_out":
			play_zoom_sound(false)
		"win_epic":
			play_win_sound()
		"win_hard":
			play_win_sound()
		"win_standard":
			play_win_sound()
		"game_lose":
			play_lose_sound()
		"first_click":
			play_click_sound()
