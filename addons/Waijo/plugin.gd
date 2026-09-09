@tool
extends EditorPlugin

const SIGNAL_MANAGER_NAME := "SignalManager"
const SIGNAL_MANAGER_PATH := "res://addons/dynamic_shop_plugin/core/signal_manager.gd"


func _enter_tree() -> void:
	add_autoload_singleton(SIGNAL_MANAGER_NAME, SIGNAL_MANAGER_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(SIGNAL_MANAGER_NAME)
