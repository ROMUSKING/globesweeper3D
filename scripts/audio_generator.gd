extends Node

# Audio Generator for GlobeSweeper 3D
# This script generates basic sound effects programmatically

func _ready():
	generate_audio_files()

func generate_audio_files():
	# Create audio directory if it doesn't exist
	var audio_dir = "res://audio/"
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("audio"):
		dir.make_dir("audio")
	
	# Generate basic sound effects
	generate_tile_reveal_sound()
	generate_mine_explosion_sound()
	generate_game_win_sound()
	generate_game_lose_sound()
	generate_background_music()

func generate_tile_reveal_sound():
	# Create a simple "pop" sound for tile reveals
	var sample_rate = 44100
	var duration = 0.1
	var samples = int(sample_rate * duration)
	
	var data = PackedVector2Array()
	for i in range(samples):
		var t = float(i) / sample_rate
		var freq = 800 - (t * 400) # Descending frequency
		var sample = sin(t * freq * 2 * PI) * (1.0 - t / duration) * 0.3
		data.append(Vector2(sample, sample))
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = duration
	
	# Save as resource (this would need actual file saving in a real implementation)
	print("Tile reveal sound generated")

func generate_mine_explosion_sound():
	# Create a "boom" sound for mine explosions
	var sample_rate = 44100
	var duration = 0.5
	var samples = int(sample_rate * duration)
	
	var data = PackedVector2Array()
	for i in range(samples):
		var t = float(i) / sample_rate
		var noise = randf() * 2.0 - 1.0
		var envelope = sin(t * PI / duration) * exp(-t * 3.0)
		var sample = noise * envelope * 0.4
		data.append(Vector2(sample, sample))
	
	print("Mine explosion sound generated")

func generate_game_win_sound():
	# Create an ascending melody for game win
	var sample_rate = 44100
	var duration = 1.0
	var samples = int(sample_rate * duration)
	
	var data = PackedVector2Array()
	var notes = [523.25, 659.25, 783.99, 1046.50] # C, E, G, C
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var note_index = int(t * 4) % 4
		var freq = notes[note_index]
		var envelope = sin(t * PI / duration)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.2
		data.append(Vector2(sample, sample))
	
	print("Game win sound generated")

func generate_game_lose_sound():
	# Create a descending melody for game lose
	var sample_rate = 44100
	var duration = 1.0
	var samples = int(sample_rate * duration)
	
	var data = PackedVector2Array()
	var notes = [392.00, 329.63, 261.63, 196.00] # G, E, C, G
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var note_index = int(t * 4) % 4
		var freq = notes[note_index]
		var envelope = sin(t * PI / duration)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.15
		data.append(Vector2(sample, sample))
	
	print("Game lose sound generated")

func generate_background_music():
	# Create simple ambient background music
	var sample_rate = 44100
	var duration = 30.0 # 30 second loop
	var samples = int(sample_rate * duration)
	
	var data = PackedVector2Array()
	var base_freq = 220.0 # A3
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var freq1 = base_freq * (1.0 + sin(t * 0.1) * 0.1)
		var freq2 = base_freq * 1.5 * (1.0 + sin(t * 0.15) * 0.1)
		
		var sample1 = sin(t * freq1 * 2 * PI) * 0.1
		var sample2 = sin(t * freq2 * 2 * PI) * 0.05
		var sample = (sample1 + sample2) * 0.3
		data.append(Vector2(sample, sample))
	
	print("Background music generated")
