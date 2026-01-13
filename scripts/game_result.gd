class_name GameResult
extends RefCounted

## Result class for consistent return types across game operations.
## Provides a structured way to return success/failure status with optional data.

## Whether the operation was successful.
var success: bool
## Human-readable message describing the result.
var message: String
## Additional data returned by the operation.
var data: Dictionary

## Creates a successful result.
## 
## Args:
## 	message: Optional success message
## 	data: Optional dictionary with additional data
## Returns: A new GameResult with success=true
static func ok(message: String = "", data: Dictionary = {}) -> GameResult:
	var result = GameResult.new()
	result.success = true
	result.message = message
	result.data = data
	return result

## Creates a failed result.
## 
## Args:
## 	message: Error message describing why the operation failed
## Returns: A new GameResult with success=false
static func fail(message: String) -> GameResult:
	var result = GameResult.new()
	result.success = false
	result.message = message
	result.data = {}
	return result
