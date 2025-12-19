extends Node

# Simple test runner for the comprehensive test suite
const ComprehensiveTestSuiteScript = preload("res://scripts/comprehensive_test_suite.gd")

func _ready():
	print("Starting GlobeSweeper 3D Test Suite...")
	
	# Create and run the comprehensive test suite
	var test_suite = ComprehensiveTestSuiteScript.new()
	add_child(test_suite)
	
	# The test suite will automatically run when added to the scene
	print("Test suite initialized and running...")