# Difficulty Scaling System Test Suite
# Tests various scenarios to ensure the difficulty scaling system works correctly

extends Node

# Test scenarios for difficulty scaling
var test_scenarios = [
	{
		"name": "Basic Scaling Test",
		"description": "Test basic difficulty adjustment",
		"actions": [
			{"type": "reveal", "success": true},
			{"type": "reveal", "success": true},
			{"type": "flag", "success": true},
			{"type": "game_end", "victory": true, "time": 120.0, "score": 500}
		]
	},
	{
		"name": "High Performance Test",
		"description": "Test difficulty increase for skilled players",
		"actions": [
			{"type": "reveal", "success": true},
			{"type": "reveal", "success": true},
			{"type": "reveal", "success": true},
			{"type": "chord", "success": true},
			{"type": "chord", "success": true},
			{"type": "game_end", "victory": true, "time": 60.0, "score": 800}
		]
	},
	{
		"name": "Struggling Player Test",
		"description": "Test difficulty decrease for struggling players",
		"actions": [
			{"type": "reveal", "success": false},
			{"type": "flag", "success": false},
			{"type": "reveal", "success": false},
			{"type": "powerup_use", "powerup_type": "reveal_safe_tile"},
			{"type": "powerup_use", "powerup_type": "hint_system"},
			{"type": "game_end", "victory": false, "time": 300.0, "score": 100}
		]
	},
	{
		"name": "Powerup Dependency Test",
		"description": "Test how powerup usage affects difficulty scaling",
		"actions": [
			{"type": "powerup_use", "powerup_type": "reveal_protection"},
			{"type": "powerup_use", "powerup_type": "reveal_mine"},
			{"type": "powerup_use", "powerup_type": "time_freeze"},
			{"type": "game_end", "victory": true, "time": 180.0, "score": 300}
		]
	},
	{
		"name": "Scaling Mode Test",
		"description": "Test different scaling modes",
		"modes": ["CONSERVATIVE", "AGGRESSIVE", "ADAPTIVE", "STATIC"],
		"actions": [
			{"type": "reveal", "success": true},
			{"type": "game_end", "victory": true, "time": 150.0, "score": 400}
		]
	}
]

var difficulty_scaling_manager: Node = null
var test_results: Array = []

func _ready():
	print("=== DIFFICULTY SCALING SYSTEM TEST SUITE ===")
	run_all_tests()

func initialize_test_environment():
	"""Initialize test environment with difficulty scaling manager"""
	# This would typically be done by the main game script
	# For testing, we'll simulate the initialization
	if not difficulty_scaling_manager:
		difficulty_scaling_manager = load("res://scripts/difficulty_scaling_manager.gd").new()
		add_child(difficulty_scaling_manager)

func run_all_tests():
	"""Run all test scenarios"""
	print("Running comprehensive difficulty scaling tests...")
	
	for scenario in test_scenarios:
		run_scenario_test(scenario)
	
	generate_test_report()

func run_scenario_test(scenario: Dictionary):
	"""Run a specific test scenario"""
	print("\n--- Running Test: %s ---" % scenario.name)
	print("Description: %s" % scenario.description)
	
	var test_result = {
		"scenario_name": scenario.name,
		"description": scenario.description,
		"initial_difficulty": 1.0,
		"final_difficulty": 1.0,
		"difficulty_changes": [],
		"performance_metrics": {},
		"success": false,
		"details": []
	}
	
	# Test different scaling modes if specified
	if scenario.has("modes"):
		for mode in scenario.modes:
			test_scenario_with_mode(scenario, mode, test_result)
	else:
		test_scenario_with_mode(scenario, "ADAPTIVE", test_result)
	
	test_results.append(test_result)

