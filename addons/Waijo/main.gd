@tool
extends EditorPlugin

const SIGNAL_MANAGER_PATH = "res://addons/Waijo/core/SignalManager.gd"
const SIGNAL_MANAGER_NAME = "SignalManager"


func _enter_tree() -> void:
	add_autoload_singleton(SIGNAL_MANAGER_NAME, SIGNAL_MANAGER_PATH)
	print("✓ Waijo Dynamic Shop Plugin loaded!")
	print("  - SignalManager registered as autoload")


func _exit_tree() -> void:
	remove_autoload_singleton(SIGNAL_MANAGER_NAME)
	print("✗ Waijo Dynamic Shop Plugin unloaded")
