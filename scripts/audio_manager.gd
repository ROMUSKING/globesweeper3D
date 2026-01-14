class_name AudioManager
extends Node

# Audio players
var background_player: AudioStreamPlayer
var reveal_player: AudioStreamPlayer
var explosion_player: AudioStreamPlayer
var win_player: AudioStreamPlayer
var lose_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var chord_player: AudioStreamPlayer

# Additional sound players for new event types
var flag_player: AudioStreamPlayer
var game_start_player: AudioStreamPlayer
var game_pause_player: AudioStreamPlayer
var game_resume_player: AudioStreamPlayer
var difficulty_change_player: AudioStreamPlayer
var streak_player: AudioStreamPlayer
var globe_rotate_player: AudioStreamPlayer
var zoom_player: AudioStreamPlayer

# Constants
const SAMPLE_RATE = 22050

func _ready():
	_setup_audio_nodes()
	_setup_streams()

func _setup_audio_nodes():
	background_player = _create_player("BackgroundMusic")
	reveal_player = _create_player("RevealSound")
	explosion_player = _create_player("ExplosionSound")
	win_player = _create_player("WinSound")
	lose_player = _create_player("LoseSound")
	click_player = _create_player("ClickSound")
	chord_player = _create_player("ChordSound")
	flag_player = _create_player("FlagSound")
	game_start_player = _create_player("GameStartSound")
	game_pause_player = _create_player("GamePauseSound")
	game_resume_player = _create_player("GameResumeSound")
	difficulty_change_player = _create_player("DifficultyChangeSound")
	streak_player = _create_player("StreakSound")
	globe_rotate_player = _create_player("GlobeRotateSound")
	zoom_player = _create_player("ZoomSound")

func _create_player(node_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = node_name
	add_child(player)
	return player

func _setup_streams():
	# Tile reveal
	var reveal_stream = AudioStreamGenerator.new()
	reveal_stream.mix_rate = SAMPLE_RATE
	reveal_stream.buffer_length = 0.1
	reveal_player.stream = reveal_stream

	# Mine explosion
	var explosion_stream = AudioStreamGenerator.new()
	explosion_stream.mix_rate = SAMPLE_RATE
	explosion_stream.buffer_length = 0.3
	explosion_player.stream = explosion_stream

	# Game win
	var win_stream = AudioStreamGenerator.new()
	win_stream.mix_rate = SAMPLE_RATE
	win_stream.buffer_length = 0.8
	win_player.stream = win_stream

	# Game lose
	var lose_stream = AudioStreamGenerator.new()
	lose_stream.mix_rate = SAMPLE_RATE
	lose_stream.buffer_length = 0.8
	lose_player.stream = lose_stream

	# Click sound
	var click_stream = AudioStreamGenerator.new()
	click_stream.mix_rate = SAMPLE_RATE
	click_stream.buffer_length = 0.05
	click_player.stream = click_stream
	
	# Chord sound
	var chord_stream = AudioStreamGenerator.new()
	chord_stream.mix_rate = SAMPLE_RATE
	chord_stream.buffer_length = 0.2
	chord_player.stream = chord_stream

	# Flag sound
	var flag_stream = AudioStreamGenerator.new()
	flag_stream.mix_rate = SAMPLE_RATE
	flag_stream.buffer_length = 0.1
	flag_player.stream = flag_stream

	# Game start sound
	var game_start_stream = AudioStreamGenerator.new()
	game_start_stream.mix_rate = SAMPLE_RATE
	game_start_stream.buffer_length = 0.5
	game_start_player.stream = game_start_stream

	# Game pause sound
	var game_pause_stream = AudioStreamGenerator.new()
	game_pause_stream.mix_rate = SAMPLE_RATE
	game_pause_stream.buffer_length = 0.2
	game_pause_player.stream = game_pause_stream

	# Game resume sound
	var game_resume_stream = AudioStreamGenerator.new()
	game_resume_stream.mix_rate = SAMPLE_RATE
	game_resume_stream.buffer_length = 0.2
	game_resume_player.stream = game_resume_stream

	# Difficulty change sound
	var difficulty_stream = AudioStreamGenerator.new()
	difficulty_stream.mix_rate = SAMPLE_RATE
	difficulty_stream.buffer_length = 0.3
	difficulty_change_player.stream = difficulty_stream

	# Streak sound
	var streak_stream = AudioStreamGenerator.new()
	streak_stream.mix_rate = SAMPLE_RATE
	streak_stream.buffer_length = 0.2
	streak_player.stream = streak_stream

	# Globe rotate sound
	var globe_rotate_stream = AudioStreamGenerator.new()
	globe_rotate_stream.mix_rate = SAMPLE_RATE
	globe_rotate_stream.buffer_length = 0.1
	globe_rotate_player.stream = globe_rotate_stream

	# Zoom sound
	var zoom_stream = AudioStreamGenerator.new()
	zoom_stream.mix_rate = SAMPLE_RATE
	zoom_stream.buffer_length = 0.15
	zoom_player.stream = zoom_stream

	# Background music (Placeholder based on original code)
	var bg_stream = AudioStreamGenerator.new()
	bg_stream.mix_rate = SAMPLE_RATE
	bg_stream.buffer_length = 10.0
	background_player.stream = bg_stream

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