func test_scenario_with_mode(scenario: Dictionary, mode: String, test_result: Dictionary):
	"""Test scenario with specific scaling mode"""
	print("\nTesting with mode: %s" % mode)
	
	# Reset scaling manager for each test
	if difficulty_scaling_manager:
		difficulty_scaling_manager.set_scaling_mode(mode)
		difficulty_scaling_manager.reset_difficulty()
	
	var current_difficulty = 1.0
	test_result.initial_difficulty = current_difficulty
	
	# Execute test actions
	for action in scenario.actions:
		var action_result = execute_test_action(action, current_difficulty)
		
		if action.type == "game_end":
			# Record game end for difficulty analysis
			if difficulty_scaling_manager:
				difficulty_scaling_manager.record_game_end(
					action.victory,
					action.time,
					action.score
				)
			
			# Check for difficulty changes
			if difficulty_scaling_manager:
				var new_difficulty = difficulty_scaling_manager.current_difficulty_level
				if new_difficulty != current_difficulty:
					test_result.difficulty_changes.append({
						"from": current_difficulty,
						"to": new_difficulty,
						"mode": mode
					})
					current_difficulty = new_difficulty
		
		test_result.details.append(action_result)
	
	test_result.final_difficulty = current_difficulty
	test_result.success = test_result.difficulty_changes.size() > 0 or mode == "STATIC"
	
	# Get final performance metrics
	if difficulty_scaling_manager:
		test_result.performance_metrics = difficulty_scaling_manager.get_current_metrics()
	
	print("Result: %s | Difficulty: %.2f -> %.2f" % [
		"PASSED" if test_result.success else "FAILED",
		test_result.initial_difficulty,
		test_result.final_difficulty
	])

func execute_test_action(action: Dictionary, current_difficulty: float) -> Dictionary:
	"""Execute a test action and return result"""
	var result = {
		"action": action,
		"difficulty_before": current_difficulty,
		"difficulty_after": current_difficulty,
		"success": true
	}
	
	match action.type:
		"reveal":
			# Simulate tile reveal action
			if difficulty_scaling_manager:
				difficulty_scaling_manager.record_player_action(
					"reveal",
					action.success,
					{"tile_index": 0}
				)
			result.success = action.success
		
		"flag":
			# Simulate flag action
			if difficulty_scaling_manager:
				difficulty_scaling_manager.record_player_action(
					"flag",
					action.success,
					{"tile_index": 0}
				)
			result.success = action.success
		
		"chord":
			# Simulate chord reveal action
			if difficulty_scaling_manager:
				difficulty_scaling_manager.record_player_action(
					"chord",
					action.success,
					{"tiles_revealed": action.success}
				)
			result.success = action.success
		
		"powerup_use":
			# Simulate powerup usage
			if difficulty_scaling_manager:
				difficulty_scaling_manager.record_player_action(
					"powerup_use",
					true,
					{
						"type": action.powerup_type,
						"action": "activate",
						"needed": true
					}
				)
		
		"game_end":
			# Game end is handled by the calling function
			pass
	
	return result

