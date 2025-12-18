extends Node

# Audio players
var background_player: AudioStreamPlayer
var reveal_player: AudioStreamPlayer
var explosion_player: AudioStreamPlayer
var win_player: AudioStreamPlayer
var lose_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

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