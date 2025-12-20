extends Node

class_name PerformanceMonitor

# Configuration
@export var monitor_interval: float = 1.0
@export var log_performance: bool = true
@export var auto_adjust_quality: bool = true

# Performance thresholds
@export var target_fps: int = 60
@export var warning_fps: int = 30
@export var critical_fps: int = 20

# Current performance data
var current_fps: int = 0
var current_frame_time: float = 0.0
var current_memory_usage: float = 0.0
var current_draw_calls: int = 0
var current_tile_count: int = 0

# Performance history
var fps_history: Array = []
var frame_time_history: Array = []
var memory_history: Array = []

# Quality settings
var current_quality_level: int = 2 # 0=Low, 1=Medium, 2=High
var quality_settings = {
	"Low": {
		"max_subdivision": 2,
		"max_particles": 50,
		"shader_quality": "Low",
		"vfx_enabled": false
	},
	"Medium": {
		"max_subdivision": 3,
		"max_particles": 100,
		"shader_quality": "Medium",
		"vfx_enabled": true
	},
	"High": {
		"max_subdivision": 4,
		"max_particles": 200,
		"shader_quality": "High",
		"vfx_enabled": true
	}
}

# Signals
signal performance_warning(message: String, severity: int)
signal quality_adjusted(new_quality: String)
signal performance_report(data: Dictionary)

func _ready():
	# Start monitoring
	var timer = Timer.new()
	timer.wait_time = monitor_interval
	timer.autostart = true
	timer.timeout.connect(_update_performance_data)
	add_child(timer)

func _update_performance_data():
	# Get current performance metrics
	current_fps = Performance.get_monitor(Performance.TIME_FPS)
	current_frame_time = Performance.get_monitor(Performance.TIME_PROCESS)
	current_memory_usage = Performance.get_monitor(Performance.MEMORY_STATIC)
	current_draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	
	# Update history
	fps_history.append(current_fps)
	frame_time_history.append(current_frame_time)
	memory_history.append(current_memory_usage)
	
	# Keep only last 60 entries (1 minute at 1 second intervals)
	if fps_history.size() > 60:
		fps_history.remove_at(0)
		frame_time_history.remove_at(0)
		memory_history.remove_at(0)
	
	# Check performance thresholds
	_check_performance_thresholds()
	
	# Auto-adjust quality if enabled
	if auto_adjust_quality:
		_adjust_quality_settings()
	
	# Log performance data
	if log_performance:
		_log_performance_data()

func _check_performance_thresholds():
	var severity = 0
	var message = ""
	
	if current_fps < critical_fps:
		severity = 2
		message = "Critical performance warning: FPS is very low (%d). Consider lowering quality settings." % current_fps
	elif current_fps < warning_fps:
		severity = 1
		message = "Performance warning: FPS is low (%d). Consider reducing game complexity." % current_fps
	elif current_fps >= target_fps:
		severity = 0
		message = "Performance is optimal: %d FPS" % current_fps
	
	if severity > 0:
		performance_warning.emit(message, severity)

func _adjust_quality_settings():
	var avg_fps = _get_average_fps()
	
	# Determine quality adjustment needed
	var target_quality = current_quality_level
	
	if avg_fps < critical_fps and current_quality_level > 0:
		target_quality = current_quality_level - 1
	elif avg_fps > target_fps + 10 and current_quality_level < 2:
		target_quality = current_quality_level + 1
	
	if target_quality != current_quality_level:
		current_quality_level = target_quality
		var quality_name = _get_quality_name(current_quality_level)
		quality_adjusted.emit(quality_name)
		
		# Emit signal to other systems to adjust quality
		get_tree().call_group("quality_adjustable", "adjust_quality", quality_settings[quality_name])

func _get_average_fps() -> float:
	if fps_history.size() == 0:
		return current_fps
	
	var sum = 0
	for fps in fps_history:
		sum += fps
	return float(sum) / float(fps_history.size())

func _get_quality_name(level: int) -> String:
	match level:
		0: return "Low"
		1: return "Medium"
		2: return "High"
		_: return "Unknown"

func _log_performance_data():
	var log_message = "Performance: %d FPS, %.2f ms/frame, %.2f MB memory, %d draw calls" % [
		current_fps,
		current_frame_time * 1000,
		current_memory_usage / 1024 / 1024,
		current_draw_calls
	]
	print(log_message)

func get_performance_summary() -> Dictionary:
	return {
		"current_fps": current_fps,
		"average_fps": _get_average_fps(),
		"current_frame_time": current_frame_time,
		"current_memory_usage": current_memory_usage,
		"current_draw_calls": current_draw_calls,
		"current_tile_count": current_tile_count,
		"current_quality_level": current_quality_level,
		"quality_name": _get_quality_name(current_quality_level),
		"fps_history": fps_history.duplicate(),
		"frame_time_history": frame_time_history.duplicate(),
		"memory_history": memory_history.duplicate()
	}

func set_tile_count(count: int):
	current_tile_count = count

func get_current_quality_settings() -> Dictionary:
	return quality_settings[_get_quality_name(current_quality_level)]

func force_quality_adjustment(quality_level: int):
	if quality_level >= 0 and quality_level <= 2:
		current_quality_level = quality_level
		var quality_name = _get_quality_name(current_quality_level)
		quality_adjusted.emit(quality_name)
		get_tree().call_group("quality_adjustable", "adjust_quality", quality_settings[quality_name])

func export_performance_report() -> String:
	var summary = get_performance_summary()
	var report = "=== Performance Report ===\n"
	report += "Current FPS: %d\n" % summary.current_fps
	report += "Average FPS: %.2f\n" % summary.average_fps
	report += "Frame Time: %.2f ms\n" % (summary.current_frame_time * 1000)
	report += "Memory Usage: %.2f MB\n" % (summary.current_memory_usage / 1024 / 1024)
	report += "Draw Calls: %d\n" % summary.current_draw_calls
	report += "Tile Count: %d\n" % summary.current_tile_count
	report += "Quality Level: %s\n" % summary.quality_name
	report += "\n=== Performance History ===\n"
	var fps_slice = fps_history.slice(max(0, fps_history.size() - 10), fps_history.size())
	var frame_time_slice = frame_time_history.slice(max(0, frame_time_history.size() - 10), frame_time_history.size())
	report += "FPS History (last 10): %s\n" % str(fps_slice)
	report += "Frame Time History (last 10): %s\n" % str(frame_time_slice)
	return report