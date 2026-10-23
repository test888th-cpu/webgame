class_name TestCase
extends RefCounted
## Minimal assertion base for headless tests. Each public method whose name
## starts with "test_" is run by TestRunner on a fresh instance.
##
## A tiny in-repo harness is used instead of an addon (GUT / gdUnit4) so CI
## needs nothing beyond the pinned engine binary. Revisit if tests need
## mocking, parameterisation or scene-tree fixtures beyond `tree`.

var tree: SceneTree
var failures: PackedStringArray = []


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append(
			"%s (expected %s, got %s)" % [message, var_to_str(expected), var_to_str(actual)]
		)


func assert_near(actual: float, expected: float, message: String, epsilon := 0.001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s (expected %f, got %f)" % [message, expected, actual])
