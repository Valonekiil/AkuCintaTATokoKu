@tool
extends EditorPlugin

func _enter_tree() -> void:
	print("✓ Waijo Dynamic Shop Plugin loaded successfully!")

func _exit_tree() -> void:
	print("✗ Waijo Dynamic Shop Plugin unloaded.")
