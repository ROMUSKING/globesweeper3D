class_name VFXSystem
extends Node3D

# VFX types and configurations
var vfx_configs = {
	"tile_reveal": {
		"particle_count": 20,
		"lifetime": 0.5,
		"color": Color(0.8, 0.9, 1.0),
		"scale": 0.3
	},
	"tile_reveal_mine": {
		"particle_count": 30,
		"lifetime": 0.8,
		"color": Color(1.0, 0.3, 0.1),
		"scale": 0.5
	},
	"flag_placed": {
		"particle_count": 15,
		"lifetime": 0.3,
		"color": Color(1.0, 0.8, 0.2),
		"scale": 0.2
	},
	"flag_removed": {
		"particle_count": 10,
		"lifetime": 0.2,
		"color": Color(0.5, 0.8, 1.0),
		"scale": 0.15
	},
	"mine_explosion": {
		"particle_count": 100,
		"lifetime": 1.0,
		"color": Color(1.0, 0.3, 0.1),
		"scale": 1.5
	},
	"standard_fireworks": {
		"particle_count": 200,
		"lifetime": 1.8,
		"color": Color(1.0, 1.0, 1.0),
		"scale": 1.0
	},
	"advanced_fireworks": {
		"particle_count": 400,
		"lifetime": 2.5,
		"color": Color(1.0, 0.8, 0.2),
		"scale": 1.8
	},
	"mega_fireworks": {
		"particle_count": 800,
		"lifetime": 3.0,
		"color": Color(1.0, 0.5, 0.8),
		"scale": 2.5
	},
	"game_lose_effect": {
		"particle_count": 150,
		"lifetime": 1.2,
		"color": Color(0.8, 0.2, 0.2),
		"scale": 1.2
	},
	"difficulty_increase": {
		"particle_count": 50,
		"lifetime": 0.8,
		"color": Color(1.0, 0.2, 0.2),
		"scale": 0.8
	},
	"difficulty_decrease": {
		"particle_count": 50,
		"lifetime": 0.8,
		"color": Color(0.2, 1.0, 0.2),
		"scale": 0.8
	},
	"streak_milestone": {
		"particle_count": 100,
		"lifetime": 1.0,
		"color": Color(1.0, 0.8, 0.0),
		"scale": 1.2
	},
	"chord_reveal": {
		"particle_count": 25,
		"lifetime": 0.6,
		"color": Color(0.5, 1.0, 0.5),
		"scale": 0.4
	},
	"chord_reveal_large": {
		"particle_count": 60,
		"lifetime": 1.0,
		"color": Color(0.5, 1.0, 0.5),
		"scale": 1.0
	},
	"first_click": {
		"particle_count": 30,
		"lifetime": 0.7,
		"color": Color(0.8, 1.0, 0.8),
		"scale": 0.6
	},
	"globe_rotate_fast": {
		"particle_count": 5,
		"lifetime": 0.2,
		"color": Color(0.7, 0.7, 1.0),
		"scale": 0.1
	},
	"globe_rotate_slow": {
		"particle_count": 3,
		"lifetime": 0.1,
		"color": Color(0.7, 0.7, 1.0),
		"scale": 0.05
	}
}

func play_vfx(vfx_type: String, position: Vector3, scale: float = 1.0):
	if not vfx_configs.has(vfx_type):
		return
	
	var config = vfx_configs[vfx_type]
	var particles = GPUParticles3D.new()
	
	# Configure particles based on type
	particles.amount = config.particle_count
	particles.lifetime = config.lifetime
	var scale_factor = config.scale * scale
	particles.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Add to scene and position
	add_child(particles)
	particles.global_position = position
	
	# Set up material
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, -3.0, 0)
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 10.0
	mat.color = config.color
	
	particles.process_material = mat
	particles.emitting = true
	
	# Cleanup after effect completes
	var timer = get_tree().create_timer(config.lifetime + 0.5)
	await timer.timeout
	if is_instance_valid(particles):
		particles.queue_free()
