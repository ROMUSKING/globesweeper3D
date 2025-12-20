extends Node

class_name ImprovementValidator

# Validation results
var validation_results: Dictionary = {}
var test_passed: int = 0
var test_failed: int = 0

# Test configuration
@export var run_automated_tests: bool = true
@export var log_detailed_results: bool = true

# Signals
signal validation_complete(results: Dictionary)
signal test_completed(test_name: String, message: String, passed: bool)
signal validation_test_failed(test_name: String, message: String)

func _ready():
	if run_automated_tests:
		start_validation()

func start_validation():
	print("=== Starting Improvement Validation ===")
	
	# Run all validation tests
	validate_tutorial_system()
	validate_performance_monitoring()
	validate_notification_system()
	validate_ui_improvements()
	validate_gameplay_enhancements()
	
	# Complete validation
	var total_tests = test_passed + test_failed
	var success_rate = 0.0
	if total_tests > 0:
		success_rate = float(test_passed) / float(total_tests) * 100
	
	validation_results.total_tests = total_tests
	validation_results.success_rate = success_rate
	validation_results.passed = test_passed
	validation_results.failed = test_failed
	
	print("=== Validation Complete ===")
	print("Tests Passed: %d" % test_passed)
	print("Tests Failed: %d" % test_failed)
	print("Success Rate: %.1f%%" % success_rate)
	
	validation_complete.emit(validation_results)

func validate_tutorial_system():
	print("Validating Tutorial System...")
	
	# Check if tutorial manager exists
	if not has_node("TutorialManager"):
		_test_failed("Tutorial System", "TutorialManager node not found")
		return
	
	var tm = get_node("TutorialManager")
	if not tm:
		_test_failed("Tutorial System", "TutorialManager instance not accessible")
		return
	
	# Check tutorial steps
	if tm.tutorial_steps.size() == 0:
		_test_failed("Tutorial System", "No tutorial steps defined")
		return
	
	# Check tutorial progress loading
	tm.load_tutorial_progress()
	if tm.tutorial_progress < 0:
		_test_failed("Tutorial System", "Invalid tutorial progress loaded")
		return
	
	# Check tutorial overlay
	if not has_node("TutorialOverlay"):
		_test_failed("Tutorial System", "TutorialOverlay node not found")
		return
	
	var overlay = get_node("TutorialOverlay")
	if not overlay:
		_test_failed("Tutorial System", "TutorialOverlay instance not accessible")
		return
	
	_test_passed("Tutorial System", "All tutorial components properly initialized")

func validate_performance_monitoring():
	print("Validating Performance Monitoring...")
	
	# Check if performance monitor exists
	if not has_node("PerformanceMonitor"):
		_test_failed("Performance Monitoring", "PerformanceMonitor node not found")
		return
	
	var pm = get_node("PerformanceMonitor")
	if not pm:
		_test_failed("Performance Monitoring", "PerformanceMonitor instance not accessible")
		return
	
	# Check performance data collection
	pm._update_performance_data()
	if pm.current_fps <= 0:
		_test_failed("Performance Monitoring", "FPS not being tracked properly")
		return
	
	# Check quality adjustment system
	var initial_quality = pm.current_quality_level
	pm._adjust_quality_settings()
	if pm.current_quality_level < 0 or pm.current_quality_level > 2:
		_test_failed("Performance Monitoring", "Invalid quality level after adjustment")
		return
	
	_test_passed("Performance Monitoring", "Performance monitoring system working correctly")

func validate_notification_system():
	print("Validating Notification System...")
	
	# Check if notification manager exists
	if not has_node("NotificationManager"):
		_test_failed("Notification System", "NotificationManager node not found")
		return
	
	var nm = get_node("NotificationManager")
	if not nm:
		_test_failed("Notification System", "NotificationManager instance not accessible")
		return
	
	# Test notification creation
	nm.show_notification("Test notification", "info", 1.0)
	if nm.get_notification_count() == 0:
		_test_failed("Notification System", "Notifications not being created")
		return
	
	_test_passed("Notification System", "Notification system working correctly")

func validate_ui_improvements():
	print("Validating UI Improvements...")
	
	# Check if UI manager exists
	if not has_node("UI"):
		_test_failed("UI Improvements", "UI node not found")
		return
	
	var ui = get_node("UI")
	if not ui:
		_test_failed("UI Improvements", "UI instance not accessible")
		return
	
	# Check if tutorial overlay is connected
	if not has_node("TutorialOverlay"):
		_test_failed("UI Improvements", "Tutorial overlay not integrated")
		return
	
	# Check if notification system is integrated
	if not has_node("NotificationManager"):
		_test_failed("UI Improvements", "Notification system not integrated")
		return
	
	_test_passed("UI Improvements", "UI improvements properly integrated")

func validate_gameplay_enhancements():
	print("Validating Gameplay Enhancements...")
	
	# Check if main game has all required components
	if not has_node("InteractionManager"):
		_test_failed("Gameplay Enhancements", "InteractionManager not found")
		return
	
	if not has_node("AudioManager"):
		_test_failed("Gameplay Enhancements", "AudioManager not found")
		return
	
	if not has_node("GlobeGenerator"):
		_test_failed("Gameplay Enhancements", "GlobeGenerator not found")
		return
	
	# Check if performance monitoring is integrated
	if not has_node("PerformanceMonitor"):
		_test_failed("Gameplay Enhancements", "Performance monitoring not integrated")
		return
	
	_test_passed("Gameplay Enhancements", "Gameplay enhancements properly integrated")

func _test_passed(test_name: String, message: String):
	test_passed += 1
	if log_detailed_results:
		print("✓ PASS: %s - %s" % [test_name, message])
	test_completed.emit(test_name, message, true)

func _test_failed(test_name: String, message: String):
	test_failed += 1
	if log_detailed_results:
		print("✗ FAIL: %s - %s" % [test_name, message])
	validation_test_failed.emit(test_name, message)
	test_completed.emit(test_name, message, false)

func get_validation_summary() -> String:
	var summary = "=== Validation Summary ===\n"
	summary += "Tests Passed: %d\n" % test_passed
	summary += "Tests Failed: %d\n" % test_failed
	summary += "Success Rate: %.1f%%\n" % validation_results.get("success_rate", 0.0)
	
	if validation_results.get("success_rate", 0.0) >= 80.0:
		summary += "Status: ✓ VALIDATION SUCCESSFUL\n"
	else:
		summary += "Status: ✗ VALIDATION FAILED\n"
	
	return summary

func export_validation_report() -> String:
	var report = get_validation_summary()
	report += "\n=== Detailed Results ===\n"
	
	# Add specific test results
	if has_node("TutorialManager"):
		var tm = get_node("TutorialManager")
		report += "Tutorial Steps: %d\n" % tm.tutorial_steps.size()
	
	if has_node("PerformanceMonitor"):
		var pm = get_node("PerformanceMonitor")
		report += "Performance Monitor: Active\n"
		report += "Current Quality: %s\n" % pm._get_quality_name(pm.current_quality_level)
	
	if has_node("NotificationManager"):
		var nm = get_node("NotificationManager")
		report += "Notification Manager: Active\n"
		report += "Max Notifications: %d\n" % nm.max_notifications
	
	return report