func generate_test_report():
	"""Generate comprehensive test report"""
	print("\n============================================================")
	print("DIFFICULTY SCALING TEST REPORT")
	print("============================================================")
	
	var total_tests = test_results.size()
	var passed_tests = 0
	var total_difficulty_changes = 0
	
	for result in test_results:
		if result.success:
			passed_tests += 1
		total_difficulty_changes += result.difficulty_changes.size()
	
	print("Total Tests: %d" % total_tests)
	print("Passed: %d" % passed_tests)
	print("Failed: %d" % (total_tests - passed_tests))
	print("Success Rate: %.1f%%" % (float(passed_tests) / float(total_tests) * 100))
	print("Total Difficulty Changes: %d" % total_difficulty_changes)
	
	# Detailed results
	print("\n--- DETAILED RESULTS ---")
	for result in test_results:
		print("\n%s:" % result.scenario_name)
		print("  Initial Difficulty: %.2f" % result.initial_difficulty)
		print("  Final Difficulty: %.2f" % result.final_difficulty)
		print("  Difficulty Changes: %d" % result.difficulty_changes.size())
		
		if result.difficulty_changes.size() > 0:
			for change in result.difficulty_changes:
				print("    %.2f -> %.2f (%s mode)" % [change.from, change.to, change.mode])
		
		# Performance metrics
		var metrics = result.performance_metrics
		if metrics.size() > 0:
			print("  Performance Metrics:")
			print("    Efficiency: %.2f" % metrics.get("efficiency_score", 0.0))
			print("    Error Rate: %.2f" % metrics.get("error_rate", 0.0))
			print("    Powerup Dependency: %.2f" % metrics.get("powerup_dependency", 0.0))
	
	# Scaling mode analysis
	print("\n--- SCALING MODE ANALYSIS ---")
	var mode_performance = {}
	for result in test_results:
		for change in result.difficulty_changes:
			var mode = change.mode
			if not mode_performance.has(mode):
				mode_performance[mode] = {"changes": 0, "total_change": 0.0}
			
			mode_performance[mode].changes += 1
			mode_performance[mode].total_change += abs(change.to - change.from)
	
	for mode in mode_performance.keys():
		var perf = mode_performance[mode]
		var avg_change = perf.total_change / perf.changes if perf.changes > 0 else 0.0
		print("%s: %d changes, avg magnitude: %.3f" % [mode, perf.changes, avg_change])
	
	# Recommendations
	print("\n--- RECOMMENDATIONS ---")
	if passed_tests == total_tests:
		print("✓ All tests passed! The difficulty scaling system is working correctly.")
	else:
		print("⚠ Some tests failed. Review the implementation for issues.")
	
	if total_difficulty_changes > 0:
		print("✓ Difficulty adjustments are being triggered appropriately.")
	else:
		print("⚠ No difficulty changes detected. Check trigger thresholds.")
	
	print("\nTest suite completed.")

# Additional test functions for specific scenarios
func test_scaling_bounds():
	"""Test that difficulty stays within bounds"""
	print("\n--- Testing Scaling Bounds ---")
	
	if not difficulty_scaling_manager:
		return
	
	# Test minimum bound
	difficulty_scaling_manager.set_difficulty_bounds(0.3, 3.0)
	difficulty_scaling_manager.current_difficulty_level = 0.2
	difficulty_scaling_manager.apply_difficulty_adjustment(5.0, "Test bounds")
	
	var final_diff = difficulty_scaling_manager.current_difficulty_level
	var bounds_ok = final_diff >= 0.3 and final_diff <= 3.0
	
	print("Bounds test: %s (final difficulty: %.2f)" % ["PASSED" if bounds_ok else "FAILED", final_diff])

func test_scaling_persistence():
	"""Test that scaling preferences are saved and loaded"""
	print("\n--- Testing Scaling Persistence ---")
	
	if not difficulty_scaling_manager:
		return
	
	# Save preferences
	difficulty_scaling_manager.current_difficulty_level = 1.5
	difficulty_scaling_manager.set_scaling_mode(difficulty_scaling_manager.ScalingMode.AGGRESSIVE)
	difficulty_scaling_manager.save_scaling_preferences()
	
	# Reset and load
	difficulty_scaling_manager.current_difficulty_level = 1.0
	difficulty_scaling_manager.set_scaling_mode(difficulty_scaling_manager.ScalingMode.CONSERVATIVE)
	difficulty_scaling_manager.load_scaling_preferences()
	
	var diff_ok = abs(difficulty_scaling_manager.current_difficulty_level - 1.5) < 0.01
	var mode_ok = difficulty_scaling_manager.current_mode == difficulty_scaling_manager.ScalingMode.AGGRESSIVE
	
	print("Persistence test: %s (difficulty: %.2f, mode: %s)" % [
		"PASSED" if diff_ok and mode_ok else "FAILED",
		difficulty_scaling_manager.current_difficulty_level,
		difficulty_scaling_manager.ScalingMode.keys()[difficulty_scaling_manager.current_mode]
	])

# Public API for running specific tests
func run_specific_test(test_name: String):
	"""Run a specific test by name"""
	for scenario in test_scenarios:
		if scenario.name == test_name:
			run_scenario_test(scenario)
			return
	print("Test '%s' not found." % test_name)

func get_test_results() -> Array:
	"""Get all test results"""
	return test_results

func clear_test_results():
	"""Clear test results"""
	test_results.clear()