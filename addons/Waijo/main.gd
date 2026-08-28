@tool
extends EditorPlugin

const SIGNAL_MANAGER_PATH = "res://addons/Waijo/core/SignalManager.gd"
const SIGNAL_MANAGER_NAME = "SignalManager"
#const MAIN_WINDOW_SCENE_PATH = 

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		#_load_addon_main_menu()
		add_autoload_singleton(SIGNAL_MANAGER_NAME, SIGNAL_MANAGER_PATH)
		print("✓ Waijo Dynamic Shop Plugin loaded!")
		print("  - SignalManager registered as autoload")

func _load_addon_main_menu():
	#alicenzia_main_window_node = load(MAIN_WINDOW_SCENE_PATH).instantiate()
	pass
	#EditorInterface.get_editor_main_screen().add_child(alicenzia_main_window_node)
	#_make_visible(false)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		remove_autoload_singleton(SIGNAL_MANAGER_NAME)
		print("✗ Waijo Dynamic Shop Plugin unloaded")
